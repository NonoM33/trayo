# Système d'Onboarding Trayo

## Vue d'ensemble

Ce système permet aux utilisateurs de s'inscrire sur Trayo via un code d'invitation unique. Le processus d'onboarding se fait en 4 étapes progressives.

## URL

- **Page d'entrée** : `https://join.trayo.fr/join`
- **Onboarding avec code** : `https://join.trayo.fr/join/{CODE}`

## Étapes de l'onboarding

### Étape 1 : Règles du Jeu

- Explication des règles fondamentales
- Collecte des informations personnelles (nom, prénom, email, téléphone)

### Étape 2 : Sélection du Broker

- Choix entre 2 brokers (Exness et IC Markets)
- Saisie des identifiants MT5 (ID et mot de passe trader)

### Étape 3 : Sélection des Bots

- Affichage de tous les bots disponibles
- Affichage des projections mensuelles
- Sélection multiple des bots souhaités

### Étape 4 : Règlement

- Récapitulatif complet
- VPS obligatoire (399€/an)
- Total : VPS + Bots sélectionnés

## Création d'une invitation

```bash
bin/rails invitations:create[1]
```

Crée une nouvelle invitation avec un code unique.

## Lister les invitations

```bash
bin/rails invitations:list
```

Affiche les 20 dernières invitations créées.

## Nettoyer les invitations expirées

```bash
bin/rails invitations:cleanup
```

Supprime automatiquement les invitations expirées.

## Processus de création d'utilisateur

Lors de la finalisation de la commande (étape 4), le système :

1. Crée un utilisateur avec email, mot de passe généré
2. Crée un compte MT5 associé avec les identifiants fournis
3. Crée un VPS en status "ordered"
4. Assigne les bots sélectionnés (BotPurchase)
5. Marque l'invitation comme complétée

## Configuration

### Prix du VPS

- Prix annuel : 399.99€
- Configuré automatiquement pour tous les nouveaux utilisateurs

### Commission par défaut

- Taux de commission : 20%

### Expiration des invitations

- Durée de validité : 30 jours
- Les invitations expirées ne peuvent plus être utilisées

## Design

Le design suit les principes d'Apple avec :

- Interface épurée et moderne
- Navigation fluide entre les étapes
- Indicateur de progression visuel
- Formulaires intuitifs et accessibles
- Design responsive (mobile-first)

## Fichiers créés

### Modèles

- `app/models/invitation.rb`

### Contrôleurs

- `app/controllers/onboarding_controller.rb`

### Vues

- `app/views/onboarding/landing.html.erb`
- `app/views/onboarding/step1_rules.html.erb`
- `app/views/onboarding/step2_brokers.html.erb`
- `app/views/onboarding/step3_bots_selection.html.erb`
- `app/views/onboarding/step4_payment.html.erb`
- `app/views/onboarding/complete.html.erb`
- `app/views/layouts/_onboarding_layout.html.erb`

### Assets

- `app/assets/stylesheets/onboarding.css`

### Migrations

- `db/migrate/20251027142344_create_invitations.rb`

### Routes

- `get "join", to: "onboarding#landing"`
- `get "join/:code", to: "onboarding#show"`
- `get "join/:code/step/:step", to: "onboarding#step"`
- `post "join/:code/next", to: "onboarding#next_step"`
- `get "join/:code/complete", to: "onboarding#complete"`
