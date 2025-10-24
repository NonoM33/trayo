# 🛠️ Guide de Maintenance UI/UX - Trayo

## 🎨 Modifier les Couleurs

### Changer la couleur d'accent principale

Éditer `app/assets/stylesheets/admin.css` :

```css
:root {
  --color-accent: #3b82f6; /* Votre nouvelle couleur */
  --color-accent-hover: #2563eb; /* Version plus foncée */
  --color-accent-light: #dbeafe; /* Version très claire */
}
```

### Changer les gradients

```css
:root {
  --gradient-accent: linear-gradient(135deg, #DEBUT 0%, #FIN 100%);
}
```

## 📱 Ajuster le Responsive

### Modifier les breakpoints

```css
/* Tablet */
@media (max-width: 1024px) {
  ...;
}

/* Mobile */
@media (max-width: 768px) {
  ...;
}

/* Small Mobile */
@media (max-width: 480px) {
  ...;
}
```

### Masquer/Afficher sur mobile

```css
@media (max-width: 768px) {
  .desktop-only {
    display: none;
  }
  .mobile-only {
    display: block;
  }
}
```

## 🎬 Ajouter des Animations

### 1. Définir l'animation dans admin.css

```css
@keyframes monAnimation {
  0% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.1);
    opacity: 0.8;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}
```

### 2. Appliquer l'animation

```html
<div style="animation: monAnimation 2s ease-in-out infinite;">
  Contenu animé
</div>
```

### 3. Animations disponibles

- `slideUp` : Entrée par le bas
- `slideDown` : Entrée par le haut
- `slideIn` : Entrée latérale
- `fadeIn` : Apparition
- `scaleIn` : Zoom
- `bounce` : Rebond
- `float` : Flottement
- `pulse` : Pulsation
- `shimmer` : Brillance

## 🃏 Utiliser les Composants

### Card standard

```html
<div class="card">
  <h2>Titre avec icône</h2>
  <p>Contenu de la carte</p>
</div>
```

### Info Grid (statistiques)

```html
<div class="info-grid">
  <div class="info-item">
    <div class="info-label">Label</div>
    <div class="info-value positive">1,234 €</div>
  </div>
</div>
```

### Buttons

```html
<!-- Primary -->
<button class="btn btn-primary">Action</button>

<!-- Success -->
<button class="btn btn-success">Valider</button>

<!-- Danger -->
<button class="btn btn-danger">Supprimer</button>

<!-- Small -->
<button class="btn btn-sm btn-primary">Petit</button>

<!-- Large -->
<button class="btn btn-lg btn-primary">Grand</button>
```

### Status Badges

```html
<span class="status-badge status-validated">✓ Validé</span>
<span class="status-badge status-pending">⏳ En attente</span>
<span class="status-badge status-rejected">✗ Rejeté</span>
```

### Info Boxes

```html
<div class="info-box info-box-success">
  <div class="info-box-title">Succès</div>
  <p>Message de succès</p>
</div>

<div class="info-box info-box-warning">
  <div class="info-box-title">Attention</div>
  <p>Message d'avertissement</p>
</div>

<div class="info-box info-box-info">
  <div class="info-box-title">Information</div>
  <p>Message informatif</p>
</div>
```

### Tables Responsive

```html
<div class="table-wrapper">
  <table>
    <thead>
      <tr>
        <th>Colonne 1</th>
        <th>Colonne 2</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Donnée 1</td>
        <td>Donnée 2</td>
      </tr>
    </tbody>
  </table>
</div>
```

## 🌓 Dark Mode

### Toggle programmatique

```javascript
function toggleTheme() {
  const body = document.body;
  if (body.classList.contains("dark-mode")) {
    body.classList.remove("dark-mode");
    localStorage.setItem("theme", "light");
  } else {
    body.classList.add("dark-mode");
    localStorage.setItem("theme", "dark");
  }
}
```

### Vérifier le thème actuel

```javascript
const isDarkMode = document.body.classList.contains("dark-mode");
```

## 📄 Créer une Nouvelle Page

### 1. Structure de base

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Ma Page - Trayo</title>
    <%= stylesheet_link_tag "admin" %>
  </head>
  <body>
    <% @page_title = "🎯 Ma Page" %>

    <div class="app-layout">
      <%= render 'admin/shared/sidebar' %>

      <div class="main-content">
        <%= render 'admin/shared/navbar' %>

        <div class="container">
          <!-- Contenu ici -->
        </div>
      </div>
    </div>
  </body>
</html>
```

### 2. Ajouter au menu sidebar

Éditer `app/views/admin/shared/_sidebar.html.erb` :

```html
<li class="sidebar-menu-item">
  <%= link_to ma_route_path, class: "sidebar-menu-link #{request.path ==
  ma_route_path ? 'active' : ''}" do %>
  <span class="sidebar-menu-icon">🎯</span>
  <span>Ma Page</span>
  <% end %>
</li>
```

### 3. Ajouter au mobile bottom nav (si pertinent)

```html
<%= link_to ma_route_path, class: "mobile-nav-item #{request.path ==
ma_route_path ? 'active' : ''}" do %>
<div class="mobile-nav-icon">🎯</div>
<div class="mobile-nav-label">Ma Page</div>
<% end %>
```

## ⚡ Performance

### Optimisations appliquées

- ✅ Animations GPU (transform, opacity)
- ✅ Transitions CSS natives
- ✅ Pas de JS pour les animations
- ✅ Variables CSS pour les couleurs
- ✅ Lazy loading implicite

### À éviter

- ❌ Will-change (laissé au navigateur)
- ❌ Trop d'animations simultanées
- ❌ Animations sur scroll (scroll-jank)
- ❌ Transitions sur layout properties (width, height, top, left)

## 🐛 Debugging

### Vérifier le dark mode

```javascript
console.log("Theme:", localStorage.getItem("theme"));
console.log("Dark mode active:", document.body.classList.contains("dark-mode"));
```

### Vérifier la sidebar

```javascript
console.log("Sidebar collapsed:", localStorage.getItem("sidebarCollapsed"));
```

### Inspecter les variables CSS

```javascript
const styles = getComputedStyle(document.documentElement);
console.log("Accent color:", styles.getPropertyValue("--color-accent"));
```

## 🎯 Classes Utilitaires

```css
/* Texte */
.text-center      /* Centre le texte */
/* Centre le texte */
.text-muted       /* Texte gris */

/* Layout */
.two-col          /* Grid 2 colonnes */
.three-col        /* Grid 3 colonnes */

/* Colors */
.positive         /* Vert (success) */
.negative         /* Rouge (danger) */

/* Actions */
.action-buttons   /* Flex gap pour boutons */

/* Forms */
.form-group       /* Espacement formulaire */
.form-inline      /* Formulaire inline */
.checkbox-group; /* Checkbox avec label */
```

## 📦 Structure des Fichiers

```
app/
├── assets/stylesheets/
│   ├── admin.css           ← Tous les styles (1900+ lignes)
│   └── application.css
├── views/
│   └── admin/
│       ├── shared/
│       │   ├── _sidebar.html.erb
│       │   └── _navbar.html.erb
│       ├── clients/
│       ├── bots/
│       ├── vps/
│       ├── shop/
│       ├── dashboard/
│       └── sessions/
```

## 🔄 Workflow Modifications

1. **Modifier les styles** → `admin.css`
2. **Tester** → Rafraîchir le navigateur
3. **Vérifier mobile** → DevTools responsive
4. **Tester dark mode** → Toggle thème
5. **Valider** → Toutes les pages

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifier la console (F12) pour les erreurs
2. Valider le HTML (pas de balises non fermées)
3. Vérifier que admin.css est bien chargé
4. Tester en mode incognito (cache)

---

**Dernière mise à jour** : Octobre 2025
