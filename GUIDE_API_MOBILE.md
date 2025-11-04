# Guide API Trayo - Développement Application Mobile

## 🎯 Vue d'Ensemble

API REST Rails pour application mobile de gestion de trading MT5. L'API utilise **JWT** pour l'authentification et retourne du **JSON**.

**Base URL** : `http://localhost:3000/api/v1` (dev) ou `https://api.trayo.com/api/v1` (prod)

---

## 🔐 Authentification

### 1. Inscription
```http
POST /api/v1/register
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

**Réponse** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "mt5_api_token": "abc123def456..."
  }
}
```

**RG** : Stocker le `token` JWT pour toutes les requêtes suivantes. Valide 24h.

---

### 2. Connexion
```http
POST /api/v1/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Réponse** : Identique à `/register`

**RG** : Token JWT dans header `Authorization: Bearer <token>` pour endpoints protégés.

---

## 📊 Comptes MT5

### 3. Balance de tous les comptes
```http
GET /api/v1/accounts/balance
Authorization: Bearer <token>
```

**Réponse** :
```json
{
  "accounts": [
    {
      "id": 1,
      "mt5_id": "123456789",
      "account_name": "Demo Trading Account",
      "balance": 10000.50,
      "last_sync_at": "2025-10-23T12:00:00Z"
    }
  ],
  "total_balance": 10000.50
}
```

**RG** : 
- Afficher `total_balance` dans dashboard
- Liste des comptes avec balance individuelle
- Format monétaire : `10 000,50 €`

---

### 4. Derniers trades
```http
GET /api/v1/accounts/trades
Authorization: Bearer <token>
```

**Réponse** :
```json
{
  "trades": [
    {
      "id": 1,
      "trade_id": "987654321",
      "account_name": "Demo Trading Account",
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
    }
  ]
}
```

**RG** :
- Limite à 20 trades (API fixe)
- Trier par `close_time` décroissant
- Coloriser : profit positif (vert), négatif (rouge)
- Format date : "23 oct 2025, 14:30"

---

### 5. Projections financières
```http
GET /api/v1/accounts/projection?days=30
Authorization: Bearer <token>
```

**Paramètres** :
- `days` (optionnel, défaut: 30) : Nombre de jours pour projection (1-365)

**Réponse** :
```json
{
  "projections": [
    {
      "account_id": 1,
      "mt5_id": "123456789",
      "account_name": "Demo Trading Account",
      "current_balance": 10000.50,
      "projected_balance": 11500.75,
      "daily_average": 50.0,
      "projected_profit": 1500.0,
      "confidence": "high",
      "based_on_days": 25
    }
  ],
  "summary": {
    "total_current_balance": 10000.50,
    "total_projected_balance": 11500.75,
    "projected_difference": 1500.25,
    "projection_days": 30
  }
}
```

**RG** :
- `confidence` : "high" (20+ jours), "medium" (10-19), "low" (<10)
- Afficher badge de confiance avec couleur
- Permettre changement période (7, 30, 60, 90 jours)

---

## 🤖 Bots de Trading

### 6. Liste des bots
```http
GET /api/v1/bots
Authorization: Bearer <token>
```

**Note** : Utilise `mt5_api_token` ou token JWT. Voir authentification bots ci-dessous.

**Réponse** :
```json
{
  "success": true,
  "bots": [
    {
      "purchase_id": 1,
      "bot_id": 5,
      "bot_name": "Scalper Pro",
      "is_running": true,
      "max_drawdown_limit": 10.0,
      "current_drawdown": 2.5,
      "total_profit": 1250.50
    }
  ]
}
```

**RG** :
- Afficher seulement bots avec `status = 'active'`
- `is_running` : 🟢 Actif / 🔴 Inactif
- Alerte si `current_drawdown > max_drawdown_limit`

---

### 7. Statut d'un bot
```http
GET /api/v1/bots/:purchase_id/status
Authorization: Bearer <token>
```

**Réponse** :
```json
{
  "success": true,
  "bot_name": "Scalper Pro",
  "is_running": true,
  "max_drawdown_limit": 10.0,
  "current_drawdown": 2.5,
  "total_profit": 1250.50,
  "trades_count": 150,
  "message": "Bot active - trading autorisé"
}
```

**RG** :
- `is_running = false` → Bot en pause, ne pas trader
- Afficher message explicite
- Calculer ROI = `(total_profit / price_paid) × 100`

---

### 8. Mise à jour performances bot
```http
POST /api/v1/bots/:purchase_id/performance
Authorization: Bearer <token>
Content-Type: application/json

{
  "profit": 1250.50,
  "drawdown": 2.5
}
```

**Réponse** :
```json
{
  "success": true,
  "message": "Performance mise à jour",
  "is_running": true,
  "within_drawdown_limit": true
}
```

**RG** : Utilisé par script MT5 pour mettre à jour performances. App mobile peut utiliser pour refresh.

---

## 👤 Utilisateur

### 9. Informations utilisateur connecté
```http
GET /api/v1/users/me
Authorization: Bearer <token>
```

**Réponse** :
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "mt5_api_token": "abc123def456...",
    "mt5_accounts": [
      {
        "id": 1,
        "mt5_id": "123456789",
        "account_name": "Demo Trading Account",
        "balance": 10000.50
      }
    ]
  }
}
```

**RG** :
- Afficher nom complet dans profil
- `mt5_api_token` masqué partiellement (abc***def)
- Liste des comptes MT5 pour navigation

---

### 10. Liste tous les utilisateurs
```http
GET /api/v1/users
```

**Note** : Pas d'authentification requise (peut changer).

**RG** : Utilisé pour tests ou admin uniquement.

---

### 11. Supprimer un utilisateur
```http
DELETE /api/v1/users/:id
Authorization: Bearer <token>
```

**RG** : Utilisateur peut supprimer uniquement son propre compte.

---

## 🔄 Synchronisation MT5

**IMPORTANT** : Ces endpoints sont utilisés par le script MT5 installé sur le VPS, pas par l'app mobile.

### 12. Synchronisation standard
```http
POST /api/v1/mt5/sync
X-API-Key: <mt5_api_key>
Content-Type: application/json

{
  "mt5_data": {
    "mt5_id": "123456789",
    "mt5_api_token": "abc123...",
    "account_name": "Demo Account",
    "balance": 10000.50,
    "trades": [...],
    "open_positions": [...],
    "withdrawals": [...],
    "deposits": [...],
    "active_experts": [...]
  }
}
```

**RG** : Utilise `X-API-Key` header, pas JWT. App mobile ne doit PAS utiliser.

---

## 📱 Structure Recommandée App Mobile

### Écrans Principaux

1. **Connexion** → `/api/v1/login`
2. **Dashboard** → `/api/v1/users/me` + `/api/v1/accounts/balance` + `/api/v1/accounts/projection`
3. **Liste Comptes** → `/api/v1/users/me` (comptes dans user.mt5_accounts)
4. **Détails Compte** → `/api/v1/accounts/balance` + `/api/v1/accounts/trades`
5. **Liste Trades** → `/api/v1/accounts/trades`
6. **Liste Bots** → `/api/v1/bots`
7. **Détails Bot** → `/api/v1/bots/:purchase_id/status`
8. **Profil** → `/api/v1/users/me`

### Flux Typique

```
1. Connexion → POST /api/v1/login
   ↓
2. Stocker token JWT
   ↓
3. Dashboard → GET /api/v1/users/me + /accounts/balance + /accounts/projection
   ↓
4. Navigation selon action utilisateur
```

---

## 🔑 Gestion du Token

### Stockage
- **iOS** : Keychain
- **Android** : Keystore
- **React Native** : `react-native-keychain`
- **Flutter** : `flutter_secure_storage`

### Header pour Requêtes Authentifiées
```http
Authorization: Bearer <token_jwt>
```

### Expiration
- Token valide 24h
- Si 401 → Rediriger vers écran connexion
- Message : "Votre session a expiré, veuillez vous reconnecter"

---

## ⚠️ Règles de Gestion Critiques

### RG-001 : Format Monétaire
- Affichage : `10 000,50 €`
- Espace séparateur milliers
- Virgule décimale
- 2 décimales toujours

### RG-002 : Format Dates
- Affichage : "23 octobre 2025, 14:30"
- Timezone : UTC (convertir côté client si nécessaire)
- Relative : "Il y a 2 heures" pour trades récents

### RG-003 : Projections
- Basées sur moyennes des 30 derniers jours
- Non garanties, juste estimations
- Confiance dépend du nombre de jours de trading

### RG-004 : Drawdown
- Bot arrêté si `current_drawdown > max_drawdown_limit`
- Affichage jauge visuelle (vert/orange/rouge)

### RG-005 : Synchronisation
- Données MT5 synchronisées automatiquement par script VPS
- App mobile affiche seulement les données
- Actualisation toutes les 60 secondes recommandée

---

## 🎨 Formatage des Données

### Montants
- API retourne : `10000.50`
- App affiche : `10 000,50 €`
- Négatif : `-500,00 €` (rouge)

### Trades
- Profit positif : `+16,50 €` (vert)
- Profit négatif : `-8,30 €` (rouge)
- Type : Icône ↑ (buy) ou ↓ (sell)

### Statuts
- Bot actif : 🟢 "Actif"
- Bot inactif : 🔴 "En pause"
- Trade ouvert : Badge "Ouvert"

---

## 🚨 Gestion des Erreurs

### Erreurs Communes

**401 Unauthorized**
```json
{
  "error": "Unauthorized"
}
```
→ Token expiré ou invalide → Rediriger connexion

**422 Unprocessable Entity**
```json
{
  "errors": ["Email has already been taken"]
}
```
→ Erreurs de validation → Afficher messages utilisateur

**404 Not Found**
```json
{
  "success": false,
  "message": "Bot non trouvé"
}
```
→ Ressource non trouvée → Afficher message + navigation arrière

---

## 📝 Exemple Requête Complète

### Dashboard (3 appels en parallèle)

```javascript
// 1. Informations utilisateur
GET /api/v1/users/me
Authorization: Bearer <token>

// 2. Balance
GET /api/v1/accounts/balance
Authorization: Bearer <token>

// 3. Projections
GET /api/v1/accounts/projection?days=30
Authorization: Bearer <token>
```

**Implémentation** :
- Appels parallèles pour performance
- Afficher spinner pendant chargement
- Gérer erreurs individuellement
- Actualisation pull-to-refresh

---

## 🔄 Actualisation des Données

### Stratégie Recommandée

1. **Au démarrage** : Charger toutes les données
2. **Pull-to-refresh** : Actualiser manuellement
3. **Auto-refresh** : Toutes les 60 secondes (dashboard)
4. **Cache** : Stocker dernières données pour mode hors ligne

### Endpoints à Actualiser

- Dashboard : `/users/me`, `/accounts/balance`, `/accounts/projection`
- Détails compte : `/accounts/balance`, `/accounts/trades`
- Bots : `/bots`, `/bots/:id/status`

---

## 📋 Checklist Développement

- [ ] Gestion authentification JWT
- [ ] Stockage sécurisé token
- [ ] Gestion expiration token
- [ ] Formatage monétaire (€)
- [ ] Formatage dates (UTC → local)
- [ ] Colorisation profits (vert/rouge)
- [ ] Pull-to-refresh
- [ ] Gestion erreurs réseau
- [ ] Mode hors ligne (cache)
- [ ] Actualisation automatique
- [ ] Loading states
- [ ] Navigation entre écrans

---

## 🎯 Endpoints Résumés

| Endpoint | Méthode | Auth | Description |
|----------|---------|------|-------------|
| `/register` | POST | ❌ | Inscription |
| `/login` | POST | ❌ | Connexion |
| `/users/me` | GET | ✅ | Utilisateur connecté |
| `/users` | GET | ❌ | Liste utilisateurs |
| `/users/:id` | DELETE | ✅ | Supprimer compte |
| `/accounts/balance` | GET | ✅ | Balance comptes |
| `/accounts/trades` | GET | ✅ | 20 derniers trades |
| `/accounts/projection` | GET | ✅ | Projections financières |
| `/bots` | GET | ✅ | Liste bots utilisateur |
| `/bots/:id/status` | GET | ✅ | Statut bot |
| `/bots/:id/performance` | POST | ✅ | Mettre à jour performances |

**Auth** : ✅ = JWT requis, ❌ = Pas d'authentification

---

## 💡 Astuces Développement

1. **Intercepteur HTTP** : Ajouter token automatiquement à toutes requêtes
2. **Gestionnaire d'erreurs global** : Centraliser gestion erreurs 401/500
3. **Cache intelligent** : Stocker données avec timestamp, utiliser si < 60s
4. **Optimistic updates** : Mettre à jour UI immédiatement, puis sync serveur
5. **Pagination** : Prévoir pour trades si > 20 (actuellement limité API)

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-XX

