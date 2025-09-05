#!/bin/bash

# Sıfırdan Keycloak Federasyon Kurulumu
# Bu script tüm sistemi sıfırdan kurar ve test eder

echo "🚀 Sıfırdan Keycloak Federasyon Kurulumu Başlatılıyor..."
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
    echo "----------------------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Adım 1: Temizlik
print_step "Adım 1: Temizlik ve Hazırlık"
print_info "Mevcut servisler durduruluyor ve volume'lar temizleniyor..."

docker-compose down -v 2>/dev/null
docker system prune -f 2>/dev/null

print_success "Temizlik tamamlandı"
echo ""

# Adım 2: Servisleri Başlat
print_step "Adım 2: Keycloak Servislerini Başlat"
print_info "Keycloak 26.2.0 servisleri başlatılıyor..."

docker-compose up -d

if [ $? -eq 0 ]; then
    print_success "Servisler başlatıldı"
else
    print_error "Servisler başlatılamadı"
    exit 1
fi

echo ""

# Adım 3: Servislerin Hazır Olmasını Bekle
print_step "Adım 3: Servislerin Hazır Olmasını Bekle"
print_info "Keycloak servislerinin tam olarak başlaması bekleniyor..."

for i in {1..12}; do
    echo -n "."
    sleep 5
    
    # Keycloak-A kontrolü
    if curl -s http://localhost:8080/realms/master/.well-known/openid_configuration > /dev/null 2>&1; then
        KEYCLOAK_A_READY=true
    else
        KEYCLOAK_A_READY=false
    fi
    
    # Keycloak-B kontrolü
    if curl -s http://localhost:8081/realms/master/.well-known/openid_configuration > /dev/null 2>&1; then
        KEYCLOAK_B_READY=true
    else
        KEYCLOAK_B_READY=false
    fi
    
    if [ "$KEYCLOAK_A_READY" = true ] && [ "$KEYCLOAK_B_READY" = true ]; then
        echo ""
        print_success "Servisler hazır!"
        break
    fi
    
    if [ $i -eq 12 ]; then
        echo ""
        print_error "Servisler hazır olmadı, manuel kontrol gerekli"
        echo "Keycloak-A: http://localhost:8080/admin"
        echo "Keycloak-B: http://localhost:8081/admin"
        exit 1
    fi
done

echo ""

# Adım 4: Konfigürasyonları Yap
print_step "Adım 4: Keycloak Konfigürasyonları"
print_info "Keycloak-A (Kamunet) konfigürasyonu yapılıyor..."

./setup-keycloak-a.sh

if [ $? -eq 0 ]; then
    print_success "Keycloak-A konfigürasyonu tamamlandı"
else
    print_error "Keycloak-A konfigürasyonu başarısız"
    exit 1
fi

echo ""

print_info "Keycloak-B (Vatandaş) konfigürasyonu yapılıyor..."

./setup-keycloak-b.sh

if [ $? -eq 0 ]; then
    print_success "Keycloak-B konfigürasyonu tamamlandı"
else
    print_error "Keycloak-B konfigürasyonu başarısız"
    exit 1
fi

echo ""

print_info "Brokering konfigürasyonu yapılıyor..."

./setup-brokering.sh

if [ $? -eq 0 ]; then
    print_success "Brokering konfigürasyonu tamamlandı"
else
    print_error "Brokering konfigürasyonu başarısız"
fi

echo ""

# Adım 5: Test Senaryolarını Çalıştır
print_step "Adım 5: Test Senaryoları"
print_info "Detaylı test senaryoları çalıştırılıyor..."

./detailed-test-scenarios.sh

echo ""

# Adım 6: Özet
print_step "Adım 6: Kurulum Özeti"
print_success "🎉 Sıfırdan kurulum tamamlandı!"

echo ""
echo "📋 Erişim Bilgileri:"
echo "   Keycloak-A (Kamunet): http://localhost:8080/admin"
echo "   Keycloak-B (Vatandaş): http://localhost:8081/admin"
echo "   Admin kullanıcı: admin / admin123"
echo ""

echo "🔧 Test Komutları:"
echo "   ./detailed-test-scenarios.sh  # Test senaryolarını çalıştır"
echo "   ./fresh-install.sh           # Sıfırdan yeniden kur"
echo "   docker-compose logs          # Logları görüntüle"
echo "   docker-compose down -v       # Tüm sistemi temizle"
echo ""

echo "📖 Dokümantasyon:"
echo "   TOKEN_EXCHANGE_SCENARIOS.md  # Senaryo detayları"
echo "   README.md                    # Genel kullanım kılavuzu"
echo ""

print_info "Kurulum tamamlandı! Test senaryolarını inceleyin."
