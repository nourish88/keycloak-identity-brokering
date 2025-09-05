#!/bin/bash

# Detaylı Token Exchange Test Senaryoları
# Keycloak Federasyon Senaryoları

KEYCLOAK_A_URL="http://localhost:8080"
KEYCLOAK_B_URL="http://localhost:8081"

echo "=== Keycloak Federasyon Detaylı Test Senaryoları ==="
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function
print_scenario() {
    echo -e "${BLUE}📋 $1${NC}"
    echo "----------------------------------------"
}

print_result() {
    if [ "$1" = "SUCCESS" ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Senaryo 1: İç Kullanıcı - İç Uygulama (Token Exchange YOK)
print_scenario "Senaryo 1: İç Kullanıcı → İç Uygulama"
print_info "Durum: Token Exchange YAPILMAZ - Aynı realm, aynı client"
print_info "Sebep: Gereksiz, token zaten doğru client için"

IC_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=ic-uygulama&username=ic_kullanici&password=password123&scope=openid profile email" | \
  jq -r '.access_token')

if [ "$IC_TOKEN" != "null" ] && [ -n "$IC_TOKEN" ]; then
    print_result "SUCCESS" "İç kullanıcı token'ı alındı"
    
    # Token'ı doğrula
    USER_INFO=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
      -H "Authorization: Bearer $IC_TOKEN")
    
    if [ -n "$USER_INFO" ] && [ "$USER_INFO" != "null" ]; then
        print_result "SUCCESS" "Token doğrulandı, user bilgileri mevcut"
        echo "User: $(echo $USER_INFO | jq -r '.preferred_username')"
    else
        print_result "FAIL" "Token doğrulanamadı"
    fi
else
    print_result "FAIL" "İç kullanıcı token'ı alınamadı"
fi

echo ""

# Senaryo 2: İç Kullanıcı - Karma Uygulama (Token Exchange YOK)
print_scenario "Senaryo 2: İç Kullanıcı → Karma Uygulama"
print_info "Durum: Token Exchange YAPILMAZ - Aynı realm, farklı client"
print_info "Sebep: Kullanıcı zaten Keycloak-A'da, doğrudan karma uygulamaya token alabilir"

IC_KARMA_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI&username=ic_kullanici&password=password123&scope=openid profile email" | \
  jq -r '.access_token')

if [ "$IC_KARMA_TOKEN" != "null" ] && [ -n "$IC_KARMA_TOKEN" ]; then
    print_result "SUCCESS" "İç kullanıcı karma uygulama token'ı alındı"
    
    USER_INFO=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
      -H "Authorization: Bearer $IC_KARMA_TOKEN")
    
    if [ -n "$USER_INFO" ] && [ "$USER_INFO" != "null" ]; then
        print_result "SUCCESS" "Token doğrulandı, user bilgileri mevcut"
        echo "User: $(echo $USER_INFO | jq -r '.preferred_username')"
    else
        print_result "FAIL" "Token doğrulanamadı"
    fi
else
    print_result "FAIL" "İç kullanıcı karma uygulama token'ı alınamadı"
fi

echo ""

# Senaryo 3: Vatandaş Kullanıcı - Vatandaş Uygulama (Token Exchange YOK)
print_scenario "Senaryo 3: Vatandaş Kullanıcı → Vatandaş Uygulama"
print_info "Durum: Token Exchange YAPILMAZ - Aynı realm, aynı client"
print_info "Sebep: Gereksiz, token zaten doğru client için"

VATANDAS_TOKEN=$(curl -s -X POST "$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=vatandas-uygulama&username=vatandas_kullanici&password=password123&scope=openid profile email" | \
  jq -r '.access_token')

if [ "$VATANDAS_TOKEN" != "null" ] && [ -n "$VATANDAS_TOKEN" ]; then
    print_result "SUCCESS" "Vatandaş kullanıcı token'ı alındı"
    
    USER_INFO=$(curl -s -X GET "$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/userinfo" \
      -H "Authorization: Bearer $VATANDAS_TOKEN")
    
    if [ -n "$USER_INFO" ] && [ "$USER_INFO" != "null" ]; then
        print_result "SUCCESS" "Token doğrulandı, user bilgileri mevcut"
        echo "User: $(echo $USER_INFO | jq -r '.preferred_username')"
    else
        print_result "FAIL" "Token doğrulanamadı"
    fi
else
    print_result "FAIL" "Vatandaş kullanıcı token'ı alınamadı"
fi

echo ""

# Senaryo 4: Vatandaş Kullanıcı - Karma Uygulama (Token Exchange YAPILIR)
print_scenario "Senaryo 4: Vatandaş Kullanıcı → Karma Uygulama"
print_info "Durum: Token Exchange YAPILIR - Farklı realm, farklı client"
print_info "Sebep: Vatandaş token'ı Keycloak-A'da geçerli değil, exchange gerekli"

print_info "Adım 1: Vatandaş token'ı Keycloak-A'da doğrula (başarısız olmalı)"
VALIDATION_RESULT=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
  -H "Authorization: Bearer $VATANDAS_TOKEN")

if [ -z "$VALIDATION_RESULT" ] || [ "$VALIDATION_RESULT" = "null" ]; then
    print_result "SUCCESS" "Vatandaş token'ı Keycloak-A'da geçersiz (beklenen)"
else
    print_result "FAIL" "Vatandaş token'ı Keycloak-A'da geçerli (beklenmeyen)"
fi

print_info "Adım 2: Token exchange ile Keycloak-A token'ına dönüştür"
EXCHANGED_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI&subject_token=$VATANDAS_TOKEN&subject_token_type=urn:ietf:params:oauth:token-type:access_token&requested_token_type=urn:ietf:params:oauth:token-type:access_token" | \
  jq -r '.access_token')

if [ "$EXCHANGED_TOKEN" != "null" ] && [ -n "$EXCHANGED_TOKEN" ]; then
    print_result "SUCCESS" "Token exchange başarılı"
    
    print_info "Adım 3: Exchange edilen token'ı doğrula"
    EXCHANGED_USER_INFO=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
      -H "Authorization: Bearer $EXCHANGED_TOKEN")
    
    if [ -n "$EXCHANGED_USER_INFO" ] && [ "$EXCHANGED_USER_INFO" != "null" ]; then
        print_result "SUCCESS" "Exchange edilen token doğrulandı"
        echo "User: $(echo $EXCHANGED_USER_INFO | jq -r '.preferred_username')"
        echo "Email: $(echo $EXCHANGED_USER_INFO | jq -r '.email')"
    else
        print_result "FAIL" "Exchange edilen token doğrulanamadı"
    fi
else
    print_result "FAIL" "Token exchange başarısız"
    echo "Hata: Identity provider konfigürasyonu eksik olabilir"
fi

echo ""

# Senaryo 5: Internal Token Exchange (Aynı Realm, Farklı Client)
print_scenario "Senaryo 5: Internal Token Exchange (İç Kullanıcı)"
print_info "Durum: Token Exchange YAPILIR - Aynı realm, farklı client"
print_info "Sebep: Client değişikliği, scope/audience farklılığı"

print_info "Adım 1: İç kullanıcı token'ı ile token exchange"
INTERNAL_EXCHANGE=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI&subject_token=$IC_KARMA_TOKEN&subject_token_type=urn:ietf:params:oauth:token-type:access_token&requested_token_type=urn:ietf:params:oauth:token-type:access_token" | \
  jq -r '.access_token')

if [ "$INTERNAL_EXCHANGE" != "null" ] && [ -n "$INTERNAL_EXCHANGE" ]; then
    print_result "SUCCESS" "Internal token exchange başarılı"
    
    INTERNAL_USER_INFO=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
      -H "Authorization: Bearer $INTERNAL_EXCHANGE")
    
    if [ -n "$INTERNAL_USER_INFO" ] && [ "$INTERNAL_USER_INFO" != "null" ]; then
        print_result "SUCCESS" "Exchange edilen token doğrulandı"
        echo "User: $(echo $INTERNAL_USER_INFO | jq -r '.preferred_username')"
    else
        print_result "FAIL" "Exchange edilen token doğrulanamadı"
    fi
else
    print_result "FAIL" "Internal token exchange başarısız"
fi

echo ""

# Senaryo 6: Service Account Token Exchange (Token Exchange YOK)
print_scenario "Senaryo 6: Service Account Token"
print_info "Durum: Token Exchange YAPILMAZ - Service account token'ı"
print_info "Sebep: Service account token'ı zaten client için, user bilgisi yok"

SERVICE_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=karma-uygulama&client_secret=8tOTQi85ZGNA70Z1KMllLLMpLC0p1bbI" | \
  jq -r '.access_token')

if [ "$SERVICE_TOKEN" != "null" ] && [ -n "$SERVICE_TOKEN" ]; then
    print_result "SUCCESS" "Service account token alındı"
    
    SERVICE_USER_INFO=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
      -H "Authorization: Bearer $SERVICE_TOKEN")
    
    if [ -z "$SERVICE_USER_INFO" ] || [ "$SERVICE_USER_INFO" = "null" ]; then
        print_result "SUCCESS" "Service account token'ında user bilgisi yok (beklenen)"
    else
        print_result "FAIL" "Service account token'ında user bilgisi var (beklenmeyen)"
    fi
else
    print_result "FAIL" "Service account token alınamadı"
fi

echo ""
echo "=== Test Senaryoları Tamamlandı ==="
echo ""
echo "📋 Özet:"
echo "✅ Senaryo 1: İç → İç (Exchange YOK)"
echo "✅ Senaryo 2: İç → Karma (Exchange YOK)"  
echo "✅ Senaryo 3: Vatandaş → Vatandaş (Exchange YOK)"
echo "🔄 Senaryo 4: Vatandaş → Karma (Exchange YAPILIR)"
echo "🔄 Senaryo 5: Internal Exchange (Exchange YAPILIR)"
echo "✅ Senaryo 6: Service Account (Exchange YOK)"
