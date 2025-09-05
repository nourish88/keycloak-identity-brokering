#!/bin/bash

# Keycloak-A (Kamunet) Konfigürasyon Scripti

KEYCLOAK_A_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

echo "Keycloak-A (Kamunet) konfigürasyonu başlatılıyor..."

# Admin token al
ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=admin-cli&username=$ADMIN_USER&password=$ADMIN_PASSWORD" | \
  jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "Admin token alınamadı. Keycloak-A'nın çalıştığından emin olun."
  exit 1
fi

echo "Admin token alındı."

# Kamunet realm'i oluştur
echo "Kamunet realm'i oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_A_URL/admin/realms" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "kamunet",
    "enabled": true,
    "displayName": "Kamunet - İç Kullanıcılar",
    "loginWithEmailAllowed": false,
    "duplicateEmailsAllowed": false,
    "resetPasswordAllowed": true,
    "editUsernameAllowed": false,
    "bruteForceProtected": true
  }'

# İç kullanıcı oluştur
echo "İç kullanıcı oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_A_URL/admin/realms/kamunet/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ic_kullanici",
    "enabled": true,
    "firstName": "İç",
    "lastName": "Kullanıcı",
    "email": "ic@kamunet.gov.tr",
    "credentials": [{
      "type": "password",
      "value": "password123",
      "temporary": false
    }]
  }'

# İç uygulama client'ı oluştur
echo "İç uygulama client'ı oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_A_URL/admin/realms/kamunet/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "ic-uygulama",
    "enabled": true,
    "publicClient": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": false,
    "redirectUris": ["http://localhost:3000/*"],
    "webOrigins": ["http://localhost:3000"]
  }'

# Karma uygulama client'ı oluştur (Confidential + Service Account)
echo "Karma uygulama client'ı oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_A_URL/admin/realms/kamunet/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "karma-uygulama",
    "enabled": true,
    "publicClient": false,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": true,
    "redirectUris": ["http://localhost:3000/*"],
    "webOrigins": ["http://localhost:3000"]
  }'

# Karma uygulama client'ında token exchange'i aktif et
echo "Karma uygulama client'ında token exchange aktif ediliyor..."
KARMA_CLIENT_ID=$(curl -s -X GET "$KEYCLOAK_A_URL/admin/realms/kamunet/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | \
  jq -r '.[] | select(.clientId=="karma-uygulama") | .id')

curl -s -X PUT "$KEYCLOAK_A_URL/admin/realms/kamunet/clients/$KARMA_CLIENT_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"attributes": {"token.exchange": "true"}}'

echo "Keycloak-A konfigürasyonu tamamlandı!"
echo "Admin Console: $KEYCLOAK_A_URL/admin"
echo "Realm: kamunet"
echo "Kullanıcı: ic_kullanici / password123"
echo "Client: ic-uygulama (public), karma-uygulama (confidential + token exchange)"
