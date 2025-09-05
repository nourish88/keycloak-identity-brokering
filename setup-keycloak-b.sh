#!/bin/bash

# Keycloak-B (Vatandaş) Konfigürasyon Scripti

KEYCLOAK_B_URL="http://localhost:8081"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

echo "Keycloak-B (Vatandaş) konfigürasyonu başlatılıyor..."

# Admin token al
ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_B_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=admin-cli&username=$ADMIN_USER&password=$ADMIN_PASSWORD" | \
  jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "Admin token alınamadı. Keycloak-B'nin çalıştığından emin olun."
  exit 1
fi

echo "Admin token alındı."

# Vatandaş realm'i oluştur
echo "Vatandaş realm'i oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_B_URL/admin/realms" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "vatandas",
    "enabled": true,
    "displayName": "Vatandaş - Dış Kullanıcılar",
    "loginWithEmailAllowed": true,
    "duplicateEmailsAllowed": false,
    "resetPasswordAllowed": true,
    "editUsernameAllowed": true,
    "bruteForceProtected": true
  }'

# Vatandaş kullanıcı oluştur
echo "Vatandaş kullanıcı oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_B_URL/admin/realms/vatandas/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "vatandas_kullanici",
    "enabled": true,
    "firstName": "Vatandaş",
    "lastName": "Kullanıcı",
    "email": "vatandas@example.com",
    "credentials": [{
      "type": "password",
      "value": "password123",
      "temporary": false
    }]
  }'

# Vatandaş uygulama client'ı oluştur
echo "Vatandaş uygulama client'ı oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_B_URL/admin/realms/vatandas/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "vatandas-uygulama",
    "enabled": true,
    "publicClient": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": false,
    "redirectUris": ["http://localhost:3000/*"],
    "webOrigins": ["http://localhost:3000"]
  }'

# Brokering için client oluştur (Keycloak-A'dan erişim için)
echo "Brokering client'ı oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_B_URL/admin/realms/vatandas/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "keycloak-a-broker",
    "enabled": true,
    "publicClient": false,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": true,
    "redirectUris": ["http://localhost:8080/realms/kamunet/broker/keycloak-b/endpoint"],
    "webOrigins": ["http://localhost:8080"]
  }'

echo "Keycloak-B konfigürasyonu tamamlandı!"
echo "Admin Console: $KEYCLOAK_B_URL/admin"
echo "Realm: vatandas"
echo "Kullanıcı: vatandas_kullanici / password123"
echo "Client: vatandas-uygulama, keycloak-a-broker"
