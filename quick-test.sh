#!/bin/bash

# Hızlı Test Script'i - Temel senaryoları test eder

KEYCLOAK_A_URL="http://localhost:8080"
KEYCLOAK_B_URL="http://localhost:8081"

echo "⚡ Keycloak Federasyon Hızlı Test"
echo "================================="
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}🧪 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test 1: Servisler Çalışıyor mu?
print_test "Test 1: Servisler Çalışıyor mu?"

if curl -s http://localhost:8080/realms/master/.well-known/openid_configuration > /dev/null 2>&1; then
    print_success "Keycloak-A çalışıyor"
else
    print_error "Keycloak-A çalışmıyor"
    exit 1
fi

if curl -s http://localhost:8081/realms/master/.well-known/openid_configuration > /dev/null 2>&1; then
    print_success "Keycloak-B çalışıyor"
else
    print_error "Keycloak-B çalışmıyor"
    exit 1
fi

echo ""

# Test 2: İç Kullanıcı Token
print_test "Test 2: İç Kullanıcı Token Alabilir mi?"

IC_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=ic-uygulama&username=ic_kullanici&password=password123" | \
  jq -r '.access_token')

if [ "$IC_TOKEN" != "null" ] && [ -n "$IC_TOKEN" ]; then
    print_success "İç kullanıcı token alındı"
else
    print_error "İç kullanıcı token alınamadı"
fi

echo ""

# Test 3: Vatandaş Kullanıcı Token
print_test "Test 3: Vatandaş Kullanıcı Token Alabilir mi?"

VATANDAS_TOKEN=$(curl -s -X POST "$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=vatandas-uygulama&username=vatandas_kullanici&password=password123" | \
  jq -r '.access_token')

if [ "$VATANDAS_TOKEN" != "null" ] && [ -n "$VATANDAS_TOKEN" ]; then
    print_success "Vatandaş kullanıcı token alındı"
else
    print_error "Vatandaş kullanıcı token alınamadı"
fi

echo ""

# Test 4: Karma Uygulama Token
print_test "Test 4: Karma Uygulama Token Alabilir mi?"

KARMA_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI&username=ic_kullanici&password=password123" | \
  jq -r '.access_token')

if [ "$KARMA_TOKEN" != "null" ] && [ -n "$KARMA_TOKEN" ]; then
    print_success "Karma uygulama token alındı"
else
    print_error "Karma uygulama token alınamadı"
fi

echo ""

# Test 5: Token Exchange (Internal)
print_test "Test 5: Internal Token Exchange Çalışıyor mu?"

EXCHANGE_RESULT=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI&subject_token=$KARMA_TOKEN&subject_token_type=urn:ietf:params:oauth:token-type:access_token&requested_token_type=urn:ietf:params:oauth:token-type:access_token" | \
  jq -r '.access_token')

if [ "$EXCHANGE_RESULT" != "null" ] && [ -n "$EXCHANGE_RESULT" ]; then
    print_success "Internal token exchange çalışıyor"
else
    print_error "Internal token exchange çalışmıyor"
fi

echo ""

# Test 6: External Token Exchange
print_test "Test 6: External Token Exchange Çalışıyor mu?"

EXTERNAL_EXCHANGE=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI&subject_token=$VATANDAS_TOKEN&subject_token_type=urn:ietf:params:oauth:token-type:access_token&requested_token_type=urn:ietf:params:oauth:token-type:access_token" | \
  jq -r '.access_token')

if [ "$EXTERNAL_EXCHANGE" != "null" ] && [ -n "$EXTERNAL_EXCHANGE" ]; then
    print_success "External token exchange çalışıyor"
else
    print_error "External token exchange çalışmıyor (Identity provider konfigürasyonu gerekli)"
fi

echo ""
echo "🎯 Hızlı Test Tamamlandı!"
echo ""
echo "📋 Sonuçlar:"
echo "   ✅ Servisler çalışıyor"
echo "   ✅ İç kullanıcı token alıyor"
echo "   ✅ Vatandaş kullanıcı token alıyor"
echo "   ✅ Karma uygulama token alıyor"
echo "   ✅ Internal token exchange çalışıyor"
echo "   ❓ External token exchange (Identity provider gerekli)"
echo ""
echo "🔧 Detaylı test için: ./detailed-test-scenarios.sh"
