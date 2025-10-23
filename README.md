# Trayo - Backend API MT5

Backend Rails pour la gestion et synchronisation des données MetaTrader 5 (MT5).

## Description

Cette API backend permet de :

- Récupérer et stocker les données de comptes MT5 (solde, trades)
- Authentifier des utilisateurs (inscription/connexion)
- Fournir des projections financières sur 30 jours basées sur l'historique de trading
- Éviter les doublons lors de la synchronisation des données

## Prérequis

- Ruby 3.3+
- PostgreSQL 14+
- Bundler 2.6+

## Installation

1. Cloner le repository

```bash
git clone <repository-url>
cd trayo
```

2. Installer les dépendances

```bash
bundle install
```

3. Configurer la base de données

```bash
cp config/database.yml.example config/database.yml
# Modifier les credentials si nécessaire
```

4. Créer et initialiser la base de données

```bash
bin/rails db:create
bin/rails db:migrate
```

5. Configurer les variables d'environnement

```bash
# Créer un fichier .env à la racine
MT5_API_KEY=votre_cle_api_mt5
SECRET_KEY_BASE=votre_secret_key_base
```

## Démarrage

```bash
bin/rails server
```

Le serveur démarre sur `http://localhost:3000`

## Architecture

### Modèles

- **User** : Utilisateurs de l'application
- **Mt5Account** : Comptes MetaTrader 5 liés aux utilisateurs
- **Trade** : Trades effectués sur les comptes MT5

### Routes API

#### Authentification

- `POST /api/v1/register` - Inscription d'un nouvel utilisateur
- `POST /api/v1/login` - Connexion utilisateur

#### Synchronisation MT5 (pour le script)

- `POST /api/v1/mt5/sync` - Synchronisation des données MT5 (requiert API Key)

#### Endpoints Client (requiert JWT)

- `GET /api/v1/accounts/balance` - Récupération du solde
- `GET /api/v1/accounts/trades` - Récupération des 20 derniers trades
- `GET /api/v1/accounts/projection?days=30` - Projection sur X jours

Voir [API_DOCUMENTATION.md](API_DOCUMENTATION.md) pour les détails complets.

## Script MT5

Un exemple de script Python pour synchroniser les données MT5 est disponible dans `mt5_script_example.py`.

### Configuration du script

1. Installer les dépendances Python

```bash
pip install requests MetaTrader5
```

2. Modifier les variables dans le script :

```python
API_URL = "http://localhost:3000/api/v1/mt5/sync"
API_KEY = "votre_cle_api"
USER_ID = 1  # ID de l'utilisateur créé via /register
MT5_ACCOUNT_ID = "votre_id_compte_mt5"
REFRESH_INTERVAL = 300  # 5 minutes
```

3. Lancer le script

```bash
python mt5_script_example.py
```

## Fonctionnalités

### Synchronisation automatique

Le script MT5 peut tourner en continu et envoyer les données à intervalles réguliers. L'API :

- Crée automatiquement le compte MT5 s'il n'existe pas
- Met à jour le solde à chaque synchronisation
- Évite les doublons de trades grâce à l'index unique sur `trade_id`
- Stocke uniquement les trades des dernières 24h (configurable)

### Projection financière

L'algorithme de projection :

- Analyse les 30 derniers jours de trading
- Calcule la moyenne de profit journalière
- Projette sur le nombre de jours demandé
- Fournit un niveau de confiance basé sur le nombre de jours de trading

Niveaux de confiance :

- **high** : 20+ jours de trading dans les 30 derniers jours
- **medium** : 10-19 jours de trading
- **low** : moins de 10 jours de trading

### Sécurité

- Authentification JWT pour les endpoints client
- API Key pour la synchronisation MT5
- Mots de passe hashés avec bcrypt
- Validation des données en entrée
- Protection CSRF désactivée pour l'API
- CORS configuré

## Tests

```bash
bin/rails test
```

## Déploiement

Le projet est configuré pour le déploiement avec Kamal :

```bash
kamal setup
kamal deploy
```

## Structure du projet

```
app/
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       ├── authentication_controller.rb
│   │       ├── mt5_data_controller.rb
│   │       └── accounts_controller.rb
│   └── concerns/
│       ├── json_web_token.rb
│       └── authenticable.rb
├── models/
│   ├── user.rb
│   ├── mt5_account.rb
│   └── trade.rb
config/
├── routes.rb
└── initializers/
    └── cors.rb
db/
└── migrate/
    ├── 20251023000001_create_users.rb
    ├── 20251023000002_create_mt5_accounts.rb
    └── 20251023000003_create_trades.rb
```

## Licence

Copyright © 2025
