# Guide du Back Office Trayo

## 📋 Fonctionnalités Implémentées

### 1. Gestion des Utilisateurs

- **Création de clients et administrateurs** depuis le back office
- **Liste des clients** avec leurs métriques en temps réel
- **Liste des administrateurs** séparée
- Visualisation des gains totaux par client
- Configuration du taux de commission par client
- Calcul automatique des commissions dues
- Suppression d'utilisateurs (sauf soi-même)

### 2. Système de Watermark (High Watermark)

- **Par compte MT5** : Chaque compte MT5 a son propre watermark
- **Permanent et cumulatif** : Le watermark ne diminue jamais sauf en cas de retrait
- **Ajustement automatique** : Le watermark s'ajuste automatiquement lors des retraits
- **Commission uniquement sur nouveaux gains** : Seuls les gains au-delà du watermark sont commissionnés

**Formule de calcul :**

```
Watermark Ajusté = High Watermark - Total des Retraits
Gains Commissionnables = Gains Totaux - Watermark Ajusté
Commission Due = Gains Commissionnables × Taux de Commission
```

### 3. Gestion des Règlements

- Création de règlements manuels
- Statuts : Pending / Validated / Rejected
- Validation/Rejet des règlements en un clic
- Historique complet des règlements
- Seuls les règlements validés sont déduits du solde dû

### 4. Gestion des Avoirs

- Création d'avoirs pour créditer un client
- Les avoirs sont déduits du solde dû
- Suppression possible des avoirs
- Motif obligatoire pour traçabilité

### 5. Détection Automatique des Retraits

- L'API MT5 détecte automatiquement les retraits
- Comparaison de la balance entre deux syncs
- Si baisse de balance > pertes récentes : création d'un retrait
- Le watermark est automatiquement ajusté (diminué) du montant du retrait

### 6. Calcul du Solde Dû

```
Solde Dû = Commission Due - Règlements Validés - Avoirs
```

## 🗄️ Structure de la Base de Données

### Nouvelles Tables

- **payments** : Règlements clients (montant, date, statut, référence, notes)
- **credits** : Avoirs clients (montant, motif)
- **withdrawals** : Retraits MT5 (montant, date)

### Champs Ajoutés

- **users** : `commission_rate` (%), `is_admin` (boolean)
- **mt5_accounts** : `high_watermark`, `total_withdrawals`

## 🚀 Installation

### 1. Exécuter les Migrations

```bash
cd /Users/renaud.cosson-ext/trayo
bin/rails db:migrate
```

### 2. Créer les Données de Test

```bash
bin/rails db:seed
```

Ceci créera :

- Un admin : `admin@trayo.com` / `admin123`
- Un client de test avec un compte MT5

### 3. Démarrer le Serveur

```bash
bin/rails server
```

## 🔐 Accès au Back Office

### URL

```
http://localhost:3000/admin/login
```

### Credentials Admin

- **Email** : admin@trayo.com
- **Password** : admin123

## 📖 Utilisation

### Créer un Nouveau Client ou Admin

1. Sur le dashboard, cliquer sur **"➕ New User"**
2. Remplir le formulaire :
   - **Email** (obligatoire, unique)
   - **Password** (obligatoire, minimum 6 caractères)
   - **Confirm Password** (obligatoire)
   - **First Name** (optionnel)
   - **Last Name** (optionnel)
   - **Commission Rate** (0-100%, 0 par défaut pour admins)
   - **Role** : Choisir entre Client ou Administrator
3. Cliquer sur **"Create User"**

**Rôles disponibles :**

- **Client** : Utilisateur avec suivi de commissions, accès API, sync MT5
- **Administrator** : Accès complet au back office, gestion des clients

### Dashboard Clients

1. Connectez-vous avec les credentials admin
2. Vous arrivez sur la liste des clients et administrateurs
3. **Section Clients** - Colonnes affichées :
   - Nom/Email du client
   - Taux de commission
   - Gains totaux
   - Commission due
   - Solde dû (en rouge si positif, en vert si négatif)
   - Actions (View / Delete)
4. **Section Administrators** - Liste des admins avec possibilité de suppression

### Page Détail Client

#### Token MT5 API

En haut de la page, le **MT5 API Token** du client est affiché dans un encadré bleu :

- Token complet en police monospace (facile à copier)
- Ce token doit être configuré dans le script MT5 `TrayoSync.mq5`
- Le token est généré automatiquement à la création du client
- Il est unique par client et permet d'associer les comptes MT5 au bon utilisateur

**Comment utiliser le token :**

1. Copier le token depuis le back office
2. Ouvrir le script `TrayoSync.mq5` dans MetaEditor
3. Remplacer la valeur de `MT5_API_TOKEN` par le token copié
4. Compiler et attacher le script au compte MT5 du client

#### Informations Générales

- Taux de commission (modifiable)
- Gains totaux
- Gains commissionnables (après watermark)
- Commission due
- Règlements validés
- Avoirs totaux
- **Solde dû** (calcul en temps réel)

#### Comptes MT5

Table avec tous les comptes MT5 du client :

- Balance actuelle
- Profits totaux
- High Watermark
- Total des retraits
- Watermark ajusté
- Gains commissionnables
- **Bouton "Edit WM"** pour modifier manuellement le watermark

**Modifier le Watermark Manuellement :**

1. Cliquer sur "Edit WM" dans la colonne Actions
2. Un formulaire apparaît sous la ligne du compte
3. Saisir la nouvelle valeur du High Watermark
4. Voir le watermark actuel et ajusté en dessous du champ
5. Cliquer sur "Update" pour sauvegarder ou "Cancel" pour annuler
6. Les gains commissionnables sont recalculés automatiquement

**Cas d'usage :**

- Corriger une erreur de calcul
- Arrangement spécial avec un client
- Réinitialisation suite à un incident
- Ajustement suite à un changement de conditions

#### Ajouter un Règlement

1. Saisir le montant
2. Sélectionner la date
3. Ajouter une référence (optionnel)
4. Ajouter des notes (optionnel)
5. Cliquer sur "Create Payment"
6. Le règlement est créé avec le statut "Pending"

#### Valider/Rejeter un Règlement

1. Dans l'historique des règlements
2. Cliquer sur "Validate" pour valider
3. Ou "Reject" pour rejeter
4. Seuls les règlements validés impactent le solde dû

#### Créer un Avoir

1. Saisir le montant
2. Indiquer le motif
3. Cliquer sur "Create Credit"
4. L'avoir est immédiatement déduit du solde dû

#### Supprimer un Avoir

1. Dans l'historique des avoirs
2. Cliquer sur "Delete"
3. Confirmer la suppression

### Modifier le Taux de Commission

1. Sur la page détail client
2. Modifier le champ "Commission Rate (%)"
3. Cliquer sur "Update Rate"
4. Le nouveau taux s'applique immédiatement

## 🔄 Détection des Retraits MT5

### Fonctionnement

Lors de chaque sync MT5 (`POST /api/v1/mt5/sync`) :

1. L'API compare l'ancienne balance avec la nouvelle
2. Si la balance a diminué :
   - Calcul de la diminution
   - Vérification des pertes de trading récentes (1h)
   - Si diminution > pertes + marge (10$) → C'est un retrait
3. Création automatique d'un `Withdrawal`
4. Le watermark est ajusté automatiquement

### Impact sur les Commissions

- Retrait de 1000$ → Watermark diminue de 1000$
- Les gains commissionnables augmentent de 1000$
- La commission due augmente proportionnellement

## 📊 Exemples de Calcul

### Exemple 1 : Client sans retrait

```
Gains totaux : 5000$
High Watermark : 3000$
Total retraits : 0$

Watermark ajusté = 3000$ - 0$ = 3000$
Gains commissionnables = 5000$ - 3000$ = 2000$
Commission (20%) = 2000$ × 20% = 400$
Règlements validés = 0$
Avoirs = 0$

Solde dû = 400$ - 0$ - 0$ = 400$
```

### Exemple 2 : Client avec retrait

```
Gains totaux : 5000$
High Watermark : 3000$
Total retraits : 1000$

Watermark ajusté = 3000$ - 1000$ = 2000$
Gains commissionnables = 5000$ - 2000$ = 3000$
Commission (20%) = 3000$ × 20% = 600$
Règlements validés = 200$
Avoirs = 50$

Solde dû = 600$ - 200$ - 50$ = 350$
```

### Exemple 3 : Client avec avoir

```
Gains totaux : 2000$
High Watermark : 1000$
Total retraits : 0$

Watermark ajusté = 1000$
Gains commissionnables = 2000$ - 1000$ = 1000$
Commission (20%) = 1000$ × 20% = 200$
Règlements validés = 150$
Avoirs = 100$ (geste commercial)

Solde dû = 200$ - 150$ - 100$ = -50$
```

Le client a un crédit de 50$ (solde négatif).

## 🎨 Interface

### Design

- Interface simple et épurée
- CSS intégré (pas de dépendances)
- Responsive (fonctionne sur mobile/tablette)
- Couleurs :
  - Vert (#4CAF50) : Gains, actions positives
  - Rouge (#f44336) : Solde dû, suppressions
  - Bleu (#2196F3) : Actions secondaires (validation)

### Navigation

- Barre de navigation persistante
- Email admin affiché
- Bouton Logout
- Lien retour sur les pages de détail

## 🔒 Sécurité

- Authentification requise pour accéder au back office
- Vérification du flag `is_admin` sur chaque requête
- Protection contre auto-suppression (un admin ne peut pas se supprimer lui-même)
- Session Rails standard
- Routes admin isolées dans un namespace

## 👥 Gestion des Rôles

Le système utilise un système simple avec un flag booléen `is_admin` :

- **`is_admin: false`** → Client (utilisateur normal avec commissions)
- **`is_admin: true`** → Administrator (accès back office)

**Permissions par rôle :**

| Fonctionnalité         | Client | Admin |
| ---------------------- | ------ | ----- |
| Accès API              | ✅     | ✅    |
| Sync MT5               | ✅     | ❌    |
| Suivi commissions      | ✅     | ❌    |
| Accès back office      | ❌     | ✅    |
| Créer utilisateurs     | ❌     | ✅    |
| Gérer règlements       | ❌     | ✅    |
| Gérer avoirs           | ❌     | ✅    |
| Supprimer utilisateurs | ❌     | ✅    |

## 📝 Routes Admin

```ruby
GET    /admin/login              # Page de connexion
POST   /admin/login              # Connexion
DELETE /admin/logout             # Déconnexion
GET    /admin/clients              # Liste des clients et admins
GET    /admin/clients/new          # Formulaire création utilisateur
POST   /admin/clients              # Créer utilisateur (client ou admin)
GET    /admin/clients/:id          # Détail client
PATCH  /admin/clients/:id          # Modifier taux commission
DELETE /admin/clients/:id          # Supprimer utilisateur
POST   /admin/payments             # Créer règlement
PATCH  /admin/payments/:id         # Valider/Rejeter règlement
POST   /admin/credits              # Créer avoir
DELETE /admin/credits/:id          # Supprimer avoir
PATCH  /admin/mt5_accounts/:id     # Modifier watermark d'un compte MT5
```

## 🧪 Tests

### Créer un Client via API

```bash
curl -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "client2@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "first_name": "Jane",
      "last_name": "Smith"
    }
  }'
```

### Assigner un Taux de Commission

1. Se connecter au back office
2. Aller sur le client
3. Modifier le taux (ex: 25%)
4. Sauvegarder

### Simuler un Sync MT5 avec Trades

```bash
curl -X POST http://localhost:3000/api/v1/mt5/sync \
  -H "Content-Type: application/json" \
  -H "X-API-Key: mt5_secret_key_change_in_production" \
  -d '{
    "mt5_data": {
      "mt5_id": "12345678",
      "mt5_api_token": "TOKEN_DU_CLIENT",
      "account_name": "Demo Account",
      "balance": 15000,
      "trades": [
        {
          "trade_id": "T001",
          "symbol": "EURUSD",
          "trade_type": "BUY",
          "volume": 1.0,
          "open_price": 1.1000,
          "close_price": 1.1050,
          "profit": 500,
          "commission": -5,
          "swap": 0,
          "open_time": "2025-10-20T10:00:00Z",
          "close_time": "2025-10-20T15:00:00Z",
          "status": "closed"
        }
      ]
    }
  }'
```

Le watermark sera mis à jour automatiquement si les profits dépassent l'ancien watermark.

### Simuler un Retrait

```bash
# Sync avec balance diminuée
curl -X POST http://localhost:3000/api/v1/mt5/sync \
  -H "Content-Type: application/json" \
  -H "X-API-Key: mt5_secret_key_change_in_production" \
  -d '{
    "mt5_data": {
      "mt5_id": "12345678",
      "mt5_api_token": "TOKEN_DU_CLIENT",
      "account_name": "Demo Account",
      "balance": 12000,
      "trades": []
    }
  }'
```

Si la balance passe de 15000 à 12000 sans trades perdants, un retrait de 3000$ sera créé automatiquement.

## 🆘 Dépannage

### Les migrations ne passent pas

Vérifiez que vous utilisez la bonne version de Ruby (3.x minimum pour Rails 8).

```bash
ruby -v
```

### Erreur "Invalid credentials or not an admin"

Vérifiez que l'utilisateur a bien `is_admin: true` en base.

### Les retraits ne sont pas détectés

- Vérifiez que la balance diminue effectivement
- Vérifiez qu'il n'y a pas de trades perdants récents équivalents
- Regardez les logs Rails pour plus de détails

### Les calculs de commission semblent incorrects

- Vérifiez le watermark du compte MT5
- Vérifiez le total des retraits
- Formule : `(total_profits - (high_watermark - total_withdrawals)) × commission_rate`

## 📞 Support

Pour toute question ou problème, consulter :

- `DATABASE_SCHEMA.md` : Schéma de base de données
- `API_DOCUMENTATION.md` : Documentation API
- Logs Rails : `log/development.log`
