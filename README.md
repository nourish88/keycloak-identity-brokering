# Keycloak Federasyon Test Ortamı

Bu proje, Keycloak federasyon senaryosunu test etmek için iki Keycloak instance'ı içerir.

## Servisler

- **Keycloak-A (Kamunet)**: http://localhost:8080 - İç kullanıcılar için
- **Keycloak-B (Vatandaş)**: http://localhost:8081 - Dış kullanıcılar için

## Başlatma

```bash
docker-compose up -d
```

## Test Senaryoları

### 1. İç Kullanıcı (Kamunet) - Keycloak-A

- Realm: `kamunet`
- Kullanıcı: `ic_kullanici` / `password123`
- Client: `ic-uygulama`

### 2. Vatandaş Kullanıcı - Keycloak-B

- Realm: `vatandas`
- Kullanıcı: `vatandas_kullanici` / `password123`
- Client: `vatandas-uygulama`

### 3. Karma Uygulama

- Her iki kullanıcı tipine açık
- Token exchange ile federasyon

## Konfigürasyon Adımları

1. Keycloak-A'da `kamunet` realm'i oluştur
2. Keycloak-B'de `vatandas` realm'i oluştur
3. Keycloak-A'da Keycloak-B'ye brokering konfigürasyonu yap
4. Test kullanıcıları ve client'ları oluştur
5. Token exchange politikalarını ayarla

## Test Komutları

```bash
# Keycloak-A'dan token al
curl -X POST http://localhost:8080/realms/kamunet/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=ic-uygulama&username=ic_kullanici&password=password123"

# Keycloak-B'den token al
curl -X POST http://localhost:8081/realms/vatandas/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=vatandas-uygulama&username=vatandas_kullanici&password=password123"
```
