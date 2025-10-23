# Guide de Configuration

## Configuration initiale

### 1. Installer les dépendances

```bash
bundle install
```

Si vous avez des problèmes avec bundler, installez d'abord la bonne version :

```bash
gem install bundler -v '~> 2.6'
```

### 2. Configurer PostgreSQL

Assurez-vous que PostgreSQL est installé et en cours d'exécution :

```bash
# macOS avec Homebrew
brew install postgresql@14
brew services start postgresql@14

# Linux (Ubuntu/Debian)
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 3. Créer la base de données

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 4. Variables d'environnement

Créez un fichier `.env` à la racine :

```bash
MT5_API_KEY=votre_cle_secrete_mt5
SECRET_KEY_BASE=votre_secret_key_base
```

Pour générer une SECRET_KEY_BASE :

```bash
bin/rails secret
```

### 5. Démarrer le serveur

```bash
bin/rails server
```

Le serveur sera accessible sur `http://localhost:3000`

## Configuration du Script MT5

### 1. Créer un utilisateur

Utilisez le endpoint `/api/v1/register` ou utilisez l'utilisateur de seed :

- Email: `demo@example.com`
- Password: `password123`

### 2. Récupérer l'ID utilisateur

Notez l'ID de l'utilisateur retourné lors de l'inscription (ou `1` si vous utilisez le seed).

### 3. Configurer le script Python

Dans `mt5_script_example.py`, modifiez :

```python
API_URL = "http://localhost:3000/api/v1/mt5/sync"
API_KEY = "votre_cle_secrete_mt5"  # Même valeur que MT5_API_KEY
USER_ID = 1  # ID de votre utilisateur
MT5_ACCOUNT_ID = "votre_id_compte_mt5"
```

### 4. Installer les dépendances Python

```bash
pip install requests MetaTrader5
```

### 5. Lancer le script

```bash
python mt5_script_example.py
```

## Tester l'API

### Utiliser les exemples cURL

Voir le fichier `API_EXAMPLES.md` pour des exemples complets de requêtes.

### Test rapide

1. Créer un utilisateur :

```bash
curl -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123","password_confirmation":"password123"}}'
```

2. Sauvegarder le token reçu

3. Tester l'accès au solde :

```bash
curl http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

## Résolution de problèmes

### Erreur de connexion à PostgreSQL

Vérifiez votre `config/database.yml` et assurez-vous que les credentials sont corrects.

### Erreur JWT

Assurez-vous que `SECRET_KEY_BASE` est défini et que vous utilisez le bon token.

### Erreur MT5 API Key

Vérifiez que `X-API-Key` dans les headers correspond à `MT5_API_KEY`.

### Port déjà utilisé

Si le port 3000 est occupé :

```bash
bin/rails server -p 3001
```

## Environnements

### Development (par défaut)

```bash
bin/rails server
```

### Production

```bash
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails server
```

## Base de données

### Réinitialiser la base

```bash
bin/rails db:reset
```

### Vérifier l'état des migrations

```bash
bin/rails db:migrate:status
```

### Console Rails

```bash
bin/rails console
```

Exemples dans la console :

```ruby
# Créer un utilisateur
User.create!(email: "test@example.com", password: "password123")

# Lister tous les comptes MT5
Mt5Account.all

# Voir les trades récents
Trade.order(close_time: :desc).limit(10)
```

## Déploiement

Le projet est configuré pour Kamal. Voir la documentation de Kamal pour plus de détails.

```bash
kamal setup
kamal deploy
```

## Support

Pour plus d'informations :

- Voir `README.md` pour une vue d'ensemble
- Voir `API_DOCUMENTATION.md` pour la documentation API complète
- Voir `API_EXAMPLES.md` pour des exemples pratiques
