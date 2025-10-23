# API Examples - Commandes cURL

## 1. Inscription d'un utilisateur

```bash
curl -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "first_name": "John",
      "last_name": "Doe"
    }
  }'
```

Réponse :

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "test@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

**Sauvegarder le token pour les requêtes suivantes !**

## 2. Connexion

```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## 3. Synchronisation MT5 (Script)

```bash
curl -X POST http://localhost:3000/api/v1/mt5/sync \
  -H "Content-Type: application/json" \
  -H "X-API-Key: mt5_secret_key_change_in_production" \
  -d '{
    "mt5_data": {
      "mt5_id": "123456789",
      "user_id": 1,
      "account_name": "Demo Trading Account",
      "balance": 10000.50,
      "trades": [
        {
          "trade_id": "987654321",
          "symbol": "EURUSD",
          "trade_type": "buy",
          "volume": 0.1,
          "open_price": 1.1234,
          "close_price": 1.1250,
          "profit": 16.00,
          "commission": -0.50,
          "swap": 0.00,
          "open_time": "2025-10-23T10:00:00Z",
          "close_time": "2025-10-23T11:00:00Z",
          "status": "closed"
        },
        {
          "trade_id": "987654322",
          "symbol": "GBPUSD",
          "trade_type": "sell",
          "volume": 0.2,
          "open_price": 1.2650,
          "close_price": 1.2600,
          "profit": 100.00,
          "commission": -1.00,
          "swap": -0.50,
          "open_time": "2025-10-23T09:00:00Z",
          "close_time": "2025-10-23T10:30:00Z",
          "status": "closed"
        }
      ]
    }
  }'
```

## 4. Récupérer le solde (Client)

```bash
curl -X GET http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Réponse :

```json
{
  "accounts": [
    {
      "id": 1,
      "mt5_id": "123456789",
      "account_name": "Demo Trading Account",
      "balance": 10000.5,
      "last_sync_at": "2025-10-23T12:00:00Z"
    }
  ],
  "total_balance": 10000.5
}
```

## 5. Récupérer les 20 derniers trades (Client)

```bash
curl -X GET http://localhost:3000/api/v1/accounts/trades \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 6. Récupérer la projection sur 30 jours (Client)

```bash
curl -X GET "http://localhost:3000/api/v1/accounts/projection?days=30" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Réponse :

```json
{
  "projections": [
    {
      "account_id": 1,
      "mt5_id": "123456789",
      "account_name": "Demo Trading Account",
      "current_balance": 10000.5,
      "projected_balance": 11500.75,
      "daily_average": 50.0,
      "projected_profit": 1500.0,
      "confidence": "high",
      "based_on_days": 25
    }
  ],
  "summary": {
    "total_current_balance": 10000.5,
    "total_projected_balance": 11500.75,
    "projected_difference": 1500.25,
    "projection_days": 30
  }
}
```

## 7. Projection personnalisée (60 jours)

```bash
curl -X GET "http://localhost:3000/api/v1/accounts/projection?days=60" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Workflow complet

### 1. Créer un utilisateur

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "trader@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "first_name": "Trader",
      "last_name": "Pro"
    }
  }' | jq -r '.token')

echo "Token: $TOKEN"
```

### 2. Synchroniser les données MT5 (remplacer USER_ID par l'ID retourné)

```bash
curl -X POST http://localhost:3000/api/v1/mt5/sync \
  -H "Content-Type: application/json" \
  -H "X-API-Key: mt5_secret_key_change_in_production" \
  -d '{
    "mt5_data": {
      "mt5_id": "123456789",
      "user_id": 1,
      "account_name": "My MT5 Account",
      "balance": 15000.00,
      "trades": []
    }
  }'
```

### 3. Consulter le solde

```bash
curl -X GET http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 4. Consulter la projection

```bash
curl -X GET "http://localhost:3000/api/v1/accounts/projection?days=30" \
  -H "Authorization: Bearer $TOKEN" | jq
```

## Notes

- Remplacer `YOUR_JWT_TOKEN` par le token reçu lors de l'inscription ou de la connexion
- L'API Key MT5 par défaut est `mt5_secret_key_change_in_production` (à changer en production)
- Le `user_id` dans la requête de sync doit correspondre à un utilisateur existant
- Les trades sont dédupliqués automatiquement par `trade_id`
- Installer `jq` pour formater les réponses JSON : `brew install jq` (macOS) ou `apt install jq` (Linux)
