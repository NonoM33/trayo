# Quick Start - Démarrage Rapide

## Installation en 5 minutes ⚡

### 1. Installer les dépendances

```bash
bundle install
```

### 2. Configurer et créer la base de données

```bash
bin/rails db:create db:migrate db:seed
```

### 3. Démarrer le serveur

```bash
bin/rails server
```

✅ Le serveur tourne maintenant sur `http://localhost:3000`

---

## Test Rapide 🚀

### Créer un utilisateur et récupérer le token

```bash
curl -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

**Sauvegarder le token reçu !**

### Synchroniser des données MT5 (en tant que script)

```bash
curl -X POST http://localhost:3000/api/v1/mt5/sync \
  -H "Content-Type: application/json" \
  -H "X-API-Key: mt5_secret_key_change_in_production" \
  -d '{
    "mt5_data": {
      "mt5_id": "123456789",
      "user_id": 1,
      "account_name": "Demo Account",
      "balance": 10000.00,
      "trades": [
        {
          "trade_id": "T001",
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
  }'
```

### Récupérer le solde (en tant que client)

```bash
curl http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer VOTRE_TOKEN_ICI"
```

### Récupérer les trades

```bash
curl http://localhost:3000/api/v1/accounts/trades \
  -H "Authorization: Bearer VOTRE_TOKEN_ICI"
```

### Récupérer la projection

```bash
curl "http://localhost:3000/api/v1/accounts/projection?days=30" \
  -H "Authorization: Bearer VOTRE_TOKEN_ICI"
```

---

## Utiliser l'utilisateur de seed 👤

Un utilisateur de test est créé automatiquement avec `db:seed` :

- **Email :** `demo@example.com`
- **Password :** `password123`
- **User ID :** `1`

### Se connecter avec l'utilisateur seed

```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@example.com",
    "password": "password123"
  }'
```

---

## Configuration Script MT5 Python 🐍

### 1. Créer le fichier de script

Copier `mt5_script_example.py` et modifier :

```python
USER_ID = 1  # ID de votre utilisateur
MT5_ACCOUNT_ID = "123456789"  # Votre ID compte MT5
API_KEY = "mt5_secret_key_change_in_production"
```

### 2. Installer les dépendances

```bash
pip install requests MetaTrader5
```

### 3. Lancer le script

```bash
python mt5_script_example.py
```

---

## Commandes Utiles 🛠️

### Rails Console

```bash
bin/rails console
```

Exemples dans la console :

```ruby
# Lister les utilisateurs
User.all

# Lister les comptes MT5
Mt5Account.all

# Voir les trades récents
Trade.order(close_time: :desc).limit(10)

# Voir le solde total
Mt5Account.sum(:balance)
```

### Réinitialiser la base

```bash
bin/rails db:reset
```

### Voir l'état des migrations

```bash
bin/rails db:migrate:status
```

---

## Structure des Routes 🗺️

| Méthode | Route                         | Description | Auth    |
| ------- | ----------------------------- | ----------- | ------- |
| POST    | `/api/v1/register`            | Inscription | Public  |
| POST    | `/api/v1/login`               | Connexion   | Public  |
| POST    | `/api/v1/mt5/sync`            | Sync MT5    | API Key |
| GET     | `/api/v1/accounts/balance`    | Solde       | JWT     |
| GET     | `/api/v1/accounts/trades`     | Trades      | JWT     |
| GET     | `/api/v1/accounts/projection` | Projection  | JWT     |

---

## Résolution Rapide de Problèmes 🔧

### Le serveur ne démarre pas

```bash
# Vérifier que PostgreSQL tourne
brew services list  # macOS
sudo systemctl status postgresql  # Linux

# Vérifier la config de la base
cat config/database.yml
```

### Erreur "Unauthorized"

- Vérifiez que vous utilisez le bon token JWT
- Le token commence par "Bearer " dans le header Authorization
- Le token expire après 24h (reconnectez-vous)

### Erreur "Invalid API key" pour MT5

- Vérifiez le header `X-API-Key`
- Par défaut : `mt5_secret_key_change_in_production`

### Port 3000 déjà utilisé

```bash
bin/rails server -p 3001
```

---

## Documentation Complète 📚

Pour plus de détails, consultez :

- **README.md** - Vue d'ensemble complète
- **API_DOCUMENTATION.md** - Doc API détaillée
- **API_EXAMPLES.md** - Exemples cURL complets
- **SETUP_GUIDE.md** - Guide d'installation détaillé
- **DATABASE_SCHEMA.md** - Structure de la BD
- **PROJET_RESUME.md** - Résumé du projet

---

## Checklist Avant Production ✅

Avant de déployer en production :

- [ ] Changer `MT5_API_KEY` dans les variables d'environnement
- [ ] Générer un nouveau `SECRET_KEY_BASE` avec `bin/rails secret`
- [ ] Configurer CORS pour n'autoriser que votre frontend
- [ ] Activer SSL/HTTPS
- [ ] Configurer les backups de base de données
- [ ] Mettre en place un monitoring

---

**Prêt à coder !** 🚀

Pour toute question, référez-vous aux fichiers de documentation dans le projet.
