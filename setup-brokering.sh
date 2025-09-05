#!/bin/bash

# Keycloak-A'da Keycloak-B'ye brokering konfigürasyonu

KEYCLOAK_A_URL="http://localhost:8080"
KEYCLOAK_B_URL="http://localhost:8081"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

echo "Brokering konfigürasyonu başlatılıyor..."

# Keycloak-A admin token al
ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_A_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=admin-cli&username=$ADMIN_USER&password=$ADMIN_PASSWORD" | \
  jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "Admin token alınamadı. Keycloak-A'nın çalıştığından emin olun."
  exit 1
fi

echo "Keycloak-A admin token alındı."

# Keycloak-B admin token al
echo "Keycloak-B admin token alınıyor..."
ADMIN_TOKEN_B=$(curl -s -X POST "$KEYCLOAK_B_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=admin-cli&username=$ADMIN_USER&password=$ADMIN_PASSWORD" | \
  jq -r '.access_token')

if [ "$ADMIN_TOKEN_B" = "null" ] || [ -z "$ADMIN_TOKEN_B" ]; then
  echo "Keycloak-B admin token alınamadı."
  exit 1
fi

# Keycloak-B'de brokering client'ının client secret'ını al
echo "Keycloak-B'den client secret alınıyor..."
CLIENT_SECRET=$(curl -s -X GET "$KEYCLOAK_B_URL/admin/realms/vatandas/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN_B" | \
  jq -r '.[] | select(.clientId=="keycloak-a-broker") | .id')

if [ -z "$CLIENT_SECRET" ]; then
  echo "Keycloak-B'de brokering client'ı bulunamadı."
  exit 1
fi

# Keycloak-A'da Keycloak-B identity provider oluştur
echo "Keycloak-A'da Keycloak-B identity provider oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_A_URL/admin/realms/kamunet/identity-provider/instances" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"alias\": \"keycloak-b\",
    \"providerId\": \"keycloak-oidc\",
    \"enabled\": true,
    \"config\": {
      \"clientId\": \"keycloak-a-broker\",
      \"clientSecret\": \"$CLIENT_SECRET\",
      \"authorizationUrl\": \"$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/auth\",
      \"tokenUrl\": \"$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/token\",
      \"userInfoUrl\": \"$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/userinfo\",
      \"issuer\": \"$KEYCLOAK_B_URL/realms/vatandas\",
      \"jwksUrl\": \"$KEYCLOAK_B_URL/realms/vatandas/protocol/openid-connect/certs\",
      \"validateSignature\": \"true\",
      \"useJwksUrl\": \"true\",
      \"syncMode\": \"IMPORT\",
      \"clientAuthMethod\": \"client_secret_post\"
    }
  }"

# Token exchange politikası oluştur
echo "Token exchange politikası oluşturuluyor..."
curl -s -X POST "$KEYCLOAK_A_URL/admin/realms/kamunet/client-policies/policies" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "token-exchange-policy",
    "description": "Token exchange için politika",
    "enabled": true,
    "conditions": [
      {
        "condition": "client-roles",
        "configuration": {
          "roles": ["token-exchange"]
        }
      }
    ],
    "profiles": [
      {
        "name": "token-exchange-profile",
        "executors": [
          {
            "executor": "token-exchange",
            "configuration": {
              "allowed-audiences": ["karma-uygulama"]
            }
          }
        ]
      }
    ]
  }'

echo "Brokering konfigürasyonu tamamlandı!"
echo "Keycloak-A'da Keycloak-B identity provider aktif."
echo "Token exchange politikası oluşturuldu."
