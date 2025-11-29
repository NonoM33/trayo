# Guide Boutique & Crédits Commission

## Vue d'ensemble

La boutique Trayo propose désormais trois types de produits :

1. **Packs Crédits Commission** - Recharge de crédits avec bonus
2. **Packs & Services Premium** - Maintenance, support prioritaire, etc.
3. **Bots de Trading** - Licences à vie

---

## 🎨 Design System

### Cards Bots (Style Apple Minimaliste)

```
┌─────────────────────────────────┐
│  [🤖]                           │
│                                 │
│  Bot Name                       │
│  Jusqu'à XXX€/mois              │
│                                 │
│  XX%        +X XXX€             │
│  Win rate   Par an              │
│                                 │
│  ─────────────────────────────  │
│  XXX€ une fois    [Ajouter]     │
└─────────────────────────────────┘
```

- Fond : `bg-gradient-to-br from-blue-950/40 to-indigo-950/20`
- Bordure : `border-blue-500/20 hover:border-blue-500/40`
- CTA : Bouton pill blanc `bg-white text-neutral-900`

### Cards Packs Crédits

```
┌─────────────────────────────────┐
│         [Badge Bonus]           │
│                                 │
│           500€                  │
│         +5% bonus               │
│                                 │
│  ┌─────────────────────────┐    │
│  │   Vous recevez          │    │
│  │      525€               │    │
│  │   +25€ offerts          │    │
│  └─────────────────────────┘    │
│                                 │
│        [Recharger]              │
└─────────────────────────────────┘
```

- Fond standard : `bg-neutral-900 border-neutral-800`
- Pack Populaire (1000€) : `from-amber-950/40 border-amber-500/40`
- Meilleur Bonus (5000€) : `from-violet-950/60 border-violet-500/50`

---

## 💰 Packs Crédits Commission

### Grille tarifaire

| Pack       | Prix  | Bonus | Total Crédits | Économie     |
| ---------- | ----- | ----- | ------------- | ------------ |
| Pack 500€  | 500€  | +5%   | **525€**      | 25€ offerts  |
| Pack 1000€ | 1000€ | +6%   | **1 060€**    | 60€ offerts  |
| Pack 1500€ | 1500€ | +7%   | **1 605€**    | 105€ offerts |
| Pack 2000€ | 2000€ | +8%   | **2 160€**    | 160€ offerts |
| Pack 5000€ | 5000€ | +10%  | **5 500€**    | 500€ offerts |

### Arguments de vente

1. **Bonus progressif** - Plus vous rechargez, plus le bonus est élevé
2. **Fini les relances** - Prélèvement automatique sur le solde
3. **Tranquillité d'esprit** - Vos bots restent actifs sans interruption
4. **Pas de deadline 14 jours** - Gérez à votre rythme

### Flux d'achat

1. Client sélectionne un pack sur `/admin/shop`
2. Redirection vers Stripe Checkout
3. Après paiement → création d'un `Credit` avec le montant total (pack + bonus)
4. Redirection vers boutique avec toast de confirmation

---

## 🖥️ Intégration Dashboard

### Bannière promotionnelle

Affichée sur le dashboard si :

- L'utilisateur n'est pas admin
- Son solde de crédits < 500€

Design : Gradient violet avec icône wallet, avantages listés, CTA "Recharger maintenant"

### Navbar - Bouton Crédits

- Lien cliquable vers la boutique
- Couleur dynamique :
  - Vert (`emerald`) si solde > 0
  - Violet (`violet`) si solde = 0
- Badge "+10%" si solde < 100€ pour inciter à recharger

---

## 🛒 Panier

### Fonctionnalités

- Ajout de bots et produits
- Badge animé avec nombre d'articles
- Résumé avec total
- Checkout Stripe intégré

### Routes

```ruby
resource :cart, only: [:show], controller: 'cart' do
  post 'add_bot/:id', to: 'cart#add_bot'
  post 'add_product/:id', to: 'cart#add_product'
  delete 'remove_bot/:id', to: 'cart#remove_bot'
  delete 'remove_product/:id', to: 'cart#remove_product'
  delete 'clear', to: 'cart#clear'
  post 'checkout', to: 'cart#checkout'
  get 'success', to: 'cart#success'
end
```

---

## 🔧 Modèles impliqués

### Credit

```ruby
class Credit < ApplicationRecord
  belongs_to :user
  validates :amount, presence: true, numericality: { greater_than: 0 }
end
```

Colonnes : `user_id`, `amount`, `reason`, `created_at`

### User

```ruby
def total_credits
  credits.sum(:amount) || 0
end
```

---

## 📊 Statistiques à suivre

- Nombre de packs vendus par type
- Montant total des crédits en circulation
- Taux de conversion dashboard → boutique
- Durée moyenne avant épuisement des crédits

---

## 🎯 Prochaines améliorations possibles

1. Historique des recharges dans le profil client
2. Alerte email quand solde < 100€
3. Système de parrainage avec bonus crédits
4. Offres flash temporaires (+15% bonus)
