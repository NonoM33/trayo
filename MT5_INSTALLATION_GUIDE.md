# Guide d'Installation du Script MT5 - TrayoSync

## 📋 Prérequis

- MetaTrader 5 installé
- Compte MT5 (démo ou réel)
- Compte créé sur l'API Trayo avec le `mt5_api_token`

---

## 🚀 Installation

### 1. Ouvrir MetaTrader 5

### 2. Ouvrir l'Éditeur MetaEditor

- Menu : **Tools** → **MetaQuotes Language Editor** (ou F4)

### 3. Créer un nouveau script

- Menu : **File** → **New** → **Script**
- Nom : `TrayoSync`
- Cliquer **Next** → **Finish**

### 4. Copier le code

- Ouvrir le fichier `TrayoSync.mq5` créé
- Remplacer tout le contenu par le code du script
- **Sauvegarder** (Ctrl+S)

### 5. Compiler le script

- Menu : **File** → **Compile** (ou F7)
- Vérifier qu'il n'y a pas d'erreurs dans l'onglet "Errors"

---

## ⚙️ Configuration

### 1. Autoriser les requêtes Web

**IMPORTANT** : MT5 bloque par défaut les requêtes HTTP

Dans MetaTrader 5 :

1. Menu : **Tools** → **Options**
2. Onglet **Expert Advisors**
3. Cocher **Allow WebRequest for listed URL**
4. Ajouter votre URL : `http://localhost:3000`
   - En production : `https://votre-domaine.com`
5. Cliquer **OK**

### 2. Récupérer votre mt5_api_token

```bash
# S'inscrire ou se connecter
curl -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "trader@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

**Copier le `mt5_api_token` retourné dans la réponse**

### 3. Configurer les paramètres du script

Quand vous attachez le script au graphique, une fenêtre s'ouvre avec :

- **API_URL** : `http://localhost:3000/api/v1/mt5/sync`
  - En production : `https://votre-api.com/api/v1/mt5/sync`
- **API_KEY** : `mt5_secret_key_change_in_production`
  - La clé globale du serveur (X-API-Key)
- **MT5_API_TOKEN** : `votre_token_unique_ici`
  - Le token reçu lors de l'inscription
- **REFRESH_INTERVAL** : `300`
  - Intervalle en secondes (300 = 5 minutes)

---

## 🎯 Utilisation

### 1. Ouvrir un graphique

Dans MT5, ouvrir n'importe quel graphique (ex: EURUSD)

### 2. Attacher le script

- Dans le **Navigator** (Ctrl+N), aller dans **Scripts**
- Double-cliquer sur **TrayoSync**
- Ou glisser-déposer **TrayoSync** sur le graphique

### 3. Configurer les paramètres

Une fenêtre s'ouvre :

- **Inputs** : Configurer les paramètres (API_URL, tokens, etc.)
- **Common** : Cocher **Allow DLL imports** (si nécessaire)
- Cliquer **OK**

### 4. Vérifier l'exécution

- Onglet **Experts** en bas de MT5
- Vous devriez voir :
  ```
  TrayoSync started
  API URL: http://localhost:3000/api/v1/mt5/sync
  Refresh Interval: 300 seconds
  ------------------------------------------------
  [2025.10.23 09:00:00] Data synchronized successfully
  ```

### 5. Arrêter le script

- Clic droit sur le graphique → **Expert Advisors** → **Remove**
- Ou fermer MT5

---

## 🔍 Vérification

### Tester que ça fonctionne

```bash
# Vérifier le solde
curl http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer VOTRE_JWT_TOKEN"

# Vérifier les trades
curl http://localhost:3000/api/v1/accounts/trades \
  -H "Authorization: Bearer VOTRE_JWT_TOKEN"
```

---

## ⚠️ Résolution de Problèmes

### Erreur "WebRequest is not allowed"

➡️ Ajouter l'URL dans **Tools** → **Options** → **Expert Advisors** → **Allow WebRequest**

### Erreur 401 "Invalid API key"

➡️ Vérifier que `API_KEY` correspond à la clé serveur

### Erreur 404 "Invalid MT5 API token"

➡️ Vérifier que `MT5_API_TOKEN` est correct

### Pas de données synchronisées

➡️ Vérifier les logs dans l'onglet **Experts** de MT5

### Le script ne démarre pas

➡️ Vérifier qu'il est compilé sans erreur (F7)

---

## 📊 Données Synchronisées

Le script envoie :

- **Compte** : Nom, ID, Solde
- **Trades** : Les 24 dernières heures
  - ID du trade
  - Symbol (EURUSD, GBPUSD, etc.)
  - Type (buy/sell)
  - Volume
  - Prix d'ouverture/fermeture
  - Profit
  - Commission
  - Swap
  - Dates

---

## 🔄 Fréquence de Synchronisation

Par défaut : **5 minutes** (300 secondes)

Vous pouvez changer :

- **1 minute** : 60
- **5 minutes** : 300 (recommandé)
- **15 minutes** : 900
- **1 heure** : 3600

⚠️ **Ne pas mettre moins de 30 secondes** pour ne pas surcharger l'API

---

## 🎯 Exemple Complet

### 1. Créer un compte

```bash
curl -X POST http://localhost:3000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"trader@test.com","password":"pass123","password_confirmation":"pass123"}}'
```

**Réponse :**

```json
{
  "token": "eyJhbGci...",
  "user": {
    "mt5_api_token": "a8201ef875fbed9cf39f83b492bb3b1d..."
  }
}
```

### 2. Configurer TrayoSync

- API_URL : `http://localhost:3000/api/v1/mt5/sync`
- API_KEY : `mt5_secret_key_change_in_production`
- MT5_API_TOKEN : `a8201ef875fbed9cf39f83b492bb3b1d...` ← **Copier depuis la réponse**
- REFRESH_INTERVAL : `300`

### 3. Lancer le script sur MT5

### 4. Vérifier les données

```bash
TOKEN="eyJhbGci..." # Token JWT de la réponse

curl http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer $TOKEN"
```

---

## ✅ C'est prêt !

Le script synchronise maintenant automatiquement :

- Votre solde
- Vos trades des dernières 24h
- Toutes les 5 minutes (ou selon votre configuration)

Vous pouvez consulter vos données depuis le frontend ou l'API ! 🎉

