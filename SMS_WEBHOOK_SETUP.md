# Configuration du Webhook SMS pour le Support Client

## Vue d'ensemble

Le système de support client via SMS permet aux clients d'envoyer "aide" par SMS pour créer automatiquement un ticket SAV. Le webhook reçoit les SMS entrants et crée automatiquement des tickets.

## Fonctionnalités

1. **Mention "aide" dans les SMS de rappel** : Tous les SMS de rappel de commission incluent maintenant la mention "💬 Besoin d'aide ? Envoyez 'aide' par SMS."

2. **Réception automatique des SMS** : Le webhook `/webhooks/sms` reçoit les SMS entrants de l'API SMS Gate.

3. **Création automatique de tickets** :

   - Si l'utilisateur envoie "aide", le système demande plus de détails
   - La réponse suivante crée automatiquement un ticket avec un numéro unique
   - L'utilisateur reçoit une confirmation avec le numéro de ticket

4. **Page SAV dans l'admin** : Nouvelle section "SAV" dans la sidebar avec :

   - Liste de tous les tickets
   - Filtres par statut, numéro, téléphone
   - Statistiques (total, ouverts, fermés, non lus)
   - Badge de notification pour les nouveaux tickets

5. **Notification sur le dashboard** : Alerte visible sur le dashboard admin quand il y a de nouveaux tickets non lus.

## Configuration du Webhook

### 1. Enregistrer le webhook dans l'API SMS Gate

```bash
# Définir l'URL de votre webhook (remplacer par votre domaine)
export SMS_WEBHOOK_URL="https://votre-domaine.com/webhooks/sms"
export SMS_GATEWAY_DEVICE_ID="kHm2-bFyrL7vsjkPqXngD"
export SMS_GATEWAY_USER="EZMOAP"
export SMS_GATEWAY_PASSWORD="mx3yvylh7y-8-o"

# Enregistrer le webhook
bundle exec rake sms:register_webhook
```

### 2. Vérifier les webhooks enregistrés

```bash
bundle exec rake sms:list_webhooks
```

### 3. Configuration en production

Assurez-vous que :

- L'URL du webhook est accessible publiquement (HTTPS requis)
- Le serveur peut recevoir des requêtes POST sur `/webhooks/sms`
- Les variables d'environnement sont configurées correctement

## Structure des données

### Format du webhook reçu

Le webhook reçoit les données au format suivant :

```json
{
  "event": "sms:received",
  "id": "message-id",
  "phoneNumber": "+33776695886",
  "textMessage": {
    "text": "aide"
  }
}
```

### Format du ticket créé

- **ticket_number** : Format `TKT-YYYYMMDD-XXXX` (unique)
- **status** : `open`, `in_progress`, `waiting_for_user`, `closed`
- **phone_number** : Numéro normalisé en format international
- **user** : Utilisateur trouvé par numéro de téléphone (optionnel)
- **description** : Message SMS de l'utilisateur
- **created_via** : `sms`

## Flux utilisateur

1. **Client envoie "aide"** → Le système répond : "Bonjour [Prénom], merci de nous contacter. Pouvez-vous nous expliquer votre problème en détail ?"
2. **Client répond avec sa description** → Un ticket est créé automatiquement
3. **Client reçoit confirmation** : "Bonjour [Prénom], votre demande a bien été prise en compte. Numéro de ticket : TKT-XXXX. Notre équipe vous répondra dans les plus brefs délais."

## Gestion des tickets

### Page SAV (`/admin/support_tickets`)

- **Filtres** : Statut, numéro de ticket, téléphone
- **Actions** : Voir les détails, marquer comme lu, mettre à jour le statut
- **Statistiques** : Total, ouverts, fermés, non lus

### Statuts disponibles

- **open** : Ticket ouvert, en attente de traitement
- **in_progress** : Ticket en cours de traitement
- **waiting_for_user** : En attente de réponse du client
- **closed** : Ticket fermé

## Tests

Pour tester le webhook localement, vous pouvez utiliser ngrok :

```bash
# Installer ngrok
brew install ngrok  # ou télécharger depuis https://ngrok.com

# Démarrer le tunnel
ngrok http 3000

# Utiliser l'URL fournie par ngrok
export SMS_WEBHOOK_URL="https://xxxx.ngrok.io/webhooks/sms"
bundle exec rake sms:register_webhook
```

## Notes importantes

- Le webhook doit toujours retourner un statut HTTP 200 pour éviter les retries
- Les erreurs sont loggées mais n'interrompent pas le traitement
- Les numéros de téléphone sont automatiquement normalisés en format international (+33...)
- Les tickets sont liés aux utilisateurs si le numéro correspond à un compte existant
