# 🎨 Trayo - Shadcn Design System

## Vue d'ensemble

Design system minimaliste et élégant inspiré de shadcn/ui avec une palette sobre noir/blanc/gris.

## 🎯 Principes de Design

### Sobriété

- Pas de gradients flashy
- Pas d'animations excessives
- Couleurs neutres (noir/blanc/gris)
- Bordures subtiles
- Ombres légères

### Clarté

- Typographie lisible
- Hiérarchie visuelle claire
- Espacement généreux
- Contraste optimal

### Élégance

- Bordures arrondies subtiles
- Transitions douces (150ms)
- Hover states discrets
- Design épuré

## 🎨 Palette de Couleurs

### Light Mode

```
Background: hsl(0 0% 100%)          → Blanc pur
Foreground: hsl(240 10% 3.9%)       → Noir très foncé
Card: hsl(0 0% 100%)                → Blanc
Border: hsl(240 5.9% 90%)           → Gris très clair
Muted: hsl(240 4.8% 95.9%)          → Gris clair
```

### Dark Mode

```
Background: hsl(240 10% 3.9%)       → Noir très foncé
Foreground: hsl(0 0% 98%)           → Blanc cassé
Card: hsl(240 10% 3.9%)             → Noir très foncé
Border: hsl(240 3.7% 15.9%)         → Gris foncé
Muted: hsl(240 3.7% 15.9%)          → Gris foncé
```

### Couleurs Fonctionnelles

```
Primary: hsl(240 5.9% 10%)          → Noir (boutons)
Success: hsl(142 76% 36%)           → Vert sobre
Destructive: hsl(0 84.2% 60.2%)     → Rouge sobre
```

## 📐 Variables HSL

Utilisation de HSL pour flexibilité :

```css
:root {
  --background: 0 0% 100%;
  --foreground: 240 10% 3.9%;
  --card: 0 0% 100%;
  --primary: 240 5.9% 10%;
  --border: 240 5.9% 90%;
}

/* Usage */
background-color: hsl(var(--background));
color: hsl(var(--foreground));
border: 1px solid hsl(var(--border));

/* Avec opacité */
background: hsl(var(--muted) / 0.5);
```

## 🧩 Composants

### Card

```html
<div class="card">
  <h2>Titre</h2>
  <p>Contenu</p>
</div>
```

- Background: `hsl(var(--card))`
- Border: `1px solid hsl(var(--border))`
- Radius: `var(--radius)` (0.5rem)
- Padding: `1.5rem`

### Button

```html
<button class="btn btn-primary">Action</button>
<button class="btn btn-outline">Secondaire</button>
```

**Variantes** :

- `.btn-primary` - Noir sur fond blanc
- `.btn-secondary` - Gris clair
- `.btn-outline` - Transparent avec bordure
- `.btn-danger` - Rouge
- `.btn-success` - Vert

**Tailles** :

- `.btn-sm` - Petit
- Default - Normal
- `.btn-lg` - Grand

### Input

```html
<input type="text" placeholder="Email" />
```

- Border: `1px solid hsl(var(--input))`
- Focus: Border `hsl(var(--ring))` + Shadow
- Transition: `150ms`

### Badge

```html
<span class="status-badge status-validated">Validé</span>
<span class="status-badge status-pending">En attente</span>
```

- Border-radius: `9999px` (pill)
- Font-size: `0.75rem`
- Text-transform: `uppercase`
- Opacity sur background

### Table

```html
<div class="table-wrapper">
  <table>
    <thead>
      ...
    </thead>
    <tbody>
      ...
    </tbody>
  </table>
</div>
```

- Hover: Subtle `hsl(var(--muted) / 0.3)`
- Border: Entre les lignes
- Responsive: Overflow-x auto

## 📏 Spacing

```css
0.25rem  → 4px
0.5rem   → 8px
0.75rem  → 12px
1rem     → 16px
1.5rem   → 24px
2rem     → 32px
```

## 🔤 Typographie

### Font Family

```css
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
  "Helvetica Neue", Arial, sans-serif;
```

### Tailles

```css
h1: 1.875rem (30px) - font-weight: 700
h2: 1.125rem (18px) - font-weight: 600
Body: 0.875rem (14px)
Small: 0.75rem (12px)
```

### Letter Spacing

```css
Headings: -0.025em (plus serré)
Uppercase: 0.05em (plus espacé)
```

## 🎭 Animations

### Transitions

```css
transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
```

### Hover Effects

- Opacity change
- Background change
- Border color change
- **PAS** de translateY
- **PAS** de scale
- **PAS** de rotate

### États

```css
/* Button hover */
.btn:hover {
  background: hsl(var(--primary) / 0.9);
}

/* Card hover */
.card:hover {
  border-color: hsl(var(--muted-foreground) / 0.3);
}
```

## 📱 Responsive

### Breakpoints

```css
1024px - Tablet
768px  - Mobile
480px  - Small mobile
```

### Mobile-specific

- Sidebar hidden (translateX)
- Bottom nav visible
- Padding réduit
- Font sizes adaptés

## 🌓 Dark Mode

### Toggle

- Button avec icône 🌙/☀️
- `localStorage.setItem('theme', 'dark')`
- Class `.dark-mode` sur `<body>`

### Variables adaptées

```css
.dark-mode {
  --background: 240 10% 3.9%;
  --foreground: 0 0% 98%;
  --card: 240 10% 3.9%;
  --border: 240 3.7% 15.9%;
}
```

## ✨ Best Practices

### DO ✅

- Utiliser les variables CSS HSL
- Transitions courtes (150ms)
- Borders subtiles
- Spacing généreux
- Typographie hiérarchisée
- Contraste suffisant
- Hover states discrets

### DON'T ❌

- Pas de gradients colorés
- Pas d'animations bounce/pulse
- Pas de box-shadows importantes
- Pas de couleurs vives
- Pas de transformations excessives
- Pas d'emojis partout
- Pas de badges flashy

## 🎨 Exemples

### Page Header

```html
<div style="margin-bottom: 2rem;">
  <h1
    style="font-size: 1.875rem; font-weight: 700; margin: 0 0 0.5rem 0; letter-spacing: -0.025em;"
  >
    Page Title
  </h1>
  <p
    style="font-size: 0.875rem; color: hsl(var(--muted-foreground)); margin: 0;"
  >
    Page description
  </p>
</div>
```

### Stats Grid

```html
<div class="info-grid">
  <div class="info-item">
    <div class="info-label">Metric</div>
    <div class="info-value">1,234</div>
  </div>
</div>
```

### Action Group

```html
<div class="action-buttons">
  <button class="btn btn-outline btn-sm">View</button>
  <button class="btn btn-danger btn-sm">Delete</button>
</div>
```

## 🔧 Maintenance

### Changer la couleur d'accent

```css
:root {
  --primary: 240 5.9% 10%; /* HSL values only */
}
```

### Ajouter une nouvelle variante

```css
.btn-custom {
  background: hsl(var(--custom));
  color: hsl(var(--custom-foreground));
}
```

### Ajuster le radius

```css
:root {
  --radius: 0.5rem; /* ou 0.25rem pour plus carré */
}
```

## 📊 Comparaison Avant/Après

### Avant (Flashy)

- ❌ Gradients partout
- ❌ Animations bounce/pulse
- ❌ Box-shadows XL
- ❌ Couleurs vives
- ❌ Emojis dans les titres
- ❌ Transformations scale/rotate

### Après (Sobre)

- ✅ Fond uni noir/blanc/gris
- ✅ Transitions subtiles 150ms
- ✅ Shadows légères
- ✅ Couleurs neutres
- ✅ Typographie claire
- ✅ Hover states discrets

## 🎯 Résultat

Un design **professionnel, élégant et intemporel** qui :

- Se concentre sur le contenu
- Est agréable à lire
- Fonctionne en light/dark mode
- Est cohérent sur toutes les pages
- Charge rapidement
- Est accessible

---

## 📱 Composants Admin Avancés

### Centre SMS (Slideover)

Le Centre SMS utilise un slideover RailsBlocks pour une expérience fluide :

```html
<dialog data-slideover-target="dialog" class="slideover slideover-right">
  <!-- Header avec gradient -->
  <div
    class="bg-gradient-to-r from-emerald-600/20 via-teal-600/10 to-transparent"
  >
    <h4>Envoyer un SMS</h4>
  </div>

  <!-- Templates en grille 2x2 -->
  <div class="grid grid-cols-2 gap-2">
    <button onclick="fillTemplate('commission')">Commission</button>
    <button onclick="fillTemplate('paiement')">Paiement</button>
  </div>

  <!-- Formulaire avec programmation -->
  <textarea name="message" />
  <input type="datetime-local" name="scheduled_at" />
</dialog>
```

**Comportement des templates :**

- Clic = pré-remplir le textarea (pas d'envoi direct)
- Variables dynamiques : `{prenom}`, `{solde}`, `{commission}`
- Option de programmation avec date/heure
- Historique des SMS envoyés et programmés

### Turbo Streams (Mises à jour sans rechargement)

Les changements de statut utilisent Turbo Stream pour rester sur la page :

```ruby
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace("bot_purchase_#{@bot.id}", partial: "bot_card"),
      turbo_stream.replace("flash_messages", partial: "flash_toast")
    ]
  end
end
```

**Avantages :**

- Pas de rechargement de page
- Reste sur le même onglet
- Toast de confirmation visuel
- Expérience fluide

### Toast de confirmation

```html
<div
  class="fixed bottom-4 right-4 z-50 animate-fade-in-up"
  data-controller="auto-dismiss"
  data-auto-dismiss-delay-value="3000"
>
  <div class="bg-emerald-900/90 border-emerald-700/50">
    <i class="fa-check-circle text-emerald-400"></i>
    <span>Statut mis à jour</span>
  </div>
</div>
```

### Cartes Bot/VPS avec contrôles inline

```html
<!-- Toggle Running -->
<button
  class="relative inline-flex h-7 w-12 items-center rounded-full 
               bg-emerald-500 /* ou bg-neutral-700 si off */"
>
  <span class="translate-x-6 /* ou translate-x-1 si off */"></span>
</button>

<!-- Dropdown Status -->
<select onchange="this.form.requestSubmit()">
  <option value="active">✓ Actif</option>
  <option value="inactive">⏸ Inactif</option>
</select>
```

## 🔔 Système de Notifications SMS

### SMS Programmés

```ruby
# Modèle ScheduledSms
class ScheduledSms < ApplicationRecord
  belongs_to :user
  scope :pending, -> { where(status: 'pending') }
  scope :due, -> { pending.where('scheduled_at <= ?', Time.current) }
end

# Job périodique (toutes les 5 min)
class ScheduledSmsJob < ApplicationJob
  def perform
    ScheduledSms.due.find_each(&:send_now!)
  end
end
```

### Onglet SMS dans fiche client

- Liste des SMS programmés avec option d'annulation
- Historique complet des SMS envoyés
- Indicateur de badge sur l'onglet si SMS en attente

---

## 🛒 Boutique & Système de Panier

### Design Boutique

La boutique utilise une esthétique premium avec gradients et cartes interactives :

```html
<!-- Product Card (Pack Premium) -->
<div
  class="relative rounded-2xl bg-gradient-to-br from-emerald-500/10 to-teal-500/5 
            border-2 border-emerald-500/30 p-6 hover:border-emerald-400/50 transition-all"
>
  <!-- Badge -->
  <span
    class="absolute top-4 right-4 px-3 py-1 rounded-full text-xs font-bold 
               bg-emerald-500 text-white"
    >POPULAIRE</span
  >

  <!-- Icon -->
  <div
    class="w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-400 to-teal-500 
              flex items-center justify-center mb-4 shadow-lg shadow-emerald-500/20"
  >
    <i class="fa-solid fa-wrench text-white text-xl"></i>
  </div>

  <!-- Content -->
  <h3 class="text-xl font-bold text-white">Pack Maintenance</h3>
  <p class="text-neutral-400 text-sm">Description du pack...</p>

  <!-- Price -->
  <div class="flex items-baseline gap-2">
    <span class="text-3xl font-extrabold text-emerald-400">99€</span>
    <span class="text-neutral-500">/an</span>
  </div>

  <!-- CTA -->
  <button
    class="w-full py-3 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 
                 text-white font-semibold hover:from-emerald-600 hover:to-teal-600"
  >
    <i class="fa-solid fa-cart-plus"></i> Ajouter au panier
  </button>
</div>
```

### Système de Panier

Le panier utilise la session Rails pour stocker les items :

```ruby
# Session structure
session[:cart] = {
  bots: [1, 2, 3],      # IDs des bots
  products: [1, 2]       # IDs des packs
}

# CartController actions
- add_bot/:id      → Ajoute un bot au panier
- add_product/:id  → Ajoute un pack au panier
- remove_bot/:id   → Retire un bot
- remove_product/:id → Retire un pack
- clear            → Vide le panier
- checkout         → Crée session Stripe et redirige
- success          → Traite le paiement réussi
```

### Checkout Stripe Multi-Items

```ruby
# Création de la session Stripe avec plusieurs items
line_items = []

cart_bots.each do |bot|
  line_items << { price: get_stripe_price(bot), quantity: 1 }
end

cart_products.each do |product|
  line_items << { price: product.stripe_price_id, quantity: 1 }
end

Stripe::Checkout::Session.create(
  customer_email: current_user.email,
  line_items: line_items,
  mode: has_subscription ? 'subscription' : 'payment',
  success_url: admin_cart_success_url + "?session_id={CHECKOUT_SESSION_ID}",
  cancel_url: admin_cart_url + "?canceled=true",
  metadata: { user_id: current_user.id, bot_ids: '1,2,3', product_ids: '1,2' }
)
```

### États des Boutons

| État         | Style                                                      | Texte            |
| ------------ | ---------------------------------------------------------- | ---------------- |
| Disponible   | `bg-gradient-to-r from-emerald-500 to-teal-500`            | "Ajouter"        |
| Dans panier  | `bg-amber-500/20 border-amber-500/30 text-amber-400`       | "Dans le panier" |
| Déjà possédé | `bg-emerald-500/20 border-emerald-500/30 text-emerald-400` | "Actif"          |

### Page Panier

```
┌─────────────────────────────────────────────────────────────┐
│  🛒 Mon Panier (3 articles)          [Continuer mes achats] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────┐  ┌──────────────────┐ │
│  │ 🤖 Bot GBPUSD       399€   [🗑] │  │ Récapitulatif    │ │
│  │ 🤖 Bot Gold         399€   [🗑] │  │                  │ │
│  │ 🔧 Pack Maintenance  99€   [🗑] │  │ Bot GBPUSD  399€ │ │
│  └─────────────────────────────────┘  │ Bot Gold    399€ │ │
│                                       │ Pack Maint   99€ │ │
│  [Vider le panier]                    │ ───────────────  │ │
│                                       │ Total       897€ │ │
│                                       │                  │ │
│                                       │ [💳 Payer]       │ │
│                                       │ 🔒 SSL 🛡️        │ │
│                                       └──────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Page Succès

Animation de confirmation avec :

- Cercle vert animé (bounce) avec check ✓
- Récapitulatif de la commande
- Boutons d'action (Voir mes bots / Dashboard)
- Lien vers le support

---

**Design System** : Shadcn-inspired + RailsBlocks
**Palette** : Monochrome avec accents (emerald, amber, red, purple, blue)
**Style** : Minimal, Sobre, Élégant, Premium
**Frameworks** : Tailwind CSS, Turbo, Stimulus
**Payment** : Stripe Checkout (multi-items)
**Date** : Novembre 2025
