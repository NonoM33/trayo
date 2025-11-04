# Cahier des Charges - Application Mobile Trayo

## 1. Vue d'Ensemble

### 1.1 Description du Projet
Application mobile native permettant aux utilisateurs de :
- Gérer leurs comptes MT5 de trading
- Suivre leurs bots de trading automatisés
- Consulter leurs performances et projections de gains
- Gérer leurs abonnements VPS
- Suivre leurs paiements et commissions
- Visualiser leurs trades en temps réel

### 1.2 Architecture Technique
- **Backend** : API Rails REST (déjà existante)
- **Frontend Mobile** : Application native (iOS/Android) ou cross-platform (React Native/Flutter)
- **Communication** : REST API avec authentification JWT
- **Synchronisation** : Données synchronisées depuis MT5 via le backend

---

## 2. Modèles de Données et Relations

### 2.1 Entités Principales

#### User (Utilisateur)
- id, email, first_name, last_name
- mt5_api_token (unique)
- commission_rate (0-100%)
- init_mt5 (boolean)
- is_admin (boolean)

#### Mt5Account (Compte MT5)
- id, user_id
- mt5_id (unique), account_name
- balance, equity
- initial_balance, calculated_initial_balance
- high_watermark (point haut historique)
- total_withdrawals, total_deposits
- last_sync_at, last_heartbeat_at
- broker_name, broker_server

#### Trade (Trade)
- id, mt5_account_id
- trade_id (unique par compte)
- symbol (paire de devises)
- trade_type (buy/sell)
- volume, open_price, close_price
- profit, commission, swap
- open_time, close_time
- status (open/closed)
- magic_number (identifiant bot)
- trade_originality (bot/manual_admin/manual_client)
- is_unauthorized_manual (boolean)

#### TradingBot (Bot de Trading)
- id, name, description
- price (prix d'achat)
- status (active/inactive)
- risk_level (low/medium/high)
- magic_number_prefix
- max_drawdown_limit (%)
- projection_monthly_min, projection_monthly_max
- projection_yearly
- features (JSON)

#### BotPurchase (Achat de Bot)
- id, user_id, trading_bot_id
- price_paid
- status (active/inactive)
- is_running (boolean)
- magic_number
- total_profit, trades_count
- current_drawdown, max_drawdown_recorded
- started_at, stopped_at

#### Vps (Serveur VPS)
- id, user_id
- name, server_location
- status (ordered/configuring/ready/active/suspended/cancelled)
- monthly_price
- renewal_date
- ordered_at, configured_at, ready_at, activated_at
- ip_address, username, password (non visible client)

#### Payment (Paiement)
- id, user_id
- amount, status (pending/validated/rejected)
- payment_date
- description

#### Credit (Crédit)
- id, user_id
- amount, reason, created_at

#### Deposit (Dépôt)
- id, mt5_account_id
- amount, deposit_date, transaction_id

#### Withdrawal (Retrait)
- id, mt5_account_id
- amount, withdrawal_date, transaction_id

#### Invitation (Invitation)
- id, code (unique)
- step (1-4)
- expires_at
- completed (boolean)

---

## 3. Écrans et Fonctionnalités

### 3.1 Authentification

#### Écran : Connexion
**URL API** : `POST /api/v1/login`

**Données à saisir** :
- Email
- Mot de passe

**Règles de gestion (RG)** :
- RG-AUTH-001 : Email doit être au format valide
- RG-AUTH-002 : Mot de passe minimum 6 caractères
- RG-AUTH-003 : En cas d'échec, afficher message générique "Identifiants invalides"
- RG-AUTH-004 : En cas de succès, stocker le token JWT dans le stockage sécurisé de l'app
- RG-AUTH-005 : Token JWT valide 24 heures

**Flux** :
1. Saisie email/mot de passe
2. Validation côté client (format email)
3. Appel API POST /api/v1/login
4. Si succès : stocker token → Redirection Dashboard
5. Si échec : afficher erreur

**Données retournées** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "mt5_api_token": "abc123..."
  }
}
```

#### Écran : Inscription (si nécessaire)
**URL API** : `POST /api/v1/register`

**Données à saisir** :
- Email
- Mot de passe
- Confirmation mot de passe
- Prénom
- Nom

**Règles de gestion** :
- RG-AUTH-006 : Email unique dans le système
- RG-AUTH-007 : Mot de passe et confirmation doivent correspondre
- RG-AUTH-008 : Prénom et nom obligatoires

---

### 3.2 Dashboard Principal

#### Écran : Dashboard
**URL API** : 
- `GET /api/v1/users/me` (informations utilisateur)
- `GET /api/v1/accounts/balance` (balance comptes)
- `GET /api/v1/accounts/projection?days=30` (projections)

**Composants à afficher** :

**Section 1 : Vue d'ensemble financière**
- Balance totale de tous les comptes MT5
- Gains nets totaux (balance - capital initial + retraits)
- Commission due (si applicable)
- Crédits disponibles
- Balance à payer (commission due - crédits - paiements validés)

**Règles de gestion** :
- RG-DASH-001 : Affichage des montants avec 2 décimales
- RG-DASH-002 : Mise en évidence visuelle des montants positifs (vert) et négatifs (rouge)
- RG-DASH-003 : Format monétaire avec séparateur : 10 000,50 €
- RG-DASH-004 : Actualisation automatique toutes les 60 secondes

**Section 2 : Comptes MT5**
- Liste des comptes MT5 de l'utilisateur
- Pour chaque compte :
  - Nom du compte
  - Balance actuelle
  - Gains nets
  - Dernière synchronisation

**Règles de gestion** :
- RG-DASH-005 : Affichage du statut de synchronisation (dernière sync)
- RG-DASH-006 : Si dernière sync > 24h, afficher alerte
- RG-DASH-007 : Clic sur un compte → navigation vers détails compte

**Section 3 : Bots Actifs**
- Liste des bots actifs de l'utilisateur
- Pour chaque bot :
  - Nom du bot
  - Statut (🟢 Actif / 🔴 Inactif)
  - Profit total
  - Drawdown actuel
  - ROI (Return on Investment)

**Règles de gestion** :
- RG-DASH-008 : Affichage des bots actifs uniquement (status = 'active')
- RG-DASH-009 : Indicateur visuel si bot en pause (drawdown > limite)
- RG-DASH-010 : Clic sur un bot → navigation vers détails bot

**Section 4 : Projections (Widget)**
- Projection sur 30 jours par défaut
- Projection par compte MT5
- Niveau de confiance (high/medium/low)

**Règles de gestion** :
- RG-DASH-011 : Calcul basé sur les 30 derniers jours de trading
- RG-DASH-012 : Confiance "high" si 20+ jours de trading
- RG-DASH-013 : Confiance "medium" si 10-19 jours
- RG-DASH-014 : Confiance "low" si < 10 jours
- RG-DASH-015 : Permettre changement période (7, 30, 60, 90 jours)

**Actions disponibles** :
- Pull-to-refresh pour actualiser les données
- Navigation vers écrans détaillés

---

### 3.3 Gestion des Comptes MT5

#### Écran : Liste des Comptes
**URL API** : `GET /api/v1/users/me`

**Affichage** :
- Liste de tous les comptes MT5
- Informations : Nom, Balance, Gains, Dernière sync

**Règles de gestion** :
- RG-ACC-001 : Tri par balance décroissante par défaut
- RG-ACC-002 : Badge visuel si compte non synchronisé depuis 24h
- RG-ACC-003 : Clic → navigation vers détails compte

#### Écran : Détails d'un Compte
**URL API** : `GET /api/v1/users/me` + `GET /api/v1/accounts/balance` + `GET /api/v1/accounts/trades`

**Sections à afficher** :

**Section 1 : Informations générales**
- Nom du compte
- MT5 ID
- Balance actuelle
- Equity
- High Watermark (point haut)
- Capital initial
- Gains nets
- Gains réels (sans retraits)
- Total dépôts
- Total retraits
- Broker et serveur

**Règles de gestion** :
- RG-ACC-004 : Affichage des gains nets = balance - capital initial + retraits
- RG-ACC-005 : Affichage des gains réels = balance - capital initial
- RG-ACC-006 : Watermark ne peut jamais baisser (protection commissions)

**Section 2 : Statistiques**
- Profit total (tous trades)
- Nombre total de trades
- Taux de réussite (win rate)
- Profit moyen par trade
- Meilleur trade / Pire trade

**Section 3 : Derniers Trades**
- Liste des 20 derniers trades (API : GET /api/v1/accounts/trades)
- Pour chaque trade :
  - Symbole
  - Type (Achat/Vente)
  - Prix ouverture/fermeture
  - Profit
  - Date/heure
  - Bot associé (si magic_number)

**Règles de gestion** :
- RG-ACC-007 : Affichage formaté : EUR/USD, 1.1234 → 1.1250, +16.00 €
- RG-ACC-008 : Colorisation : profit positif (vert), négatif (rouge)
- RG-ACC-009 : Format date : "23 oct 2025, 14:30"
- RG-ACC-010 : Filtrage possible par bot, période, symbole

**Section 4 : Projections**
- Projection sur 30 jours (configurable)
- Moyenne quotidienne de profit
- Niveau de confiance
- Nombre de jours utilisés pour le calcul

**Actions disponibles** :
- Actualiser les données
- Exporter les trades (si API disponible)
- Filtrer les trades

---

### 3.4 Gestion des Bots

#### Écran : Mes Bots
**URL API** : `GET /api/v1/bots` (nécessite MT5 API token)

**Affichage** :
- Liste de tous les bots achetés par l'utilisateur
- Filtres : Actifs, Inactifs, Tous

**Pour chaque bot** :
- Nom du bot
- Statut (🟢 Actif / 🔴 Inactif)
- Date d'achat
- Prix payé
- Profit total
- Nombre de trades
- ROI (%)
- Drawdown actuel / limite

**Règles de gestion** :
- RG-BOT-001 : Affichage seulement des bots avec status = 'active'
- RG-BOT-002 : ROI = (profit total / prix payé) × 100
- RG-BOT-003 : Alerte visuelle si drawdown > limite autorisée
- RG-BOT-004 : Clic → navigation vers détails bot

#### Écran : Détails d'un Bot
**URL API** : 
- `GET /api/v1/bots/:purchase_id/status`
- `POST /api/v1/bots/:purchase_id/performance` (mise à jour)

**Sections à afficher** :

**Section 1 : Informations générales**
- Nom du bot
- Description
- Niveau de risque (Faible/Modéré/Élevé)
- Prix d'achat
- Date d'achat
- Statut d'achat (Actif/Inactif)
- Statut d'exécution (🟢 En cours / 🔴 En pause)

**Section 2 : Performances**
- Profit total
- Nombre de trades
- ROI (%)
- Profit moyen par trade
- Taux de réussite (win rate)
- Durée active (jours)
- Profit quotidien moyen

**Section 3 : Drawdown**
- Drawdown actuel (% et montant)
- Drawdown maximum enregistré
- Limite autorisée
- Indicateur visuel (jauge) :
  - Vert si < 50% limite
  - Orange si 50-80% limite
  - Rouge si > 80% limite
  - Gris si dépassé

**Règles de gestion** :
- RG-BOT-005 : Calcul drawdown = (peak balance - current balance) / peak balance × 100
- RG-BOT-006 : Si drawdown > limite → bot automatiquement mis en pause
- RG-BOT-007 : Bot en pause → affichage message "Bot en pause - ne pas trader"

**Section 4 : Statistiques par jour**
- Graphique profit par jour de la semaine
- Meilleur jour / jour le plus actif

**Section 5 : Statistiques par heure**
- Graphique profit par heure de la journée
- Meilleure heure / heure la plus active

**Section 6 : Trades du Bot**
- Liste des trades associés (via magic_number)
- Filtres : période, symbole, profit/négatif
- Statistiques détaillées par symbole

**Actions disponibles** :
- Démarrer/Arrêter le bot (si API disponible)
- Actualiser les performances
- Voir l'historique complet

---

### 3.5 Gestion des Trades

#### Écran : Liste des Trades
**URL API** : `GET /api/v1/accounts/trades`

**Affichage** :
- Liste des 20 derniers trades de tous les comptes
- Filtres disponibles :
  - Par compte MT5
  - Par bot (magic_number)
  - Par symbole
  - Par période (24h, 7j, 30j, personnalisé)
  - Par type (profit/négatif)
  - Par statut (ouvert/fermé)

**Pour chaque trade** :
- Symbole (ex: EURUSD)
- Type (Achat/Vente) avec icône
- Prix ouverture → Prix fermeture
- Volume
- Profit/Perte (colorisé)
- Commission
- Swap
- Date/heure ouverture
- Date/heure fermeture
- Bot associé (si applicable)
- Compte MT5

**Règles de gestion** :
- RG-TRD-001 : Tri par date décroissante par défaut
- RG-TRD-002 : Format volume : 0.10 lots
- RG-TRD-003 : Format profit : +16.50 € ou -8.30 €
- RG-TRD-004 : Icônes : ↑ pour achat, ↓ pour vente
- RG-TRD-005 : Badge "Ouvert" pour positions ouvertes

**Actions disponibles** :
- Actualiser
- Filtrer
- Exporter (si API disponible)
- Voir détails d'un trade

#### Écran : Détails d'un Trade
**Affichage** :
- Toutes les informations du trade
- Graphique prix si possible
- Calculs détaillés (profit brut, net, coûts)

---

### 3.6 Projections Financières

#### Écran : Projections
**URL API** : `GET /api/v1/accounts/projection?days=30`

**Affichage** :
- Sélecteur de période (7, 30, 60, 90 jours)
- Projection par compte MT5
- Projection globale

**Pour chaque projection** :
- Balance actuelle
- Balance projetée
- Profit projeté
- Moyenne quotidienne
- Niveau de confiance (high/medium/low)
- Nombre de jours de trading utilisés

**Règles de gestion** :
- RG-PROJ-001 : Calcul basé sur moyenne quotidienne des 30 derniers jours
- RG-PROJ-002 : Confiance high = 20+ jours de trading
- RG-PROJ-003 : Confiance medium = 10-19 jours
- RG-PROJ-004 : Confiance low = < 10 jours
- RG-PROJ-005 : Affichage badge de confiance avec couleur
- RG-PROJ-006 : Graphique de projection avec courbe tendance

**Actions disponibles** :
- Changer période
- Exporter rapport

---

### 3.7 Gestion VPS

#### Écran : Mes VPS
**Affichage** :
- Liste des VPS de l'utilisateur
- Statut de chaque VPS :
  - 🛒 Commandé
  - ⚙️ En Configuration
  - ✅ Prêt
  - 🟢 Actif
  - ⏸️ Suspendu
  - 🔴 Annulé

**Pour chaque VPS** :
- Nom
- Emplacement serveur
- Statut avec badge coloré
- Date de commande
- Date de renouvellement
- Prix mensuel
- IP (si disponible et actif)

**Règles de gestion** :
- RG-VPS-001 : Client ne voit pas les identifiants (sécurité)
- RG-VPS-002 : Affichage IP seulement si statut = 'active'
- RG-VPS-003 : Alerte si renouvellement < 30 jours
- RG-VPS-004 : Navigation vers détails VPS

#### Écran : Détails VPS
**Affichage** :
- Toutes les informations du VPS
- Historique des changements de statut
- Dates importantes (commande, configuration, activation)
- Informations techniques (si actif)

**Règles de gestion** :
- RG-VPS-005 : Affichage timeline du cycle de vie
- RG-VPS-006 : Bouton de contact support si problème

---

### 3.8 Paiements et Commissions

#### Écran : Mes Paiements
**Affichage** :
- Liste des paiements de l'utilisateur
- Statut : En attente / Validé / Rejeté

**Pour chaque paiement** :
- Montant
- Date
- Statut avec badge
- Description
- PDF téléchargeable (si validé)

**Règles de gestion** :
- RG-PAY-001 : Affichage seulement des paiements validés pour montant total
- RG-PAY-002 : Tri par date décroissante
- RG-PAY-003 : Badge coloré selon statut

#### Écran : Commission et Solde
**Affichage** :
- Commission due totale
- Commission due par compte MT5 (basée sur watermark)
- Crédits disponibles
- Paiements validés
- **Balance à payer** = Commission due - Crédits - Paiements

**Règles de gestion** :
- RG-COMM-001 : Commission calculée sur gains commissionnables
- RG-COMM-002 : Gains commissionnables = Balance actuelle - High Watermark
- RG-COMM-003 : Watermark ne peut jamais baisser (protection)
- RG-COMM-004 : Commission = (gains commissionnables × taux) / 100
- RG-COMM-005 : Balance à payer = MAX(0, Commission - Crédits - Paiements)
- RG-COMM-006 : Affichage détaillé par compte MT5

---

### 3.9 Profil Utilisateur

#### Écran : Mon Profil
**URL API** : `GET /api/v1/users/me`

**Affichage** :
- Informations personnelles :
  - Nom, prénom
  - Email
  - Date d'inscription
- Token MT5 API (masqué partiellement)
- Paramètres :
  - Taux de commission
  - Notifications
  - Langue
  - Devise d'affichage

**Actions disponibles** :
- Modifier profil (si API disponible)
- Changer mot de passe (si API disponible)
- Déconnexion
- Supprimer compte (si API disponible)

**Règles de gestion** :
- RG-PROF-001 : Token MT5 affiché partiellement (ex: abc***def)
- RG-PROF-002 : Bouton copier token
- RG-PROF-003 : Confirmation avant suppression compte

---

### 3.10 Notifications

#### Écran : Notifications
**Affichage** :
- Liste des notifications
- Types possibles :
  - Synchronisation MT5 réussie/échec
  - Bot arrêté (drawdown dépassé)
  - Nouveau trade important
  - Paiement validé
  - VPS prêt à activer
  - Alerte balance faible

**Règles de gestion** :
- RG-NOTIF-001 : Notifications push pour événements importants
- RG-NOTIF-002 : Badge de non-lus
- RG-NOTIF-003 : Marquer comme lu
- RG-NOTIF-004 : Paramètres de notifications dans profil

---

## 4. Règles de Gestion Métier Détaillées

### 4.1 Calculs Financiers

#### RG-CALC-001 : Gains Nets
```
Gains Nets = Balance Actuelle - Capital Initial + Total Retraits
```

**Application** : Affichage dans dashboard et détails compte

#### RG-CALC-002 : Gains Réels
```
Gains Réels = Balance Actuelle - Capital Initial
```

**Application** : Affichage dans détails compte (sans retraits)

#### RG-CALC-003 : Gains Commissionnables
```
Gains Commissionnables = Balance Actuelle - High Watermark
Si résultat < 0, alors Gains Commissionnables = 0
```

**Application** : Calcul des commissions

#### RG-CALC-004 : Commission Due
```
Commission Due = (Gains Commissionnables × Taux Commission) / 100
```

**Application** : Calcul dans section paiements

#### RG-CALC-005 : High Watermark
```
High Watermark = MAX(High Watermark Actuel, Balance Actuelle)
```

**Règle** : Le watermark ne peut JAMAIS baisser, seulement augmenter ou rester stable.

**Application** : Protection contre baisse de commissions déjà perçues

#### RG-CALC-006 : Capital Initial
**Si auto_calculated_initial_balance = true** :
```
Capital Initial = Somme de tous les Dépôts
```
**Sinon** :
```
Capital Initial = initial_balance (saisi manuellement)
```

**Application** : Calcul des gains nets et réels

#### RG-CALC-007 : Drawdown
```
Drawdown = (Point Haut - Point Actuel) / Point Haut × 100
```

**Application** : Calcul pour bots et alertes

---

### 4.2 Gestion des Bots

#### RG-BOT-RG-001 : Détection Automatique
Les bots sont automatiquement détectés et assignés lorsqu'un trade avec un `magic_number` correspondant est détecté.

**Application** : Synchronisation MT5

#### RG-BOT-RG-002 : Arrêt Automatique
Un bot est automatiquement mis en pause (`is_running = false`) si :
- Le drawdown dépasse `max_drawdown_limit` du bot
- L'utilisateur le met en pause manuellement

**Application** : Vérification lors de chaque synchronisation

#### RG-BOT-RG-003 : Calcul ROI
```
ROI = (Profit Total / Prix Payé) × 100
```

**Application** : Affichage dans liste et détails bots

#### RG-BOT-RG-004 : Magic Number
Le magic number est généré automatiquement lors de l'achat :
```
Magic Number = (bot.magic_number_prefix × 1000) + user_id
```

**Application** : Identification des trades du bot

---

### 4.3 Synchronisation MT5

#### RG-SYNC-001 : Fréquence de Sync
Les données MT5 sont synchronisées :
- Automatiquement par le script MT5 installé sur le VPS
- Fréquence recommandée : toutes les 5 minutes
- Historique complet au premier lancement

**Application** : Affichage de la dernière synchronisation

#### RG-SYNC-002 : Détection Retrait
Un retrait est automatiquement détecté si :
- Balance diminue significativement
- La diminution > pertes récentes + marge d'erreur

**Application** : Création automatique d'enregistrement Withdrawal

#### RG-SYNC-003 : Dédoublonnage Trades
Les trades sont dédoublonnés par `trade_id` au sein d'un compte MT5.

**Application** : Pas de duplication lors de sync multiples

#### RG-SYNC-004 : Historique Complet
Lors du premier sync d'un compte :
- Synchronisation de TOUS les trades historiques
- Calcul automatique du capital initial
- Marque `init_mt5 = true` après complétion

**Application** : Endpoint `/mt5/sync_complete_history`

---

### 4.4 Projections

#### RG-PROJ-RG-001 : Calcul Projection
```
1. Récupérer tous les trades des 30 derniers jours
2. Calculer le profit total
3. Compter les jours uniques avec trades
4. Moyenne quotidienne = Profit Total / Jours de Trading
5. Profit projeté = Moyenne Quotidienne × Nombre de Jours
6. Balance projetée = Balance Actuelle + Profit Projeté
```

**Application** : API `/accounts/projection`

#### RG-PROJ-RG-002 : Niveau de Confiance
- **High** : 20+ jours de trading dans les 30 derniers jours
- **Medium** : 10-19 jours de trading
- **Low** : < 10 jours de trading

**Application** : Badge de confiance dans UI

#### RG-PROJ-RG-003 : Période Configurable
L'utilisateur peut choisir la période de projection : 7, 30, 60, 90 jours.

**Application** : Paramètre `days` dans l'API

---

### 4.5 Authentification et Sécurité

#### RG-SEC-001 : Token JWT
- Validité : 24 heures
- Stockage : Stockage sécurisé de l'app (Keychain iOS / Keystore Android)
- Renouvellement : Nouvelle connexion requise après expiration

#### RG-SEC-002 : Token MT5 API
- Généré automatiquement à la création du compte
- Unique par utilisateur
- Utilisé pour synchronisation MT5

#### RG-SEC-003 : Données Sensibles
- Les mots de passe ne sont JAMAIS stockés côté client
- Le token JWT est stocké de manière sécurisée
- Les identifiants VPS ne sont jamais visibles côté client

---

### 4.6 Gestion des Erreurs

#### RG-ERR-001 : Connexion Perdue
Si la connexion réseau est perdue :
- Afficher message d'erreur clair
- Proposer réessayer
- Conserver les données en cache si disponibles

#### RG-ERR-002 : Token Expiré
Si le token JWT est expiré :
- Rediriger vers écran de connexion
- Message : "Votre session a expiré, veuillez vous reconnecter"

#### RG-ERR-003 : Erreurs API
- Afficher message d'erreur approprié
- Ne pas afficher les détails techniques à l'utilisateur
- Logger les erreurs pour le support

---

## 5. Flux Utilisateur

### 5.1 Premier Lancement
1. Écran splash/app
2. Vérification connexion internet
3. Si non connecté : Écran connexion
4. Si connecté : Vérification token JWT valide
5. Si token valide : Navigation Dashboard
6. Si token invalide/absent : Écran connexion

### 5.2 Connexion
1. Affichage formulaire connexion
2. Saisie email/mot de passe
3. Validation format email côté client
4. Appel API POST /api/v1/login
5. Si succès :
   - Stockage token JWT
   - Navigation Dashboard
6. Si échec :
   - Affichage erreur
   - Réessai possible

### 5.3 Navigation Dashboard → Détails
1. Dashboard principal
2. Clic sur carte "Compte MT5" → Détails Compte
3. Clic sur carte "Bot" → Détails Bot
4. Clic sur "Trades" → Liste Trades
5. Navigation arrière disponible partout

### 5.4 Actualisation Données
1. Pull-to-refresh dans les listes
2. Actualisation automatique toutes les 60 secondes (dashboard)
3. Actualisation manuelle via bouton

---

## 6. API Disponibles

### 6.1 Authentification
- `POST /api/v1/register` - Inscription
- `POST /api/v1/login` - Connexion

### 6.2 Utilisateur
- `GET /api/v1/users/me` - Informations utilisateur connecté
- `GET /api/v1/users` - Liste utilisateurs (si admin)
- `DELETE /api/v1/users/:id` - Supprimer compte (utilisateur uniquement)

### 6.3 Comptes MT5
- `GET /api/v1/accounts/balance` - Balance de tous les comptes
- `GET /api/v1/accounts/trades` - 20 derniers trades
- `GET /api/v1/accounts/projection?days=30` - Projections

### 6.4 Bots
- `GET /api/v1/bots` - Liste des bots de l'utilisateur
- `GET /api/v1/bots/:purchase_id/status` - Statut d'un bot
- `POST /api/v1/bots/:purchase_id/performance` - Mise à jour performances

### 6.5 Synchronisation MT5 (Backend uniquement)
- `POST /api/v1/mt5/sync` - Synchronisation standard
- `POST /api/v1/mt5/sync_complete_history` - Synchronisation complète

**Note** : Ces endpoints utilisent `X-API-Key` et ne sont pas accessibles depuis l'app mobile.

---

## 7. Contraintes Techniques

### 7.1 Performances
- Temps de chargement initial < 2 secondes
- Actualisation données < 1 seconde
- Mise en cache des données fréquemment consultées
- Pagination pour listes longues (> 50 éléments)

### 7.2 Compatibilité
- iOS : Version 14.0 minimum
- Android : Version 8.0 (API 26) minimum
- Support mode hors ligne (affichage données en cache)

### 7.3 Sécurité
- Stockage sécurisé des tokens (Keychain/Keystore)
- Chiffrement des communications (HTTPS uniquement)
- Validation des données côté client ET serveur
- Pas de stockage de mots de passe

### 7.4 UX/UI
- Design moderne et épuré (inspiré Apple)
- Navigation intuitive
- Feedback visuel pour toutes les actions
- Messages d'erreur clairs et actionnables
- Support du mode sombre (optionnel)

---

## 8. Écrans Prioritaires (MVP)

### Phase 1 - Fonctionnalités Essentielles
1. ✅ Connexion
2. ✅ Dashboard (vue d'ensemble)
3. ✅ Liste Comptes MT5
4. ✅ Détails Compte (balance, trades récents)
5. ✅ Liste Trades
6. ✅ Liste Bots
7. ✅ Détails Bot (performances)

### Phase 2 - Fonctionnalités Avancées
8. ✅ Projections détaillées
9. ✅ Gestion VPS
10. ✅ Paiements et commissions
11. ✅ Profil utilisateur
12. ✅ Notifications

### Phase 3 - Fonctionnalités Bonus
13. Graphiques avancés
14. Export de données
15. Statistiques détaillées par période
16. Historique complet des trades

---

## 9. Spécifications Techniques Mobiles

### 9.1 Stack Technologique Recommandé

**Option 1 : React Native**
- Avantages : Code unique iOS/Android, écosystème riche
- Inconvénients : Performance légèrement inférieure au natif

**Option 2 : Flutter**
- Avantages : Performance native, UI cohérente
- Inconvénients : Courbe d'apprentissage

**Option 3 : Natif**
- iOS : Swift + SwiftUI
- Android : Kotlin + Jetpack Compose
- Avantages : Performance maximale, accès complet APIs
- Inconvénients : Développement séparé

### 9.2 Bibliothèques Recommandées

**Gestion API**
- Axios / Fetch API (React Native)
- Dio (Flutter)
- Alamofire (iOS natif)
- Retrofit (Android natif)

**Gestion État**
- Redux / Zustand (React Native)
- Provider / Riverpod (Flutter)
- Combine (iOS)
- LiveData / Flow (Android)

**Stockage Local**
- AsyncStorage (React Native)
- Hive / SharedPreferences (Flutter)
- CoreData / UserDefaults (iOS)
- Room / SharedPreferences (Android)

**UI Components**
- React Native Paper / NativeBase
- Flutter Material / Cupertino
- SwiftUI (iOS)
- Material Design (Android)

---

## 10. Points d'Attention

### 10.1 Synchronisation Temps Réel
L'app doit gérer :
- Données qui peuvent changer entre deux appels API
- Conflits de données
- État de chargement
- État d'erreur

### 10.2 Formatage des Montants
- Format monétaire : 10 000,50 € (espace séparateur milliers, virgule décimale)
- Arrondi à 2 décimales
- Gestion des valeurs négatives (affichage avec signe -)

### 10.3 Gestion des Dates/Heures
- Format d'affichage : "23 octobre 2025, 14:30"
- Timezone : UTC (conversion côté client si nécessaire)
- Relative time : "Il y a 2 heures" pour trades récents

### 10.4 Performance des Listes
- Lazy loading pour listes longues
- Pagination si nécessaire
- Mise en cache des données

### 10.5 Mode Hors Ligne
- Afficher les dernières données en cache
- Badge "Données en cache" ou timestamp
- Message si données trop anciennes

---

## 11. Design System

### 11.1 Couleurs
- **Primaire** : #007AFF (Bleu Apple)
- **Succès** : #34C759 (Vert)
- **Alerte** : #FF9500 (Orange)
- **Erreur** : #FF3B30 (Rouge)
- **Fond** : #F2F2F7 (Gris clair)
- **Texte** : #000000 (Noir) / #8E8E93 (Gris)

### 11.2 Typographie
- Titre : 28pt, Bold
- Sous-titre : 22pt, Semibold
- Corps : 17pt, Regular
- Caption : 13pt, Regular

### 11.3 Espacements
- Petit : 8px
- Moyen : 16px
- Grand : 24px
- Très grand : 32px

---

## 12. Tests à Prévoir

### 12.1 Tests Fonctionnels
- Connexion/déconnexion
- Affichage des données
- Actualisation des données
- Navigation entre écrans
- Filtres et recherches

### 12.2 Tests d'Intégration
- Appels API
- Gestion des erreurs réseau
- Expiration token
- Mode hors ligne

### 12.3 Tests de Performance
- Temps de chargement
- Fluidité de l'interface
- Consommation mémoire
- Consommation batterie

---

## 13. Documentation API Complète

Référence complète disponible dans : `swagger.yaml`

Accès : `http://localhost:3000/api-docs`

---

## 14. Notes Importantes pour le Développement

1. **Tous les montants sont en euros (€)**
2. **Toutes les dates/heures sont en UTC**
3. **Le token JWT expire après 24h**
4. **Les synchronisations MT5 se font côté serveur**
5. **L'app mobile ne communique QUE avec l'API REST**
6. **Les identifiants VPS ne sont jamais exposés à l'utilisateur**
7. **Le watermark ne peut jamais baisser (règle métier critique)**
8. **Les bots peuvent être détectés automatiquement via magic_number**
9. **Les projections sont basées sur des moyennes, pas des garanties**

---

## 15. Glossaire

- **MT5** : MetaTrader 5, plateforme de trading
- **Watermark** : Point haut historique d'un compte (pour calcul commissions)
- **Drawdown** : Baisse depuis le point haut (en %)
- **Magic Number** : Identifiant unique permettant d'associer un trade à un bot
- **VPS** : Virtual Private Server, serveur virtuel pour exécuter les bots
- **ROI** : Return on Investment, retour sur investissement
- **Win Rate** : Taux de réussite, pourcentage de trades gagnants
- **Broker** : Courtier en ligne pour le trading

---

**Document Version** : 1.0  
**Date** : 2025-01-XX  
**Auteur** : Équipe Trayo

