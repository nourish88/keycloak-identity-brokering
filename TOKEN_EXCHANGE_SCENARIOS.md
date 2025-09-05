# Token Exchange Senaryoları - Keycloak Federasyon

## 🎯 Genel Kural

**Token Exchange YAPILIR** sadece şu durumlarda:

- Farklı realm'ler arası token değişimi
- Aynı realm içinde farklı client'lar arası token değişimi (scope/audience farklılığı)

**Token Exchange YAPILMAZ** şu durumlarda:

- Aynı realm, aynı client
- Service account token'ları
- Gereksiz token değişimi

## 📋 Detaylı Senaryolar

### Senaryo 1: İç Kullanıcı → İç Uygulama

- **Durum**: Token Exchange **YAPILMAZ**
- **Sebep**: Aynı realm (kamunet), aynı client (ic-uygulama)
- **Akış**:
  ```
  İç Kullanıcı → Keycloak-A → ic-uygulama token
  ```
- **Test**: ✅ Doğrudan token alınır

### Senaryo 2: İç Kullanıcı → Karma Uygulama

- **Durum**: Token Exchange **YAPILMAZ**
- **Sebep**: Aynı realm (kamunet), farklı client ama kullanıcı zaten Keycloak-A'da
- **Akış**:
  ```
  İç Kullanıcı → Keycloak-A → karma-uygulama token
  ```
- **Test**: ✅ Doğrudan karma uygulama için token alınır

### Senaryo 3: Vatandaş Kullanıcı → Vatandaş Uygulama

- **Durum**: Token Exchange **YAPILMAZ**
- **Sebep**: Aynı realm (vatandas), aynı client (vatandas-uygulama)
- **Akış**:
  ```
  Vatandaş Kullanıcı → Keycloak-B → vatandas-uygulama token
  ```
- **Test**: ✅ Doğrudan token alınır

### Senaryo 4: Vatandaş Kullanıcı → Karma Uygulama ⭐

- **Durum**: Token Exchange **YAPILIR**
- **Sebep**: Farklı realm (vatandas → kamunet), farklı client
- **Akış**:
  ```
  Vatandaş Kullanıcı → Keycloak-B → vatandas token
  ↓
  vatandas token → Keycloak-A (Token Exchange) → karma-uygulama token
  ```
- **Test**: 🔄 Token exchange gerekli
- **Gereksinimler**:
  - Keycloak-A'da Keycloak-B identity provider
  - karma-uygulama'da token exchange aktif
  - Client secret konfigürasyonu

### Senaryo 5: Internal Token Exchange

- **Durum**: Token Exchange **YAPILIR**
- **Sebep**: Aynı realm içinde farklı client'lar arası token değişimi
- **Akış**:
  ```
  İç Kullanıcı → ic-uygulama token → Token Exchange → karma-uygulama token
  ```
- **Test**: 🔄 Internal token exchange
- **Kullanım**: Scope/audience farklılığı, client değişikliği

### Senaryo 6: Service Account Token

- **Durum**: Token Exchange **YAPILMAZ**
- **Sebep**: Service account token'ı zaten client için, user bilgisi yok
- **Akış**:
  ```
  karma-uygulama → Service Account → client token
  ```
- **Test**: ✅ Service account token alınır
- **Özellik**: User bilgisi içermez, sadece client bilgisi

## 🔧 Konfigürasyon Gereksinimleri

### Token Exchange İçin Gerekli:

1. **Client Konfigürasyonu**:

   - `publicClient: false` (confidential)
   - `serviceAccountsEnabled: true`
   - `token.exchange: true` (attribute)

2. **Identity Provider** (External token exchange için):

   - Keycloak-A'da Keycloak-B provider
   - Client secret konfigürasyonu
   - Issuer URL doğru ayarlanmış

3. **Realm Ayarları**:
   - Token exchange özelliği aktif
   - Client policies konfigürasyonu

## 🚀 Test Komutları

### Senaryo 4 Test (Vatandaş → Karma):

```bash
# 1. Vatandaş token al
VATANDAS_TOKEN=$(curl -s -X POST "http://localhost:8081/realms/vatandas/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=vatandas-uygulama&username=vatandas_kullanici&password=password123&scope=openid profile email" | \
  jq -r '.access_token')

# 2. Token exchange
EXCHANGED_TOKEN=$(curl -s -X POST "http://localhost:8080/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id=karma-uygulama&client_secret=CLIENT_SECRET&subject_token=$VATANDAS_TOKEN&subject_token_type=urn:ietf:params:oauth:token-type:access_token&requested_token_type=urn:ietf:params:oauth:token-type:access_token" | \
  jq -r '.access_token')

# 3. Doğrula
curl -s -X GET "http://localhost:8080/realms/kamunet/protocol/openid-connect/userinfo" \
  -H "Authorization: Bearer $EXCHANGED_TOKEN"
```

## 📊 Senaryo Karar Matrisi

| Kullanıcı Tipi  | Hedef Uygulama    | Realm | Token Exchange |
| --------------- | ----------------- | ----- | -------------- |
| İç              | İç                | A     | ❌             |
| İç              | Karma             | A     | ❌             |
| Vatandaş        | Vatandaş          | B     | ❌             |
| Vatandaş        | Karma             | A     | ✅             |
| İç              | İç (farklı scope) | A     | ✅             |
| Service Account | Herhangi          | A     | ❌             |

## 🎯 Özet

**Token Exchange YAPILIR**:

- Vatandaş → Karma uygulama (farklı realm)
- Internal client değişikliği (scope/audience farklılığı)

**Token Exchange YAPILMAZ**:

- Aynı realm, aynı client
- Kullanıcı zaten doğru realm'de
- Service account token'ları
