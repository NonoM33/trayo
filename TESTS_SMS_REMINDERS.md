# Tests SMS Rappels de Commission

## Vue d'ensemble

Ce document liste tous les tests pour s'assurer que :

- ✅ Aucun SMS n'est oublié
- ✅ Aucun SMS n'est envoyé par erreur
- ✅ Les messages sont corrects selon le contexte

---

## 1. Tests du Service CommissionReminderSender

### 1.1 Envoi de SMS réussi

| Test                 | Description                             | Résultat attendu                                  |
| -------------------- | --------------------------------------- | ------------------------------------------------- |
| SMS initial envoyé   | Client avec téléphone et commission due | SMS envoyé, statut "sent", external_id enregistré |
| Numéro normalisé     | Numéro français 0776695886              | Converti en +33776695886                          |
| Numéro international | Numéro déjà au format +33               | Conservé tel quel                                 |
| Numéro avec 33       | Numéro commençant par 33                | Converti en +33...                                |
| Message enregistré   | Contenu du SMS sauvegardé               | Message complet dans message_content              |
| Référence watermark  | Référence dans le message               | Format REFXXXX dans le message                    |

### 1.2 Blocages et validations

| Test              | Description                     | Résultat attendu                           |
| ----------------- | ------------------------------- | ------------------------------------------ |
| Pas de téléphone  | Client sans numéro              | Erreur "Aucun numéro renseigné", aucun SMS |
| Pas de commission | Client sans commission due      | Erreur "Aucune commission due", aucun SMS  |
| Force avec 0€     | Client avec 0€ mais force: true | SMS envoyé quand même                      |
| Erreur API        | L'API SMS retourne une erreur   | Statut "failed", erreur enregistrée        |
| JSON invalide     | Réponse API mal formée          | Gestion gracieuse, pas de crash            |

### 1.3 Types de messages

| Test            | Description          | Résultat attendu                               |
| --------------- | -------------------- | ---------------------------------------------- |
| Message initial | Type "initial"       | Message standard avec "régler sous 48h"        |
| Message 24h     | Type "follow_up_24h" | Message avec "Il reste 24h"                    |
| Message 2h      | Type "follow_up_2h"  | Message URGENT avec avertissement coupure bots |
| Message 28d     | Type "follow_up_28d" | Message "Rappel important"                     |
| Message manuel  | Type "manual"        | Message standard                               |

### 1.4 Message d'urgence 2h (critique)

| Test                    | Description                       | Résultat attendu                                    |
| ----------------------- | --------------------------------- | --------------------------------------------------- |
| Avertissement URGENT    | Présence du préfixe 🚨 URGENT     | Oui                                                 |
| Coupure bots mentionnée | Mention de la coupure automatique | Oui                                                 |
| Conséquences listées    | Liste des dangers                 | Trades non contrôlés, danger réel, gestion manuelle |
| Frais mentionnés        | Montant des frais (120€)          | Oui                                                 |
| Appel à l'action        | "Agissez MAINTENANT"              | Oui                                                 |

### 1.5 Prévisualisation

| Test                | Description        | Résultat attendu                      |
| ------------------- | ------------------ | ------------------------------------- |
| Preview sans envoi  | Appel de preview() | Pas de SMS envoyé, pas de rappel créé |
| Preview avec erreur | Pas de téléphone   | Erreur levée                          |
| Preview contenu     | Contenu du message | Message complet retourné              |

---

## 2. Tests du Job CommissionReminderScheduleJob

### 2.1 Le 14 du mois - Envoi initial

| Test                   | Description                 | Résultat attendu    |
| ---------------------- | --------------------------- | ------------------- |
| Client éligible        | Téléphone + commission due  | SMS initial envoyé  |
| Client sans téléphone  | Pas de numéro               | Ignoré, pas de SMS  |
| Client sans commission | 0€ de commission            | Ignoré, pas de SMS  |
| Admin ignoré           | Utilisateur admin           | Ignoré, pas de SMS  |
| Plusieurs clients      | Plusieurs clients éligibles | SMS envoyé à chacun |

### 2.2 Le 28 du mois - Relances

| Test                       | Description                             | Résultat attendu       |
| -------------------------- | --------------------------------------- | ---------------------- |
| Client avec rappel initial | Rappel initial du mois + commission due | Relance envoyée        |
| Client sans rappel initial | Pas de rappel initial ce mois           | Ignoré, pas de relance |
| Commission payée           | Rappel initial mais 0€ maintenant       | Ignoré, pas de relance |
| Rappel échoué              | Rappel initial en "failed"              | Ignoré, pas de relance |
| Rappel ancien mois         | Rappel initial du mois précédent        | Ignoré, pas de relance |
| Rappel en pending          | Rappel initial en "pending"             | Relance envoyée        |

### 2.3 Autres jours

| Test    | Description     | Résultat attendu |
| ------- | --------------- | ---------------- |
| Jour 15 | Ni 14 ni 28     | Aucune action    |
| Jour 1  | Premier du mois | Aucune action    |
| Jour 30 | Fin du mois     | Aucune action    |

---

## 3. Tests du Job CommissionReminderDispatchJob

### 3.1 Rappel initial avec follow-ups

| Test                 | Description               | Résultat attendu                |
| -------------------- | ------------------------- | ------------------------------- |
| Envoi initial        | SMS initial envoyé        | Rappel créé avec statut "sent"  |
| Planification 24h    | Follow-up 24h planifié    | Job planifié 24h avant deadline |
| Planification 2h     | Follow-up 2h planifié     | Job planifié 2h avant deadline  |
| Deadline trop proche | Deadline dans 1h          | Pas de planification 2h         |
| Pas de follow-ups    | schedule_followups: false | Aucune planification            |

### 3.2 Rappels follow-up

| Test          | Description               | Résultat attendu                 |
| ------------- | ------------------------- | -------------------------------- |
| Follow-up 24h | SMS 24h envoyé            | Pas de nouveaux follow-ups       |
| Follow-up 2h  | SMS 2h avec avertissement | Message URGENT avec coupure bots |
| Follow-up 28d | SMS relance mensuelle     | Pas de nouveaux follow-ups       |

### 3.3 Gestion des erreurs

| Test                   | Description   | Résultat attendu                |
| ---------------------- | ------------- | ------------------------------- |
| Utilisateur inexistant | ID invalide   | Aucune action, pas de crash     |
| Envoi échoué           | Erreur API    | Pas de planification follow-ups |
| Utilisateur supprimé   | User supprimé | Gestion gracieuse               |

---

## 4. Cas limites et edge cases

### 4.1 Numéros de téléphone

| Test                | Description        | Résultat attendu    |
| ------------------- | ------------------ | ------------------- |
| Numéro avec espaces | "07 76 69 58 86"   | Espaces supprimés   |
| Numéro très court   | "123"              | Normalisé en +33... |
| Numéro très long    | "+337766958861234" | Conservé tel quel   |

### 4.2 Dates et deadlines

| Test                  | Description            | Résultat attendu       |
| --------------------- | ---------------------- | ---------------------- |
| Deadline personnalisé | Deadline fourni        | Utilisé au lieu de 48h |
| Deadline passé        | Deadline dans le passé | Géré gracieusement     |
| Changement de mois    | 28 février → 1er mars  | Logique correcte       |

### 4.3 Montants

| Test               | Description | Résultat attendu          |
| ------------------ | ----------- | ------------------------- |
| Montant très petit | 0.01€       | SMS envoyé si force: true |
| Montant très grand | 999999.99€  | Formatage correct         |
| Montant négatif    | -50€        | Traité comme 0€           |

---

## 5. Scénarios complets

### 5.1 Scénario normal (client qui paie)

| Étape | Date  | Action            | Résultat                         |
| ----- | ----- | ----------------- | -------------------------------- |
| 1     | 14/11 | Envoi initial     | SMS envoyé, follow-ups planifiés |
| 2     | 15/11 | Rappel 24h        | SMS envoyé                       |
| 3     | 16/11 | Rappel 2h         | SMS URGENT envoyé                |
| 4     | 16/11 | Paiement effectué | Commission = 0€                  |
| 5     | 28/11 | Relance mensuelle | Pas de relance (déjà payé)       |

### 5.2 Scénario non-paiement (relance mensuelle)

| Étape | Date  | Action            | Résultat                                 |
| ----- | ----- | ----------------- | ---------------------------------------- |
| 1     | 14/11 | Envoi initial     | SMS envoyé                               |
| 2     | 15/11 | Rappel 24h        | SMS envoyé                               |
| 3     | 16/11 | Rappel 2h         | SMS URGENT envoyé                        |
| 4     | 16/11 | Pas de paiement   | Commission toujours due                  |
| 5     | 28/11 | Relance mensuelle | SMS relance envoyé avec nouveau deadline |

### 5.3 Scénario client sans téléphone

| Étape | Date  | Action            | Résultat                  |
| ----- | ----- | ----------------- | ------------------------- |
| 1     | 14/11 | Envoi initial     | Ignoré (pas de téléphone) |
| 2     | 28/11 | Relance mensuelle | Ignoré (pas de téléphone) |

### 5.4 Scénario paiement partiel

| Étape | Date  | Action               | Résultat                   |
| ----- | ----- | -------------------- | -------------------------- |
| 1     | 14/11 | Envoi initial (200€) | SMS envoyé                 |
| 2     | 15/11 | Paiement 100€        | Commission = 100€          |
| 3     | 15/11 | Rappel 24h           | SMS envoyé (100€ restants) |
| 4     | 28/11 | Relance mensuelle    | SMS envoyé si toujours dû  |

---

## 6. Checklist de validation

### ✅ SMS jamais oubliés

- [ ] Client avec téléphone + commission → SMS envoyé le 14
- [ ] Client avec rappel initial + commission toujours due → Relance le 28
- [ ] Rappel 24h planifié automatiquement
- [ ] Rappel 2h planifié automatiquement

### ✅ SMS jamais envoyés par erreur

- [ ] Client sans téléphone → Pas de SMS
- [ ] Client sans commission (0€) → Pas de SMS (sauf force)
- [ ] Admin → Pas de SMS
- [ ] Client sans rappel initial → Pas de relance le 28
- [ ] Client qui a payé → Pas de relance le 28
- [ ] Autres jours que 14/28 → Pas de SMS automatique

### ✅ Messages corrects

- [ ] Message initial → Format standard
- [ ] Message 24h → Mention "24h restantes"
- [ ] Message 2h → URGENT + avertissement bots + conséquences
- [ ] Message 28d → "Rappel important"
- [ ] Tous les messages → Montant, référence, lien paiement, deadline

### ✅ Normalisation téléphone

- [ ] 0776695886 → +33776695886
- [ ] +33776695886 → +33776695886
- [ ] 33776695886 → +33776695886
- [ ] Espaces supprimés

---

## 7. Commandes de test

```bash
# Tous les tests SMS
bundle exec rspec spec/services/commission_reminder_sender_spec.rb spec/jobs/commission_reminder_*_spec.rb

# Un fichier spécifique
bundle exec rspec spec/services/commission_reminder_sender_spec.rb

# Avec couverture
COVERAGE=true bundle exec rspec spec/services/commission_reminder_sender_spec.rb
```

---

## 8. Résumé des protections

| Protection                         | Test | Statut |
| ---------------------------------- | ---- | ------ |
| Pas de SMS sans téléphone          | ✅   | Testé  |
| Pas de SMS sans commission         | ✅   | Testé  |
| Pas de SMS aux admins              | ✅   | Testé  |
| Pas de relance sans rappel initial | ✅   | Testé  |
| Pas de relance si payé             | ✅   | Testé  |
| Message 2h avec avertissement      | ✅   | Testé  |
| Normalisation téléphone            | ✅   | Testé  |
| Gestion erreurs API                | ✅   | Testé  |
| Planification follow-ups           | ✅   | Testé  |

---

**Dernière mise à jour** : Novembre 2025
