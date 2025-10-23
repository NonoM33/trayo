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
Net Gains = Balance Actuelle - Capital Initial
Watermark Ajusté = High Watermark - Total des Retraits
Gains Commissionnables = Balance Actuelle - Watermark Ajusté (si positif)
Commission Due = Gains Commissionnables × Taux de Commission
```

**Note importante :** Le High Watermark représente le plus haut niveau de **balance** atteint.

- Pour un nouveau compte, le watermark = capital initial
- Quand la balance monte, le watermark monte automatiquement lors du sync MT5
- **Quand un paiement est validé**, le watermark est mis à jour à la balance actuelle
- Quand un retrait est effectué, le watermark ajusté diminue
- On ne paie des commissions que sur les gains au-delà du watermark
- Une fois un paiement validé, les gains commissionnables = 0 jusqu'aux prochains gains

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

**Formule correcte :**

```
Solde Dû = Commission Due - Avoirs
```

**Important :** Les règlements validés ne sont PAS soustraits du solde dû car le **watermark gère déjà cela**.

**Explication :**

- Le watermark représente le niveau de balance jusqu'auquel on a déjà payé des commissions
- Quand on valide un paiement, on met à jour le watermark = balance actuelle
- Les gains commissionnables deviennent 0 (car balance = watermark)
- Donc la commission due = 0
- Les paiements validés sont juste un **historique** de ce qui a été payé
- Seuls les **avoirs (credits)** sont soustraits car ce sont des réductions futures

## 🗄️ Structure de la Base de Données

### Nouvelles Tables

- **payments** : Règlements clients (montant, date, statut, référence, notes, payment_method)
- **credits** : Avoirs clients (montant, motif)
- **withdrawals** : Retraits MT5 (montant, date)

### Champs Ajoutés

- **users** : `commission_rate` (%), `is_admin` (boolean)
- **mt5_accounts** : `high_watermark`, `total_withdrawals`, `initial_balance`

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

- **Initial Balance** : Capital de départ (modifiable)
- **Current Balance** : Balance actuelle synchro MT5
- **Net Gains** : Gains nets = Balance actuelle - Capital initial (vert si positif, rouge si négatif)
- **High Watermark** : Plus haut niveau de gains historique
- **Withdrawals** : Total des retraits effectués
- **Adjusted WM** : Watermark ajusté = High WM - Retraits
- **Commissionable** : Gains commissionnables = Net Gains - Adjusted WM
- **Bouton "Edit"** pour modifier capital initial et watermark

**Modifier les Paramètres du Compte :**

1. Cliquer sur "Edit" dans la colonne Actions
2. Un formulaire apparaît sous la ligne du compte avec 2 champs :
   - **Initial Balance** : Le capital de départ du compte
   - **High Watermark** : Le niveau de gains historique maximum
3. Un encadré bleu affiche les calculs en temps réel
4. Cliquer sur "Update" pour sauvegarder ou "Cancel" pour annuler
5. Tous les calculs sont recalculés automatiquement

**Cas d'usage Capital Initial :**

- Définir le montant de départ pour un nouveau compte
- Corriger le capital initial mal défini
- Ajuster après un dépôt initial manqué

**Cas d'usage Watermark :**

- Corriger une erreur de calcul
- Arrangement spécial avec un client
- Réinitialisation suite à un incident
- Ajustement suite à un changement de conditions

#### Ajouter un Règlement

Le formulaire affiche automatiquement :

- **Encadré jaune** : Solde dû actuel avec détail (commission, payé, avoirs)
- **Encadré bleu** : Liste des watermarks de tous les comptes MT5 (pour référence)

**Étapes :**

1. Le montant est **pré-rempli** avec le solde dû actuel (modifiable)
2. Sélectionner le **mode de règlement** : Bank Transfer, Cash, PayPal, Credit Card, Check, Other
3. La date est pré-remplie avec aujourd'hui (modifiable)
4. Ajouter une référence/numéro de transaction (optionnel)
5. Ajouter des notes (optionnel)
6. Cliquer sur "Create Payment"
7. Le règlement est créé avec le statut "Pending"

**Modes de règlement disponibles :**

- Bank Transfer (virement bancaire)
- Cash (espèces)
- PayPal
- Credit Card (carte bancaire)
- Check (chèque)
- Other (autre)

#### Valider/Rejeter un Règlement

1. Dans l'historique des règlements
2. Cliquer sur "Validate" pour valider
3. Ou "Reject" pour rejeter
4. Seuls les règlements validés impactent le solde dû

**Que se passe-t-il lors de la validation ?**

1. Un **snapshot des watermarks** est enregistré pour traçabilité
2. Les **watermarks de tous les comptes MT5** sont mis à jour à leur balance actuelle
3. Le règlement est marqué "Validated"
4. Les gains commissionnables retombent à 0 (car le watermark = balance actuelle)
5. Le client devra générer de nouveaux gains pour des commissions futures

**Colonne "Watermarks at Validation"** dans l'historique :

- Affiche pour chaque compte MT5 au moment de la validation :
  - Nom du compte et MT5 ID
  - Watermark avant → Watermark après (nouvelle balance)
  - Gains commissionnables qui ont été payés

Ceci permet de **tracer exactement** sur quels gains le paiement a été effectué.

#### Supprimer un Règlement (Mode Protégé)

Pour éviter les suppressions accidentelles, la suppression nécessite d'activer un mode spécial :

1. Cliquer sur le bouton **"🔒 Unlock Delete Mode"** en haut à droite de l'historique
2. Le bouton devient **"🔓 Lock Delete Mode"** (rouge)
3. Un **warning jaune** apparaît : "⚠️ Delete Mode Active"
4. Les boutons **"Delete"** (rouges) apparaissent sur chaque ligne
5. Cliquer sur "Delete" puis confirmer la suppression
6. Pour quitter le mode, re-cliquer sur le cadenas

**Attention :** La suppression est définitive et ne peut pas être annulée !

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

### Exemple 1 : Nouveau compte avec gains

```
Capital initial : 1700$
Balance actuelle : 1837.62$
Net Gains : 1837.62$ - 1700$ = 137.62$
High Watermark : 1700$ (niveau initial)
Total retraits : 0$

Watermark ajusté = 1700$ - 0$ = 1700$
Gains commissionnables = 1837.62$ - 1700$ = 137.62$
Commission (25%) = 137.62$ × 25% = 34.41$
Avoirs = 0$

Solde dû = 34.41$ - 0$ = 34.41$

---

Après validation du paiement de 34.41$ :
High Watermark mis à jour : 1837.62$
Gains commissionnables = 1837.62$ - 1837.62$ = 0$
Commission due = 0$ × 25% = 0$
Solde dû = 0$ - 0$ = 0$ ✓

Historique paiements : 34.41$ (pour traçabilité)
```

### Exemple 2 : Compte avec gains importants

```
Capital initial : 10000$
Balance actuelle : 15000$
Net Gains : 15000$ - 10000$ = 5000$
High Watermark : 13000$ (plus haut atteint précédemment)
Total retraits : 0$

Watermark ajusté = 13000$ - 0$ = 13000$
Gains commissionnables = 15000$ - 13000$ = 2000$
Commission (20%) = 2000$ × 20% = 400$
Règlements validés = 0$
Avoirs = 0$

Solde dû = 400$ - 0$ - 0$ = 400$
```

### Exemple 3 : Client avec retrait

```
Capital initial : 10000$
Balance actuelle : 14000$ (après retrait de 1000$)
Net Gains : 14000$ - 10000$ = 4000$
High Watermark : 15000$ (avant retrait)
Total retraits : 1000$

Watermark ajusté = 15000$ - 1000$ = 14000$
Gains commissionnables = 14000$ - 14000$ = 0$
Commission (20%) = 0$ × 20% = 0$

Solde dû = 0$
```

**Note :** Après le retrait, le watermark ajusté = balance actuelle, donc pas de nouveaux gains commissionnables. Le client devra dépasser 14000$ pour générer de nouvelles commissions.

## 🎨 Interface

### Design

- Interface moderne et épurée
- **Dark Mode** disponible (toggle lune/soleil dans la navbar)
- CSS intégré (pas de dépendances)
- Responsive (fonctionne sur mobile/tablette)
- Couleurs :
  - Bleu (#0d6efd) : Actions primaires
  - Vert (#198754) : Gains, succès
  - Rouge (#dc3545) : Solde dû, suppressions
- Préférence de thème sauvegardée dans le navigateur

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
