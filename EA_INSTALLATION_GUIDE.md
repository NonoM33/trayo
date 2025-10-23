# Guide d'Installation de l'Expert Advisor MT5 - TrayoSync

## 📋 Différence Script vs Expert Advisor

| Aspect          | Script               | Expert Advisor (EA)        |
| --------------- | -------------------- | -------------------------- |
| Type            | Exécution manuelle   | Automatique                |
| Durée           | Jusqu'à arrêt manuel | Tourne en continu          |
| Redémarrage MT5 | Doit être relancé    | Se relance automatiquement |
| Utilisation     | Tâche ponctuelle     | Surveillance continue      |

✅ **L'Expert Advisor est recommandé pour la synchronisation automatique !**

---

## 🚀 Installation de l'Expert Advisor

### 1. Ouvrir MetaEditor

Dans MT5 : **Tools** → **MetaQuotes Language Editor** (F4)

### 2. Créer l'Expert Advisor

1. Menu : **File** → **New** → **Expert Advisor (template)**
2. Nom : `TrayoSync`
3. **Next** → **Next** → **Finish**

### 3. Copier le code

1. Ouvrir le fichier `TrayoSync.mq5` créé
2. **Remplacer tout le contenu** par le code de l'EA
3. **Sauvegarder** (Ctrl+S)
4. **Compiler** (F7)
5. Vérifier qu'il n'y a pas d'erreurs

---

## ⚙️ Configuration

### 1. Autoriser WebRequest (OBLIGATOIRE)

Dans MetaTrader 5 :

1. **Tools** → **Options**
2. Onglet **Expert Advisors**
3. ✅ Cocher **Allow WebRequest for listed URL**
4. Ajouter : `http://localhost:3000`
   - En production : `https://votre-domaine.com`
5. ✅ Cocher **Allow automated trading**
6. Cliquer **OK**

### 2. Récupérer votre mt5_api_token

```bash
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

**Copier le `mt5_api_token` retourné**

---

## 🎯 Attacher l'Expert Advisor

### 1. Ouvrir un graphique

Ouvrir n'importe quel graphique dans MT5 (ex: EURUSD, M15)

### 2. Glisser-déposer l'EA

1. Dans le **Navigator** (Ctrl+N)
2. Section **Expert Advisors**
3. **Glisser-déposer** `TrayoSync` sur le graphique

### 3. Configurer les paramètres

Une fenêtre s'ouvre avec 3 onglets :

#### Onglet "Inputs" :

- **API_URL** : `http://localhost:3000/api/v1/mt5/sync`
- **API_KEY** : `mt5_secret_key_change_in_production`
- **MT5_API_TOKEN** : `votre_token_unique_ici` ⭐
- **REFRESH_INTERVAL** : `300` (5 minutes)

#### Onglet "Common" :

- ✅ **Allow automated trading**
- ✅ **Allow DLL imports** (si nécessaire)
- ⚠️ **NE PAS cocher** "Allow live trading" (sauf si vous voulez trader)

#### Onglet "Dependencies" :

- Laisser par défaut

### 4. Valider

Cliquer **OK**

---

## ✅ Vérification

### 1. Dans MT5

Un smiley apparaît dans le coin supérieur droit du graphique :

- **😊 Smiley heureux** = EA actif et prêt
- **😐 Smiley triste** = EA désactivé ou erreur

Dans l'onglet **Experts** (bas de MT5) :

```
========================================
TrayoSync Expert Advisor Started
========================================
API URL: http://localhost:3000/api/v1/mt5/sync
Refresh Interval: 300 seconds
Account: 123456789
========================================
------------------------------------------------
Starting synchronization...
Account: 123456789 - Demo Account
Balance: 10000.00 | Equity: 10000.00
Found 5 deals in history
Prepared 5 trades for sync
[SUCCESS] Data synchronized at 2025.10.23 09:00:00
Server response: {"message":"Data synchronized successfully"...}
Next sync in 300 seconds
------------------------------------------------
```

### 2. Via l'API

```bash
# Vérifier le solde
curl http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer VOTRE_JWT_TOKEN"

# Vérifier les trades
curl http://localhost:3000/api/v1/accounts/trades \
  -H "Authorization: Bearer VOTRE_JWT_TOKEN"
```

---

## 🔄 Fonctionnement Automatique

### L'EA synchronise automatiquement :

- ✅ **Au démarrage** : Synchronisation immédiate
- ✅ **Toutes les 5 minutes** : Synchronisation automatique (configurable)
- ✅ **Après redémarrage MT5** : L'EA se relance automatiquement
- ✅ **24/7** : Tourne en continu tant que MT5 est ouvert

### Fréquences recommandées :

- **1 minute** : 60 secondes (pour test)
- **5 minutes** : 300 secondes ⭐ **(recommandé)**
- **15 minutes** : 900 secondes
- **30 minutes** : 1800 secondes
- **1 heure** : 3600 secondes

---

## 🛠️ Gestion de l'EA

### Arrêter l'EA

- Clic droit sur le graphique → **Expert Advisors** → **Remove**
- Ou fermer le graphique
- L'EA s'arrête proprement et affiche :
  ```
  ========================================
  TrayoSync Expert Advisor Stopped
  Reason: 0
  ========================================
  ```

### Modifier les paramètres

1. Clic droit sur le graphique → **Expert Advisors** → **Properties**
2. Modifier les paramètres dans l'onglet **Inputs**
3. Cliquer **OK**
4. L'EA redémarre avec les nouveaux paramètres

### Voir les logs

- Onglet **Experts** en bas de MT5
- Tous les logs de synchronisation y sont affichés

---

## 🔍 Données Synchronisées

### Envoyées toutes les 5 minutes :

- **Compte MT5** :

  - ID du compte
  - Nom du compte
  - Solde actuel
  - Equity (optionnel)

- **Trades (24h)** :
  - ID unique du trade
  - Symbol (EURUSD, etc.)
  - Type (buy/sell)
  - Volume
  - Prix ouverture/fermeture
  - Profit
  - Commission
  - Swap
  - Dates et heures

---

## ⚠️ Résolution de Problèmes

### Smiley triste 😐

➡️ Clic droit sur graphique → **Expert Advisors** → **Properties** → Vérifier que "Allow automated trading" est coché

### "WebRequest is not allowed"

➡️ **Tools** → **Options** → **Expert Advisors** → Ajouter l'URL dans "Allow WebRequest"

### Erreur 401 "Invalid API key"

➡️ Vérifier que `API_KEY` est correct dans les paramètres de l'EA

### Erreur "Invalid MT5 API token"

➡️ Vérifier que `MT5_API_TOKEN` est correct (64 caractères hexadécimaux)

### Pas de synchronisation

➡️ Vérifier les logs dans l'onglet **Experts**

### L'EA ne démarre pas après redémarrage MT5

➡️ Vérifier que "Allow automated trading" est activé dans **Tools** → **Options**

---

## 📊 Exemple de Configuration Complète

### 1. Créer un compte API

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
    "mt5_api_token": "a8201ef875fbed9cf39f83b492bb3b1d2800b183faaae3761660efc3248c6a7a"
  }
}
```

### 2. Configurer l'EA

- **API_URL** : `http://localhost:3000/api/v1/mt5/sync`
- **API_KEY** : `mt5_secret_key_change_in_production`
- **MT5_API_TOKEN** : `a8201ef875fbed9cf39f83b492bb3b1d2800b183faaae3761660efc3248c6a7a`
- **REFRESH_INTERVAL** : `300`

### 3. Attacher l'EA au graphique

### 4. Vérifier la synchronisation

```bash
TOKEN="eyJhbGci..." # JWT de l'inscription

curl http://localhost:3000/api/v1/accounts/balance \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🎯 Avantages de l'Expert Advisor

✅ **Automatique** : Tourne en continu sans intervention  
✅ **Redémarrage** : Se relance après un redémarrage de MT5  
✅ **Fiable** : Timer intégré, pas besoin de boucle manuelle  
✅ **Logs clairs** : Affichage détaillé de chaque synchronisation  
✅ **Production-ready** : Conçu pour tourner 24/7

---

## 🚀 L'EA est maintenant opérationnel !

Votre compte MT5 est synchronisé automatiquement avec l'API toutes les 5 minutes ! 🎉

Pour consulter vos données :

- Via l'API REST
- Via le frontend (à développer)
- Via les logs MT5
