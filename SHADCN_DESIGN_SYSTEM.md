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

**Design System** : Shadcn-inspired
**Palette** : Monochrome avec accents
**Style** : Minimal, Sobre, Élégant
**Date** : Octobre 2025
