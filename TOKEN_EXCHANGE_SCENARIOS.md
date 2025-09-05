# Keycloak Federasyon Sistemi - Kullanım Kılavuzu

## 🚀 Sıfırdan Keycloak Federasyon Sistemi Kurulumu - Baştan Sona

### **Adım 1: Gereksinimler**

- Docker ve Docker Compose kurulu olmalı
- Terminal/Command Prompt erişimi
- Bu proje dosyaları

### **Adım 2: Script'leri Çalıştırılabilir Yap**

```bash
# Tüm script'leri çalıştırılabilir yap
chmod +x *.sh
```

### **Adım 3: Docker Compose ile Servisleri Başlat**

```bash
# Terminal'de şu komutu çalıştır:
docker-compose up -d
```

Bu komut:

- Keycloak-A (port 8080) - Kamunet
- Keycloak-B (port 8081) - Vatandaş
- PostgreSQL veritabanları
- Tüm servisleri başlatır

### **Adım 4: Servislerin Hazır Olmasını Bekle**

```bash
# Servislerin tam başlaması için 60 saniye bekle
sleep 60
```

### **Adım 5: Keycloak-A Konfigürasyonu**

```bash
# Keycloak-A'yı konfigüre et
./setup-keycloak-a.sh
```

Bu script:

- `kamunet` realm'i oluşturur
- `ic_kullanici` kullanıcısı oluşturur
- `ic-uygulama` (public) client'ı oluşturur
- `karma-uygulama` (confidential + token exchange) client'ı oluşturur

### **Adım 6: Keycloak-B Konfigürasyonu**

```bash
# Keycloak-B'yi konfigüre et
./setup-keycloak-b.sh
```

Bu script:

- `vatandas` realm'i oluşturur
- `vatandas_kullanici` kullanıcısı oluşturur
- `vatandas-uygulama` client'ı oluşturur
- `keycloak-a-broker` client'ı oluşturur

### **Adım 7: Brokering Konfigürasyonu**

```bash
# Brokering konfigürasyonu yap
./setup-brokering.sh
```

Bu script:

- Keycloak-A'da Keycloak-B identity provider oluşturur
- Token exchange politikalarını ayarlar

### **Adım 8: Test Senaryolarını Çalıştır**

```bash
# Detaylı test senaryolarını çalıştır
./detailed-test-scenarios.sh
```

Bu script 6 farklı senaryoyu test eder:

1. ✅ İç Kullanıcı → İç Uygulama (Exchange YOK)
2. ✅ İç Kullanıcı → Karma Uygulama (Exchange YOK)
3. ✅ Vatandaş → Vatandaş Uygulama (Exchange YOK)
4. ✅ Vatandaş → Karma Uygulama (Exchange YAPILIR)
5. ✅ Internal Token Exchange (Exchange YAPILIR)
6. ✅ Service Account Token (Exchange YOK)

## 🎯 **Tek Komutla Tüm Sistemi Kurmak İçin:**

```bash
# Sıfırdan tüm sistemi kur
./fresh-install.sh
```

Bu script yukarıdaki tüm adımları otomatik yapar.

## 🔧 **Hızlı Test İçin:**

git ```bash
# Temel testleri çalıştır
./quick-test.sh
```

## **Erişim Bilgileri:**

- **Keycloak-A (Kamunet)**: http://localhost:8080/admin
- **Keycloak-B (Vatandaş)**: http://localhost:8081/admin
- **Admin**: admin / admin123

## **Test Senaryoları:**

### **Senaryo 1: İç Kullanıcı → İç Uygulama**

```bash
# Token Exchange YAPILMAZ
curl -X POST "http://localhost:8080/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=ic-uygulama&username=ic_kullanici&password=password123"
```

### **Senaryo 2: Vatandaş → Karma Uygulama**

```bash
# Token Exchange YAPILIR
# 1. Vatandaş token al
VATANDAS_TOKEN=$(curl -s -X POST "http://localhost:8081/realms/vatandas/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=vatandas-uygulama&username=vatandas_kullanici&password=password123" | \
  jq -r '.access_token')

# 2. Token exchange yap
curl -X POST "http://localhost:8080/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI&subject_token=$VATANDAS_TOKEN&subject_token_type=urn:ietf:params:oauth:token-type:access_token&requested_token_type=urn:ietf:params:oauth:token-type:access_token"
```

## 🗑️ **Sistemi Temizlemek İçin:**

```bash
# Tüm servisleri durdur ve volume'ları sil
docker-compose down -v
```

## 📖 **Dokümantasyon:**

- `TOKEN_EXCHANGE_SCENARIOS.md` - Detaylı senaryo açıklamaları
- `README.md` - Genel kullanım kılavuzu

## 🎯 **Özet Komutlar:**

```bash
# 1. Sıfırdan kurulum
./fresh-install.sh

# 2. Hızlı test
./quick-test.sh

# 3. Detaylı test
./detailed-test-scenarios.sh

# 4. Sistemi temizle
docker-compose down -v
```

Bu adımları takip ederek sıfırdan Keycloak federasyon sistemini kurabilir ve test edebilirsiniz!
