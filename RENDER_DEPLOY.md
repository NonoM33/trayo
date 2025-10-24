# 🚀 Guide de Déploiement sur Render

## 📋 Prérequis

1. Compte [Render.com](https://render.com)
2. Repository Git configuré
3. Variables d'environnement prêtes

---

## 🔧 Configuration Render

### 1. **Créer une PostgreSQL Database**

1. Dans Render Dashboard → **New** → **PostgreSQL**
2. Nom: `trayo-db`
3. Database: `trayo_production`
4. User: (généré automatiquement)
5. Region: Choisir la plus proche
6. Plan: Starter ($7/mois) ou Free

**Important** : Copier l'**Internal Database URL** (commence par `postgresql://`)

---

### 2. **Créer le Web Service**

1. Dans Render Dashboard → **New** → **Web Service**
2. Connecter votre repository Git
3. Configuration :
   - **Name**: `trayo`
   - **Region**: Même que la DB
   - **Branch**: `main`
   - **Root Directory**: (vide)
   - **Runtime**: `Ruby`
   - **Build Command**:
     ```bash
     bundle install && bundle exec rake assets:precompile && bundle exec rake db:migrate
     ```
   - **Start Command**:
     ```bash
     bundle exec puma -C config/puma.rb -p ${PORT:-3000}
     ```
   - **Plan**: Starter ($7/mois) ou Free

---

### 3. **Variables d'Environnement**

Dans **Environment** → **Environment Variables**, ajouter :

| Variable                   | Valeur                                               |
| -------------------------- | ---------------------------------------------------- |
| `RAILS_MASTER_KEY`         | `547c55260f3b3204b988263597052558`                   |
| `RAILS_ENV`                | `production`                                         |
| `DATABASE_URL`             | (Copier l'Internal Database URL de votre PostgreSQL) |
| `WEB_CONCURRENCY`          | `2`                                                  |
| `RAILS_MAX_THREADS`        | `5`                                                  |
| `MT5_API_KEY`              | `mt5_secret_key_change_in_production`                |
| `RAILS_LOG_TO_STDOUT`      | `true`                                               |
| `RAILS_SERVE_STATIC_FILES` | `true`                                               |
| `MAINTENANCE_DISABLED`     | `true`                                               |

**Note** : `DATABASE_URL` doit ressembler à :

```
postgresql://user:password@dpg-xxxxx-a.oregon-postgres.render.com/trayo_production
```

---

### 4. **Build & Deploy**

1. Cliquer sur **Create Web Service**
2. Render va automatiquement :
   - Installer les gems
   - Compiler les assets
   - Exécuter les migrations
   - Démarrer l'application

**Temps estimé** : 5-10 minutes

---

## 🎯 Post-Déploiement

### 1. **Créer le premier utilisateur admin**

Dans **Shell** (dans le dashboard Render) :

```bash
bundle exec rails console
```

Puis dans la console Rails :

```ruby
User.create!(
  email: 'admin@trayo.com',
  password: 'ChangeMe123!',
  password_confirmation: 'ChangeMe123!',
  is_admin: true,
  commission_rate: 10.0
)
```

### 2. **Vérifier l'application**

Visiter : `https://your-app-name.onrender.com`

---

## 📊 Configuration Avancée

### Health Check

Render vérifie automatiquement `/up` (défini dans `routes.rb`)

### Auto-Deploy

Les pushs sur la branche `main` déclenchent automatiquement un déploiement.

### Custom Domain

1. **Settings** → **Custom Domain**
2. Ajouter votre domaine
3. Configurer DNS :
   - Type: `CNAME`
   - Name: `@` ou `www`
   - Value: `your-app-name.onrender.com`

---

## 🔐 Sécurité

### Changer la Master Key

Si vous voulez générer une nouvelle master key :

```bash
bundle exec rails credentials:edit
```

Copier la nouvelle clé dans Render.

### Changer le MT5 API Key

Dans Render → Environment Variables → `MT5_API_KEY`

---

## 🐛 Debugging

### Voir les logs

Dans Render Dashboard → **Logs**

### Console Rails

Dans Render Dashboard → **Shell** :

```bash
bundle exec rails console
```

### Exécuter une migration manuellement

Dans **Shell** :

```bash
bundle exec rails db:migrate
```

---

## 💰 Coûts Estimés

| Service     | Plan    | Prix/mois |
| ----------- | ------- | --------- |
| PostgreSQL  | Starter | $7        |
| Web Service | Starter | $7        |
| **Total**   |         | **$14**   |

**Alternative gratuite** :

- PostgreSQL Free (limitations : 1 GB, expire après 90 jours)
- Web Service Free (limitations : 750h/mois, spin down après inactivité)

---

## 📝 Checklist de Déploiement

- [ ] PostgreSQL créée
- [ ] Variables d'environnement configurées
- [ ] Build Command configuré
- [ ] Start Command configuré
- [ ] Déploiement réussi
- [ ] Migrations exécutées
- [ ] Admin user créé
- [ ] Login testé
- [ ] MT5 Sync testé

---

## 🔄 Workflow de Déploiement

1. **Développement Local**

   ```bash
   git add .
   git commit -m "Feature: nouvelle fonctionnalité"
   git push origin main
   ```

2. **Render Auto-Deploy**

   - Détecte le push
   - Lance le build
   - Exécute les migrations
   - Redémarre l'app

3. **Vérification**
   - Consulter les logs
   - Tester les nouvelles fonctionnalités

---

## 🆘 Support

- [Documentation Render](https://render.com/docs)
- [Documentation Rails](https://guides.rubyonrails.org/)
- [Forum Render Community](https://community.render.com/)

---

**Dernière mise à jour** : 23 octobre 2025
