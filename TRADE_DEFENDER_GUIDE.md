# Trade Defender - Guide d'utilisation

## Vue d'ensemble

Le système **Trade Defender** détecte automatiquement tous les trades manuels (magic_number = 0) et vous permet de décider lesquels sont les vôtres vs ceux des clients. Les pénalités ne sont appliquées QUE après votre validation manuelle.

## Fonctionnement

### Détection automatique

Le système identifie **automatiquement** tous les trades manuels en se basant sur le `magic_number` :

- `magic_number = 0` → Trade manuel détecté
- `magic_number > 0` → Trade bot (automatique)

### Workflow

1. **Détection** : Tous les trades manuels sont automatiquement marqués comme "⏳ En attente"
2. **Vous examinez** : Vous voyez tous les trades manuels dans la page Trade Defender
3. **Vous décidez** : Pour chaque trade, vous cliquez :
   - "✓ Mes trades" si c'est votre hedging
   - "⚠️ Client" si c'est un trade client non autorisé
4. **Sanction appliquée** : Uniquement les trades marqués "Client" seront sanctionnés

## Interface Admin

### Accès

**Menu Admin → Trade Defender**

### Page principale

La page affiche 3 statistiques en haut :

- **⏳ En attente** : Nombre de trades non encore classés
- **✓ Mes trades** : Nombre de trades validés comme admin
- **⚠️ Clients (sanctionnés)** : Nombre de trades sanctions avec impact total

### Actions sur les trades

#### Pour un trade individuel :

Si le trade est **⏳ En attente** :

- Bouton **"✓ Mes trades"** → Marque comme admin, pas de sanction
- Bouton **"⚠️ Client"** → Marque comme trade client, **APPLIQUE LA SANCTION** immédiatement

Si le trade est déjà classé :

- Vous pouvez changer le statut (client → admin ou admin → client)

#### Actions en masse :

1. **Sélectionner** les trades avec les cases à cocher
2. **Choisir l'action** :
   - **"Marquer sélectionnés comme MIENS"** → Marque comme admin
   - **"Marquer sélectionnés comme CLIENTS (sanction)"** → Marque comme clients et **APPLIQUE LES SANCTIONS**

## Comment ça fonctionne techniquement

### Détection automatique

```ruby
# Dans le modèle Trade
def detect_trade_originality!
  if magic_number == 0
    self.trade_originality = 'manual_pending_review'  # En attente de votre décision
    self.is_unauthorized_manual = false
  else
    self.trade_originality = 'bot'  # Trades bots
    self.is_unauthorized_manual = false
  end
end
```

### Application des sanctions

Les sanctions ne sont **JAMAIS appliquées automatiquement**. Elles le sont uniquement quand vous cliquez sur "⚠️ Client" :

```ruby
def mark_as_client_trade
  @trade.update!(
    trade_originality: 'manual_client',
    is_unauthorized_manual: true
  )

  # LA SANCTION EST APPLIQUÉE ICI
  @trade.mt5_account.apply_trade_defender_penalty(@trade.profit)
end
```

## Workflow recommandé

### 1. Sur une base régulière

- Consultez la page **Trade Defender** tous les jours
- Voyez les nouveaux trades manuels détectés
- Analysez si c'est vous ou un client

### 2. Validation rapide

Si vous voyez beaucoup de trades suspects d'un même client :

- Sélectionnez-les tous avec la case à cocher
- Cliquez sur **"Marquer sélectionnés comme CLIENTS (sanction)"**
- Les sanctions sont appliquées en masse

### 3. Erreur de classification ?

Si vous vous trompez :

- Cliquez sur l'action opposée
- La sanction est ajustée automatiquement

## Exemple concret

### Scénario

Vous vérifiez Trade Defender et vous voyez :

1. **Trade 001** : 100€ profit, EURUSD - ⏳ En attente

   - Vous cliquez "✓ Mes trades"
   - ➡️ Statut : ✓ Mes trades (pas de sanction)

2. **Trade 002** : -50€, GBPUSD - ⏳ En attente

   - Vous cliquez "⚠️ Client"
   - ➡️ Statut : ⚠️ Client (sanction de -50€ appliquée au watermark)

3. **Trade 003 à 010** : 8 trades suspects du client Jean
   - Vous sélectionnez les 8 trades
   - Cliquez "Marquer sélectionnés comme CLIENTS (sanction)"
   - ➡️ Tous marqués clients avec sanctions appliquées

## Sanctions automatiques

### Principe

Quand vous marquez un trade comme "Client" :

- Le profit du trade est **ajouté** au high watermark
- Cela réduit les gains commissionnables du client
- L'impact est immédiat

### Exemple de sanction

Si un client a :

- High Watermark : 10 000€
- Trade manuel gagnant : +200€ (marqué par vous comme client)
- Balance : 10 500€

**Résultat :**

- High Watermark ajusté : 10 200€ (10 000 + 200)
- Gains commissionnables : 300€ au lieu de 500€

## Avantages de cette approche

### ✅ Sécurité totale

- **Aucune auto-sanction** : Vous gardez le contrôle
- **Erreurs réparables** : Vous pouvez changer votre décision
- **Traçabilité** : Tous les trades manuels sont visibles

### ✅ Flexibilité

- Classement **individuel** ou **en masse**
- Validation **rapide** ou **approfondie**
- Interface **claire** avec statistiques

### ✅ Mobile-friendly

- Pas besoin d'ajouter de commentaires dans MT5
- Vous tradez normalement sur mobile
- Vous vérifiez ensuite dans l'interface

## FAQ

**Q : Que faire si je trade sur mobile sans commentaire ?**
R : Pas de problème ! Les trades manuels seront détectés et marqués "⏳ En attente". Vous vérifiez et validez plus tard.

**Q : Les pénalités s'appliquent quand ?**
R : **Uniquement** quand vous cliquez sur "⚠️ Client" ou "Marquer sélectionnés comme CLIENTS (sanction)".

**Q : Les trades en attente impactent-ils les commissions ?**
R : **NON** ! Seuls les trades marqués "Client" impactent le watermark.

**Q : Puis-je changer mon avis ?**
R : **OUI** ! Vous pouvez changer un trade "Client" → "Admin" ou vice versa à tout moment.

**Q : Combien de temps ai-je pour décider ?**
R : **Autant que nécessaire** ! Les trades en attente n'impactent rien jusqu'à votre décision.

## Support

Pour toute question :

- Consultez la page **Trade Defender** pour voir tous les trades manuels
- Utilisez les actions en masse pour gagner du temps
- Les statistiques en haut montrent l'impact total des sanctions
