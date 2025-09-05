#!/bin/bash

# Test Senaryoları Scripti

KEYCLOAK_A_URL="http://localhost:8080"
KEYCLOAK_B_URL="http://localhost:8081"

echo "=== Keycloak Federasyon Test Senaryoları ==="
echo ""

# Test 1: İç kullanıcı token'ı (Keycloak-A)
echo "1️⃣ İç Kullanıcı Token Testi (Keycloak-A)"
echo "----------------------------------------"
IC_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=ic-uygulama&username=ic_kullanici&password=password123" | \
  jq -r '.access_token')

if [ "$IC_TOKEN" != "null" ] && [ -n "$IC_TOKEN" ]; then
  echo "✅ İç kullanıcı token'ı başarıyla alındı"
  echo "Token: ${IC_TOKEN:0:50}..."
  
  # Token'ı doğrula
  echo "Token doğrulanıyor..."
  USER_INFO=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
    -H "Authorization: Bearer $IC_TOKEN")
  echo "Kullanıcı bilgileri: $USER_INFO"
else
  echo "❌ İç kullanıcı token'ı alınamadı"
fi

echo ""

# Test 2: Vatandaş kullanıcı token'ı (Keycloak-B)
echo "2️⃣ Vatandaş Kullanıcı Token Testi (Keycloak-B)"
echo "----------------------------------------------"
VATANDAS_TOKEN=$(curl -s -X POST "$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=vatandas-uygulama&username=vatandas_kullanici&password=password123" | \
  jq -r '.access_token')

if [ "$VATANDAS_TOKEN" != "null" ] && [ -n "$VATANDAS_TOKEN" ]; then
  echo "✅ Vatandaş kullanıcı token'ı başarıyla alındı"
  echo "Token: ${VATANDAS_TOKEN:0:50}..."
  
  # Token'ı doğrula
  echo "Token doğrulanıyor..."
  USER_INFO=$(curl -s -X GET "$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/userinfo" \
    -H "Authorization: Bearer $VATANDAS_TOKEN")
  echo "Kullanıcı bilgileri: $USER_INFO"
else
  echo "❌ Vatandaş kullanıcı token'ı alınamadı"
fi

echo ""

# Test 3: Token Exchange (Vatandaş token'ını Keycloak-A'da doğrula)
echo "3️⃣ Token Exchange Testi (Vatandaş → Keycloak-A)"
echo "------------------------------------------------"
if [ "$VATANDAS_TOKEN" != "null" ] && [ -n "$VATANDAS_TOKEN" ]; then
  echo "Vatandaş token'ı Keycloak-A'da doğrulanıyor..."
  
  # Keycloak-A'da vatandaş token'ını doğrula
  EXCHANGE_RESPONSE=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id=karma-uygulama&subject_token=$VATANDAS_TOKEN&subject_issuer=keycloak-b")
  
  EXCHANGED_TOKEN=$(echo "$EXCHANGE_RESPONSE" | jq -r '.access_token')
  
  if [ "$EXCHANGED_TOKEN" != "null" ] && [ -n "$EXCHANGED_TOKEN" ]; then
    echo "✅ Token exchange başarılı"
    echo "Yeni token: ${EXCHANGED_TOKEN:0:50}..."
    
    # Yeni token'ı doğrula
    echo "Exchange edilen token doğrulanıyor..."
    USER_INFO=$(curl -s -X GET "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/userinfo" \
      -H "Authorization: Bearer $EXCHANGED_TOKEN")
    echo "Kullanıcı bilgileri: $USER_INFO"
  else
    echo "❌ Token exchange başarısız"
    echo "Hata: $EXCHANGE_RESPONSE"
  fi
else
  echo "❌ Vatandaş token'ı olmadığı için token exchange test edilemiyor"
fi

echo ""

# Test 4: Karma uygulama erişimi
echo "4️⃣ Karma Uygulama Erişim Testi"
echo "------------------------------"

# İç kullanıcı ile karma uygulamaya erişim
echo "İç kullanıcı ile karma uygulamaya erişim..."
KARMA_IC_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/kamunet/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=karma-uygulama&username=ic_kullanici&password=password123" | \
  jq -r '.access_token')

if [ "$KARMA_IC_TOKEN" != "null" ] && [ -n "$KARMA_IC_TOKEN" ]; then
  echo "✅ İç kullanıcı karma uygulamaya erişebildi"
else
  echo "❌ İç kullanıcı karma uygulamaya erişemedi"
fi

echo ""
echo "=== Test Senaryoları Tamamlandı ==="
