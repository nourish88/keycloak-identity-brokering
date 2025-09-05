#!/bin/bash

# Ana Setup Scripti - Tüm Keycloak federasyon ortamını kurar

echo "🚀 Keycloak Federasyon Test Ortamı Kurulumu Başlatılıyor..."
echo ""

# Docker Compose ile servisleri başlat
echo "1️⃣ Docker servisleri başlatılıyor..."
docker-compose up -d

# Servislerin hazır olmasını bekle
echo "2️⃣ Servislerin hazır olması bekleniyor..."
sleep 30

# jq kurulu mu kontrol et
if ! command -v jq &> /dev/null; then
  echo "❌ jq kurulu değil. Lütfen jq'yu kurun:"
  echo "   macOS: brew install jq"
  echo "   Ubuntu: sudo apt-get install jq"
  exit 1
fi

# Scriptleri çalıştırılabilir yap
chmod +x setup-keycloak-a.sh
chmod +x setup-keycloak-b.sh
chmod +x setup-brokering.sh
chmod +x test-scenarios.sh

# Keycloak-A konfigürasyonu
echo "3️⃣ Keycloak-A (Kamunet) konfigürasyonu..."
./setup-keycloak-a.sh

echo ""

# Keycloak-B konfigürasyonu
echo "4️⃣ Keycloak-B (Vatandaş) konfigürasyonu..."
./setup-keycloak-b.sh

echo ""

# Brokering konfigürasyonu
echo "5️⃣ Brokering konfigürasyonu..."
./setup-brokering.sh

echo ""

# Test senaryolarını çalıştır
echo "6️⃣ Test senaryoları çalıştırılıyor..."
./detailed-test-scenarios.sh

echo ""
echo "🎉 Kurulum tamamlandı!"
echo ""
echo "📋 Erişim Bilgileri:"
echo "   Keycloak-A (Kamunet): http://localhost:8080/admin"
echo "   Keycloak-B (Vatandaş): http://localhost:8081/admin"
echo "   Admin kullanıcı: admin / admin123"
echo ""
echo "🔧 Test Komutları:"
echo "   ./test-scenarios.sh  # Test senaryolarını çalıştır"
echo "   docker-compose logs  # Logları görüntüle"
echo "   docker-compose down  # Servisleri durdur"
echo ""
echo "📖 Detaylı bilgi için README.md dosyasını inceleyin."
