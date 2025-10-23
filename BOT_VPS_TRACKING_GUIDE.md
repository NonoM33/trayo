# 🤖 Guide : Tracking des Bots & VPS

Ce guide explique le système complet de gestion des bots de trading et des VPS pour Trayo.

---

## 📊 Système de Tracking des Bots par Magic Number

### Concept
Chaque bot assigné à un client reçoit un **Magic Number unique** qui permet d'identifier automatiquement ses trades dans MT5.

### Comment ça Fonctionne

#### 1. **Configuration du Bot** (Admin)
- Dans `/admin/bots`, créer/modifier un bot
- Définir un **Symbol** (ex: EURUSD, GBPUSD)
- Définir un **Magic Number Prefix** (ex: 10000, 20000)

#### 2. **Assignation à un Client** (Admin)
- Aller sur `/admin/clients/:id`
- Section "🤖 Bots de Trading"
- Assigner un bot → Un Magic Number unique est généré automatiquement

**Formule** : `Magic Number = (Magic Number Prefix OU Bot ID * 1000) + User ID`

Exemple :
- Bot "Alpha Trader" (ID=5, Prefix=10000)
- Client (ID=3)
- Magic Number généré = **10003**

#### 3. **Configuration MT5** (Client)
Le client doit configurer son Expert Advisor avec le **Magic Number** fourni :

```mql5
input int MagicNumber = 10003;  // Récupéré depuis l'interface

// Dans les ordres
OrderSend(..., MagicNumber, ...);
```

#### 4. **Synchronisation Automatique**
Le script `TrayoSync.mq5` envoie automatiquement :
- `magic_number` de chaque trade
- `comment` (tag additionnel optionnel)
- `symbol` (EURUSD, etc.)

#### 5. **Tracking des Performances**
À chaque sync API, le système :
1. Récupère tous les trades avec le bon `magic_number`
2. Calcule automatiquement :
   - `total_profit`
   - `trades_count`
   - `current_drawdown`
   - `max_drawdown_recorded`

---

## 🖥️ Système de Gestion VPS

### États du VPS

| Statut | Icon | Description |
|--------|------|-------------|
| **Commandé** | 🛒 | VPS commandé, en attente de provisioning |
| **En Configuration** | ⚙️ | Installation en cours (OS, MT5, bots) |
| **Prêt** | ✅ | VPS configuré, prêt à être activé |
| **Actif** | 🟢 | VPS opérationnel, client l'utilise |
| **Suspendu** | ⏸️ | Temporairement arrêté |
| **Annulé** | 🔴 | Commande annulée |

### Workflow Admin

#### Créer un VPS
```
/admin/vps/new
```
1. Sélectionner le client
2. Nom du VPS
3. Emplacement serveur
4. IP (si déjà attribuée)
5. Prix mensuel
6. Statut initial (généralement "Commandé")

#### Gérer le Cycle de Vie
```
/admin/vps/:id
```
Boutons d'actions rapides :
- 🛒 **Marquer Commandé** → Enregistre `ordered_at`
- ⚙️ **Marquer En Configuration** → Enregistre `configured_at`
- ✅ **Marquer Prêt** → Enregistre `ready_at`
- 🟢 **Marquer Actif** → Enregistre `activated_at`
- ⏸️ **Suspendre**
- 🔴 **Annuler**

#### Ajouter les Identifiants
Dans la page VPS, section "🔑 Accès & Configuration" :
```
Username: vps_user
Password: SuperSecure123!
IP: 192.168.1.100
Port RDP: 3389
Port MT5: 443
```

### Vue Client

Le client peut voir ses VPS dans `/admin/vps` :
- ✅ Voir l'état d'avancement
- ✅ Voir l'IP quand disponible
- ❌ Ne peut PAS voir les identifiants (sécurité)
- ❌ Ne peut PAS modifier quoi que ce soit

---

## 🔄 Flux Complet d'Utilisation

### Scenario : Client Achète un Bot

1. **Client achète "Alpha Trader Pro"** (`/admin/shop`)
   - Bot ajouté à "Mes Bots"
   - Magic Number généré automatiquement: `10008`
   - Statut: `is_running = false`

2. **Admin active le bot** (`/admin/clients/:id`)
   - Clic sur "▶️ Démarrer"
   - `is_running = true`
   - `started_at = maintenant`

3. **Admin commande un VPS** (`/admin/vps/new`)
   - Nom: "VPS Trading - Client X"
   - Statut: "Commandé"
   - `ordered_at = maintenant`

4. **Admin configure le VPS**
   - Change statut → "En Configuration"
   - Installe Windows Server
   - Installe MT5
   - Configure les bots avec Magic Number `10008`

5. **Admin marque VPS "Prêt"**
   - Ajoute les identifiants d'accès
   - Ajoute l'IP: `185.123.45.67`

6. **Client se connecte au VPS**
   - Voit l'IP dans `/admin/vps`
   - L'admin lui fournit les identifiants séparément

7. **Synchronisation Automatique**
   - `TrayoSync.mq5` tourne sur le VPS
   - Envoie les trades toutes les 5 minutes
   - Trades avec `magic_number = 10008` sont attribués au bon bot
   - Performances mises à jour automatiquement

8. **Client voit ses stats** (`/admin/my_bots`)
   - Profit Total: 1 250 €
   - Nombre de Trades: 45
   - ROI: +25%
   - Drawdown: 120 € / 500 € (24%)

---

## 🔧 Configuration MT5 Expert Advisor

### Template pour les Bots

```mql5
//+------------------------------------------------------------------+
//|                                              AlphaTaderPro.mq5   |
//+------------------------------------------------------------------+
#property copyright "Trayo"
#property version   "1.00"

input int MagicNumber = 10008;  // À récupérer depuis le back office
input double LotSize = 0.1;
input int StopLoss = 50;
input int TakeProfit = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Alpha Trader Pro started with Magic Number: ", MagicNumber);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Logique de trading ici
   
   // IMPORTANT : Utiliser le MagicNumber dans tous les ordres
   OrderSend(
      Symbol(),           // symbol
      ORDER_TYPE_BUY,     // type
      LotSize,            // volume
      Ask,                // price
      3,                  // slippage
      Ask - StopLoss * Point(),   // sl
      Ask + TakeProfit * Point(), // tp
      "Alpha Trader Pro", // comment
      MagicNumber,        // Magic Number <<<< IMPORTANT
      0,                  // expiration
      clrGreen            // color
   );
}
//+------------------------------------------------------------------+
```

---

## 📈 API Endpoints pour Bots

### GET `/api/v1/bots`
Liste tous les bots du client avec leur Magic Number

```json
{
  "success": true,
  "bots": [
    {
      "purchase_id": 42,
      "bot_id": 5,
      "bot_name": "Alpha Trader Pro",
      "is_running": true,
      "max_drawdown_limit": 500.00,
      "current_drawdown": 120.50,
      "total_profit": 1250.00,
      "magic_number": 10008
    }
  ]
}
```

### GET `/api/v1/bots/:purchase_id/status`
Vérifie si un bot doit trader ou non

```json
{
  "success": true,
  "bot_name": "Alpha Trader Pro",
  "is_running": true,
  "max_drawdown_limit": 500.00,
  "current_drawdown": 120.50,
  "message": "Bot active - trading autorisé"
}
```

---

## 🎯 Résumé

### Avantages du Système

✅ **Tracking Automatique** : Pas besoin de saisir manuellement les performances  
✅ **Multi-Bots** : Un client peut avoir plusieurs bots avec des Magic Numbers différents  
✅ **Sécurité** : Seul l'admin peut activer/désactiver les bots  
✅ **Traçabilité** : Chaque trade est lié à son bot via le Magic Number  
✅ **VPS Géré** : Suivi complet du cycle de vie des VPS  

### Limitations

❌ **Pas de contrôle direct MT5** : On ne peut pas arrêter un bot à distance (il faut le faire manuellement dans MT5)  
❌ **Dépendance Magic Number** : Le bot MT5 DOIT utiliser le bon Magic Number  
❌ **Sync périodique** : Les stats sont mises à jour toutes les 5 minutes, pas en temps réel  

---

## 🚀 Prochaines Étapes

1. **Exécuter les migrations** :
   ```bash
   rails db:migrate
   ```

2. **Créer des bots de test** :
   - Aller sur `/admin/bots`
   - Créer un bot avec Symbol et Magic Number Prefix

3. **Assigner un bot à un client** :
   - Aller sur `/admin/clients/:id`
   - Assigner le bot
   - Noter le Magic Number généré

4. **Créer un VPS** :
   - Aller sur `/admin/vps/new`
   - Créer le VPS pour le client

5. **Configurer MT5 sur le VPS** :
   - Installer MT5
   - Configurer le bot avec le bon Magic Number
   - Lancer `TrayoSync.mq5`

6. **Vérifier le tracking** :
   - Attendre une sync (5 min)
   - Vérifier `/admin/my_bots` pour voir les performances

---

**Documentation créée le 23/10/2025**  
**Version 1.0**

