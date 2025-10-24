# Référence Rapide - Responsive Design

Guide de référence rapide pour les breakpoints et composants responsive.

---

## 📏 Breakpoints Essentiels

```css
/* Desktop Large */
@media (min-width: 1920px) { }

/* Desktop Standard */
@media (min-width: 1440px) and (max-width: 1919px) { }

/* Laptop */
@media (min-width: 1025px) and (max-width: 1439px) { }

/* Tablet Landscape */
@media (min-width: 769px) and (max-width: 1024px) { }

/* Tablet Portrait */
@media (min-width: 600px) and (max-width: 768px) { }

/* Mobile Large (iPhone Pro Max) */
@media (min-width: 428px) and (max-width: 599px) { }

/* Mobile Standard (iPhone 14) */
@media (min-width: 390px) and (max-width: 427px) { }

/* Mobile Small (iPhone SE) */
@media (max-width: 389px) { }

/* Touch Devices */
@media (hover: none) and (pointer: coarse) { }

/* Retina Displays */
@media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) { }

/* Landscape Mobile */
@media (max-width: 768px) and (orientation: landscape) { }

/* Reduced Motion */
@media (prefers-reduced-motion: reduce) { }
```

---

## 🎯 Touch Targets

| Device | Min Size | Recommandé |
|--------|----------|------------|
| iOS | 44x44pt | 44x44pt |
| Android | 48x48dp | 48x48dp |
| WCAG 2.1 | 44x44px | 44x44px |

**Code:**
```css
.btn,
.sidebar-menu-link,
.mobile-nav-item {
  min-height: 44px;
  min-width: 44px;
}

@media (max-width: 768px) {
  .btn {
    min-height: 48px;
  }
}
```

---

## 📐 Container Widths

| Breakpoint | Max Width |
|------------|-----------|
| 1920px+ | 1600px |
| 1440-1919px | 1400px |
| 1025-1439px | 1200px |
| <1024px | 100% (avec padding) |

---

## 📱 Sidebar Widths

| Breakpoint | Width | Behavior |
|------------|-------|----------|
| >1439px | 240px | Visible |
| 1025-1439px | 220px | Visible |
| 769-1024px | 200px | Visible |
| <768px | 280px | Overlay |

---

## 🔽 Bottom Nav

| Breakpoint | Height | Visible |
|------------|--------|---------|
| >768px | - | ❌ Hidden |
| 600-768px | 60px | ✅ Visible |
| 428-599px | 70px | ✅ Visible |
| 390-427px | 70px | ✅ Visible |
| <390px | 64px | ✅ Visible |

---

## 🎨 Grid Columns (Shop)

| Breakpoint | Columns | Gap |
|------------|---------|-----|
| 1920px+ | 4 | 2rem |
| 1440-1919px | 3 | 1.75rem |
| 1024-1439px | 2 | 1.5rem |
| 769-1023px | 2 | 1.25rem |
| 600-768px | 2 | 1rem |
| <600px | 1 | 1rem |

---

## 📊 Info Grid

| Breakpoint | Columns |
|------------|---------|
| Desktop | 4 (auto-fit) |
| Tablet Portrait | 2 |
| Mobile | 1 |

---

## 📝 Typography Scale

### Headings (h1)
| Breakpoint | Size |
|------------|------|
| Desktop | 1.875rem (30px) |
| Tablet | 1.5rem (24px) |
| Mobile Large | 1.375rem (22px) |
| Mobile Small | 1.125rem (18px) |

### Headings (h2)
| Breakpoint | Size |
|------------|------|
| Desktop | 1.5rem (24px) |
| Tablet | 1.125rem (18px) |
| Mobile | 0.9375rem (15px) |

### Body Text
| Breakpoint | Size |
|------------|------|
| Desktop | 0.875rem (14px) |
| Mobile | 0.8125rem (13px) |

### Buttons
| Breakpoint | Size |
|------------|------|
| Desktop | 0.875rem (14px) |
| Mobile | 0.875-0.9375rem |

---

## 🎯 Spacing System

### Container Padding
| Breakpoint | Padding |
|------------|---------|
| Desktop | 1.5rem |
| Tablet | 1rem-1.5rem |
| Mobile Large | 1rem |
| Mobile Standard | 0.875rem |
| Mobile Small | 0.75rem |

### Card Padding
| Breakpoint | Padding |
|------------|---------|
| Desktop | 1.5rem |
| Tablet | 1.25rem |
| Mobile Large | 1.125rem |
| Mobile Standard | 1rem |
| Mobile Small | 0.875rem |

### Gaps
| Breakpoint | Gap |
|------------|-----|
| Desktop | 1.5rem-2rem |
| Tablet | 1rem-1.5rem |
| Mobile | 0.625rem-1rem |

---

## 📊 Chart Heights

| Breakpoint | Height |
|------------|--------|
| Desktop | 400px |
| Laptop | 350px |
| Tablet | 300px |
| Mobile Large | 280px |
| Mobile Standard | 250px |

---

## 📋 Table Font Sizes

| Breakpoint | Size |
|------------|------|
| Desktop | 0.875rem (14px) |
| Tablet | 0.8125rem (13px) |
| Mobile Large | 0.8125rem |
| Mobile Standard | 0.75rem (12px) |
| Mobile Small | 0.6875rem (11px) |

---

## 🎨 Common Classes

### Buttons
```html
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-outline">Outline</button>
<button class="btn btn-danger">Danger</button>
<button class="btn btn-sm">Small Button</button>
```

### Cards
```html
<div class="card">
  <h2>Card Title</h2>
  <p>Card content</p>
</div>
```

### Info Grid
```html
<div class="info-grid">
  <div class="info-item">
    <div class="info-label">Label</div>
    <div class="info-value">Value</div>
  </div>
</div>
```

### Tables
```html
<div class="table-wrapper">
  <table>
    <thead>
      <tr>
        <th>Header</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Data</td>
      </tr>
    </tbody>
  </table>
</div>
```

### Status Badges
```html
<span class="status-badge status-validated">Validé</span>
<span class="status-badge status-pending">En attente</span>
<span class="status-badge status-cancelled">Annulé</span>
```

### Action Buttons
```html
<div class="action-buttons">
  <button class="btn btn-outline btn-sm">Action 1</button>
  <button class="btn btn-danger btn-sm">Action 2</button>
</div>
```

---

## 🎨 CSS Variables

### Colors
```css
--background: 0 0% 100%;
--foreground: 240 10% 3.9%;
--card: 0 0% 100%;
--border: 240 5.9% 90%;
--input: 240 5.9% 90%;
--primary: 240 5.9% 10%;
--muted: 240 4.8% 95.9%;
--accent: 240 4.8% 95.9%;
--ring: 240 5.9% 10%;
```

### Dark Mode
```css
.dark-mode {
  --background: 240 10% 3.9%;
  --foreground: 0 0% 98%;
  --card: 240 10% 3.9%;
  --border: 240 3.7% 15.9%;
  --input: 240 3.7% 15.9%;
  --primary: 0 0% 98%;
  --muted: 240 3.7% 15.9%;
  --accent: 240 3.7% 15.9%;
  --ring: 240 4.9% 83.9%;
}
```

### Usage
```css
background: hsl(var(--background));
color: hsl(var(--foreground));
border: 1px solid hsl(var(--border));
```

---

## 📱 iOS Specific

### Prevent Zoom on Input Focus
```css
input, select, textarea {
  font-size: 16px; /* minimum pour éviter zoom iOS */
}
```

### Safe Areas
```css
.navbar {
  padding-top: env(safe-area-inset-top);
}

.mobile-bottom-nav {
  padding-bottom: env(safe-area-inset-bottom);
}
```

### Smooth Scrolling
```css
body {
  -webkit-overflow-scrolling: touch;
}
```

### Tap Highlight
```css
* {
  -webkit-tap-highlight-color: transparent;
}
```

---

## 🤖 Android Specific

### Viewport Height Fix
```javascript
const vh = window.innerHeight * 0.01;
document.documentElement.style.setProperty('--vh', `${vh}px`);

window.addEventListener('resize', () => {
  const vh = window.innerHeight * 0.01;
  document.documentElement.style.setProperty('--vh', `${vh}px`);
});
```

```css
.full-height {
  height: calc(var(--vh, 1vh) * 100);
}
```

---

## ♿ Accessibility

### Focus Visible
```css
*:focus-visible {
  outline: 2px solid hsl(var(--ring));
  outline-offset: 2px;
}
```

### Skip to Content
```html
<a href="#main-content" class="skip-to-content">
  Aller au contenu principal
</a>
```

```css
.skip-to-content {
  position: absolute;
  left: -9999px;
  top: 0;
}

.skip-to-content:focus {
  left: 0;
  z-index: 9999;
  padding: 1rem;
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
}
```

---

## 🚀 Performance

### Will Change
```css
.sidebar {
  will-change: transform;
}

.sidebar.open {
  transform: translateX(0);
}
```

### GPU Acceleration
```css
.animated-element {
  transform: translateZ(0);
}
```

### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 🎯 Common Patterns

### Responsive Grid
```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

@media (max-width: 768px) {
  .grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
}
```

### Responsive Flexbox
```css
.flex-container {
  display: flex;
  gap: 1rem;
}

@media (max-width: 768px) {
  .flex-container {
    flex-direction: column;
  }
}
```

### Responsive Text
```css
h1 {
  font-size: clamp(1.375rem, 2vw + 1rem, 1.875rem);
}
```

### Responsive Spacing
```css
.section {
  padding: clamp(1rem, 3vw, 2rem);
}
```

---

## 🔧 Debug Tips

### Show Breakpoint
```html
<div class="debug-breakpoint"></div>
```

```css
.debug-breakpoint::after {
  content: 'Desktop Large';
  position: fixed;
  bottom: 10px;
  right: 10px;
  background: black;
  color: white;
  padding: 0.5rem;
  z-index: 9999;
}

@media (max-width: 1919px) {
  .debug-breakpoint::after {
    content: 'Desktop';
  }
}

@media (max-width: 1439px) {
  .debug-breakpoint::after {
    content: 'Laptop';
  }
}

@media (max-width: 1024px) {
  .debug-breakpoint::after {
    content: 'Tablet';
  }
}

@media (max-width: 768px) {
  .debug-breakpoint::after {
    content: 'Mobile';
  }
}
```

---

## 📱 Device Emulation

### Chrome DevTools
```
Cmd/Ctrl + Shift + M - Toggle device toolbar
Cmd/Ctrl + Shift + P → "Show device frame"
```

### Common Presets
- iPhone 14 Pro (390x844)
- iPhone SE (375x667)
- iPad Air (820x1180)
- Galaxy S20 (360x800)

---

## ✅ Quick Checklist

```
Desktop:
✅ Hover states
✅ Sidebar visible
✅ Grid multi-column
✅ Adequate spacing

Tablet:
✅ Touch targets 44px+
✅ Sidebar adapté
✅ Grid 2 colonnes
✅ Bottom nav (portrait)

Mobile:
✅ Touch targets 48px
✅ Bottom nav visible
✅ Sidebar overlay
✅ Grid 1 colonne
✅ Full-width buttons
✅ Safe areas respected

General:
✅ Dark mode works
✅ Accessible
✅ Performant
✅ No horizontal scroll
```

---

**Design System:** shadcn-inspired  
**Mobile-First:** Bottom-up approach  
**Touch-Optimized:** 44-48px targets  
**Accessible:** WCAG 2.1 AA

