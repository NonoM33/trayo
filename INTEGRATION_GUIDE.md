# Guide d'Intégration API Trayo

## Table des matières

1. [Introduction](#introduction)
2. [Authentification](#authentification)
3. [API REST v1](#api-rest-v1)
4. [API REST v2](#api-rest-v2)
5. [API GraphQL](#api-graphql)
6. [WebSockets et SSE](#websockets-et-sse)
7. [Exemples de code](#exemples-de-code)
8. [Gestion des erreurs](#gestion-des-erreurs)

---

## Introduction

L'API Trayo propose trois interfaces pour intégrer votre application :

- **REST v1** : API existante (maintenue pour backward compatibility)
- **REST v2** : API complète avec pagination, filtres et recherche avancés
- **GraphQL** : API flexible pour requêtes complexes et temps réel
- **WebSockets/SSE** : Communication temps réel via Action Cable

### Base URLs

- **Développement** : `http://localhost:3000`
- **Production** : `https://api.trayo.com`

### Endpoints disponibles

- **REST v1** : `/api/v1/*`
- **REST v2** : `/api/v2/*`
- **GraphQL** : `/graphql` (POST) et `/graphiql` (GET - interface GraphiQL)
- **WebSocket** : `/cable` (Action Cable)
- **SSE** : `/api/v2/events` (Server-Sent Events)

---

## Authentification

### JWT Token

Toutes les API (sauf endpoints publics) nécessitent un token JWT dans le header `Authorization` :

```
Authorization: Bearer <token>
```

### Obtenir un token

#### REST v2

```bash
curl -X POST http://localhost:3000/api/v2/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Réponse :**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "mt5_api_token": "abc123def456ghi789"
  }
}
```

#### GraphQL

```graphql
mutation {
  loginUser(email: "user@example.com", password: "password123") {
    token
    user {
      id
      email
      firstName
      lastName
    }
    errors {
      field
      message
    }
  }
}
```

### MT5 API Key

Pour la synchronisation MT5 (endpoints `/api/v1/mt5/*`), utilisez le header `X-API-Key` :

```
X-API-Key: <mt5_api_token>
```

---

## API REST v1

L'API REST v1 est maintenue pour la backward compatibility. Consultez `swagger.yaml` pour la documentation complète.

**Important** : Les routes `/api/v1/mt5/sync` et `/api/v1/mt5/sync_complete_history` ne doivent **JAMAIS** être modifiées.

### Endpoints principaux

- `POST /api/v1/register` - Inscription
- `POST /api/v1/login` - Connexion
- `POST /api/v1/mt5/sync` - Synchronisation MT5 (ne pas modifier)
- `GET /api/v1/accounts/balance` - Balance des comptes
- `GET /api/v1/accounts/trades` - Liste des trades
- `GET /api/v1/bots` - Liste des bots

---

## API REST v2

L'API REST v2 offre une interface complète avec pagination cursor-based, filtres avancés et recherche full-text.

### Authentification

Tous les endpoints nécessitent un token JWT :

```
Authorization: Bearer <token>
```

### Pagination Cursor-Based

La pagination utilise des curseurs au lieu de pages numériques :

**Format :**
```
?cursor=<id>&limit=20&direction=next
```

**Paramètres :**
- `cursor` : ID ou timestamp du dernier élément (optionnel pour la première page)
- `limit` : Nombre d'éléments par page (1-100, défaut: 20)
- `direction` : `next` ou `prev` (défaut: `next`)

**Exemple :**

```bash
curl -X GET "http://localhost:3000/api/v2/trades?cursor=123&limit=20&direction=next" \
  -H "Authorization: Bearer <token>"
```

**Réponse :**

```json
{
  "data": [...],
  "next_cursor": "456",
  "prev_cursor": "123",
  "has_more": true
}
```

### Filtres Avancés

Les filtres utilisent la syntaxe suivante :

```
?filters[field][operator]=value
```

**Opérateurs disponibles :**
- `eq` : égal
- `neq` : différent
- `gt` : supérieur
- `gte` : supérieur ou égal
- `lt` : inférieur
- `lte` : inférieur ou égal
- `in` : dans la liste
- `not_in` : pas dans la liste
- `like` : contient (case-insensitive)
- `between` : entre deux valeurs

**Exemple :**

```bash
curl -X GET "http://localhost:3000/api/v2/trades?filters[symbol][eq]=EURUSD&filters[profit][gt]=0" \
  -H "Authorization: Bearer <token>"
```

### Recherche Full-Text

La recherche utilise le paramètre `search` :

```
?search=term&search_fields=field1,field2
```

**Exemple :**

```bash
curl -X GET "http://localhost:3000/api/v2/trades?search=EURUSD&search_fields=symbol,trade_id" \
  -H "Authorization: Bearer <token>"
```

### Endpoints

#### Authentification

- `POST /api/v2/auth/register` - Inscription
- `POST /api/v2/auth/login` - Connexion
- `POST /api/v2/auth/logout` - Déconnexion
- `POST /api/v2/auth/refresh` - Rafraîchir le token
- `GET /api/v2/auth/me` - Utilisateur connecté

#### Comptes MT5

- `GET /api/v2/accounts` - Liste des comptes (pagination, filtres, recherche)
- `GET /api/v2/accounts/:id` - Détails d'un compte
- `GET /api/v2/accounts/:id/balance` - Balance d'un compte
- `GET /api/v2/accounts/:id/trades` - Trades d'un compte (pagination, filtres)
- `GET /api/v2/accounts/:id/projection` - Projection financière
- `GET /api/v2/accounts/:id/stats` - Statistiques d'un compte

#### Trades

- `GET /api/v2/trades` - Liste des trades (pagination, filtres, recherche)
- `GET /api/v2/trades/:id` - Détails d'un trade
- `GET /api/v2/trades/stats` - Statistiques agrégées
- `GET /api/v2/trades/export` - Export CSV

#### Bots

- `GET /api/v2/bots` - Liste des bots disponibles
- `GET /api/v2/bots/:id` - Détails d'un bot
- `GET /api/v2/my_bots` - Mes bots achetés
- `GET /api/v2/bot_purchases` - Liste des achats de bots
- `GET /api/v2/bot_purchases/:id` - Détails d'un achat
- `POST /api/v2/bot_purchases` - Acheter un bot
- `GET /api/v2/bot_purchases/:id/status` - Statut d'un bot
- `POST /api/v2/bot_purchases/:id/start` - Démarrer un bot
- `POST /api/v2/bot_purchases/:id/stop` - Arrêter un bot
- `POST /api/v2/bot_purchases/:id/performance` - Mettre à jour les performances

#### VPS

- `GET /api/v2/vps` - Liste des VPS
- `GET /api/v2/vps/:id` - Détails d'un VPS

#### Paiements

- `GET /api/v2/payments` - Liste des paiements (pagination, filtres)
- `GET /api/v2/payments/:id` - Détails d'un paiement
- `POST /api/v2/payments` - Créer un paiement
- `GET /api/v2/payments/balance_due` - Solde dû

#### Crédits

- `GET /api/v2/credits` - Liste des crédits
- `GET /api/v2/credits/:id` - Détails d'un crédit

#### Statistiques

- `GET /api/v2/stats/dashboard` - Données du dashboard
- `GET /api/v2/stats/profits` - Profits (filtres période)
- `GET /api/v2/stats/trades` - Statistiques des trades

#### Utilisateur

- `GET /api/v2/users/me` - Profil utilisateur
- `PATCH /api/v2/users/me` - Mettre à jour le profil
- `PATCH /api/v2/users/me/password` - Changer le mot de passe
- `DELETE /api/v2/users/me` - Supprimer le compte

---

## API GraphQL

GraphQL offre une interface flexible pour requêtes complexes et temps réel.

### Endpoint

- **POST** `/graphql` - API GraphQL
- **GET** `/graphiql` - Interface GraphiQL (développement uniquement)

### Authentification

Utilisez le header `Authorization` :

```
Authorization: Bearer <token>
```

### Queries

#### Utilisateur

```graphql
query {
  user {
    id
    email
    firstName
    lastName
    mt5Accounts {
      id
      mt5Id
      accountName
      balance
    }
  }
}
```

#### Comptes MT5

```graphql
query {
  mt5Accounts {
    id
    mt5Id
    accountName
    balance
    equity
    netGains
    trades {
      edges {
        node {
          id
          symbol
          profit
          closeTime
        }
      }
    }
  }
}
```

#### Trades avec filtres

```graphql
query {
  trades(
    symbol: "EURUSD"
    status: "closed"
    startDate: "2025-01-01T00:00:00Z"
    endDate: "2025-12-31T23:59:59Z"
  ) {
    edges {
      node {
        id
        tradeId
        symbol
        tradeType
        profit
        commission
        swap
        openTime
        closeTime
        botName
      }
      cursor
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
  }
}
```

#### Statistiques

```graphql
query {
  stats(period: "30_days", botId: "1") {
    totalProfit
    totalTrades
    winningTrades
    losingTrades
    winRate
    averageProfit
    bestTrade
    worstTrade
  }
}
```

#### Dashboard

```graphql
query {
  dashboard {
    totalBalance
    totalProfits
    totalCommissionDue
    totalCredits
    balanceDue
    accountsCount
    botsCount
    activeBotsCount
    recentTradesCount
  }
}
```

### Mutations

#### Inscription

```graphql
mutation {
  registerUser(
    email: "user@example.com"
    password: "password123"
    passwordConfirmation: "password123"
    firstName: "John"
    lastName: "Doe"
  ) {
    token
    user {
      id
      email
    }
    errors {
      field
      message
    }
  }
}
```

#### Connexion

```graphql
mutation {
  loginUser(
    email: "user@example.com"
    password: "password123"
  ) {
    token
    user {
      id
      email
    }
    errors {
      field
      message
    }
  }
}
```

#### Acheter un bot

```graphql
mutation {
  purchaseBot(botId: "1") {
    botPurchase {
      id
      pricePaid
      status
      isRunning
      tradingBot {
        id
        name
        description
      }
    }
    errors {
      field
      message
    }
  }
}
```

#### Démarrer/Arrêter un bot

```graphql
mutation {
  startBot(purchaseId: "1") {
    botPurchase {
      id
      isRunning
      startedAt
    }
    errors {
      field
      message
    }
  }
}
```

#### Mettre à jour le profil

```graphql
mutation {
  updateProfile(
    firstName: "Jane"
    lastName: "Smith"
  ) {
    user {
      id
      firstName
      lastName
    }
    errors {
      field
      message
    }
  }
}
```

### Subscriptions (Temps Réel)

Les subscriptions GraphQL utilisent WebSockets via Action Cable.

#### Nouveau trade créé

```graphql
subscription {
  tradeCreated(userId: "1") {
    trade {
      id
      tradeId
      symbol
      profit
      closeTime
      botName
    }
  }
}
```

#### Mise à jour de balance

```graphql
subscription {
  accountBalanceUpdated(accountId: "1") {
    mt5Account {
      id
      mt5Id
      balance
      equity
      netGains
    }
  }
}
```

#### Changement de statut de bot

```graphql
subscription {
  botStatusChanged(purchaseId: "1") {
    botPurchase {
      id
      status
      isRunning
      totalProfit
      currentDrawdown
    }
  }
}
```

---

## WebSockets et SSE

### WebSockets (Action Cable)

Les WebSockets sont utilisés pour les subscriptions GraphQL et les channels personnalisés.

**Endpoint :** `ws://localhost:3000/cable` (ou `wss://` en production)

**Authentification :**

```
Authorization: Bearer <token>
```

**Channels disponibles :**
- `AccountChannel` : Mises à jour de balance
- `TradeChannel` : Nouveaux trades
- `BotChannel` : Changements de statut de bots
- `PaymentChannel` : Nouveaux paiements

### Server-Sent Events (SSE)

L'endpoint SSE permet de recevoir des événements temps réel via HTTP.

**Endpoint :** `GET /api/v2/events`

**Paramètres :**
- `channels` : Liste des channels à écouter (séparés par virgule) : `account,trade,bot,payment`

**Exemple :**

```bash
curl -X GET "http://localhost:3000/api/v2/events?channels=trade,account" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: text/event-stream"
```

**Réponse :**

```
data: {"type":"connected","channels":["trade","account"]}

data: {"type":"trade_created","trade":{"id":1,"symbol":"EURUSD","profit":100.5}}

data: {"type":"account_balance_updated","account":{"id":1,"balance":10000.5}}
```

**Format des événements :**

- `trade_created` : Nouveau trade créé
- `trade_updated` : Trade mis à jour
- `account_balance_updated` : Balance mise à jour
- `bot_status_changed` : Statut de bot changé
- `payment_created` : Nouveau paiement créé

---

## Exemples de code

### JavaScript/TypeScript (Fetch)

```javascript
// Authentification
async function login(email, password) {
  const response = await fetch('http://localhost:3000/api/v2/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });
  const data = await response.json();
  return data.token;
}

// Récupérer les trades avec pagination
async function getTrades(token, cursor = null) {
  const url = new URL('http://localhost:3000/api/v2/trades');
  if (cursor) url.searchParams.set('cursor', cursor);
  url.searchParams.set('limit', '20');
  
  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  });
  return await response.json();
}

// GraphQL Query
async function graphqlQuery(token, query, variables = {}) {
  const response = await fetch('http://localhost:3000/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({ query, variables }),
  });
  return await response.json();
}

// Utilisation
const token = await login('user@example.com', 'password123');
const trades = await getTrades(token);

// GraphQL
const result = await graphqlQuery(token, `
  query {
    user {
      id
      email
      mt5Accounts {
        id
        balance
      }
    }
  }
`);
```

### Python (Requests)

```python
import requests

BASE_URL = "http://localhost:3000/api/v2"

def login(email, password):
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": password}
    )
    return response.json()["token"]

def get_trades(token, cursor=None):
    params = {"limit": 20}
    if cursor:
        params["cursor"] = cursor
    
    response = requests.get(
        f"{BASE_URL}/trades",
        headers={"Authorization": f"Bearer {token}"},
        params=params
    )
    return response.json()

# Utilisation
token = login("user@example.com", "password123")
trades = get_trades(token)
```

### React (useEffect + Fetch)

```jsx
import { useState, useEffect } from 'react';

function useTrades(token) {
  const [trades, setTrades] = useState([]);
  const [loading, setLoading] = useState(true);
  const [cursor, setCursor] = useState(null);
  const [hasMore, setHasMore] = useState(false);

  useEffect(() => {
    async function fetchTrades() {
      setLoading(true);
      const url = new URL('http://localhost:3000/api/v2/trades');
      if (cursor) url.searchParams.set('cursor', cursor);
      url.searchParams.set('limit', '20');
      
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });
      const data = await response.json();
      
      setTrades(data.data);
      setCursor(data.next_cursor);
      setHasMore(data.has_more);
      setLoading(false);
    }
    
    fetchTrades();
  }, [token, cursor]);

  return { trades, loading, hasMore, loadMore: () => setCursor(cursor) };
}
```

### SSE (EventSource)

```javascript
const token = 'your_jwt_token';
const eventSource = new EventSource(
  `http://localhost:3000/api/v2/events?channels=trade,account`,
  {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  }
);

eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Event received:', data);
  
  if (data.type === 'trade_created') {
    console.log('New trade:', data.trade);
  } else if (data.type === 'account_balance_updated') {
    console.log('Balance updated:', data.account);
  }
};

eventSource.onerror = (error) => {
  console.error('SSE error:', error);
};
```

---

## Gestion des erreurs

### Codes HTTP

- `200` : Succès
- `201` : Créé avec succès
- `400` : Requête invalide
- `401` : Non autorisé (token invalide ou manquant)
- `403` : Interdit (permissions insuffisantes)
- `404` : Ressource non trouvée
- `422` : Erreur de validation
- `500` : Erreur serveur

### Format des erreurs REST

```json
{
  "error": "Message d'erreur"
}
```

ou

```json
{
  "errors": ["Erreur 1", "Erreur 2"]
}
```

### Format des erreurs GraphQL

```json
{
  "errors": [
    {
      "message": "Message d'erreur",
      "extensions": {
        "code": "UNAUTHORIZED"
      }
    }
  ],
  "data": null
}
```

### Exemples de gestion d'erreurs

```javascript
async function handleApiCall(url, options) {
  try {
    const response = await fetch(url, options);
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || error.message || 'Erreur API');
    }
    
    return await response.json();
  } catch (error) {
    console.error('API Error:', error);
    throw error;
  }
}
```

---

## Ressources supplémentaires

- **Swagger UI** : `http://localhost:3000/api-docs` (documentation REST v1)
- **GraphiQL** : `http://localhost:3000/graphiql` (interface GraphQL interactive)
- **Support** : support@trayo.com

---

**Dernière mise à jour** : Janvier 2025

