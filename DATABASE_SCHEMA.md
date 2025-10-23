# Schéma de Base de Données

## Vue d'ensemble

Le système utilise PostgreSQL avec 3 tables principales :

- `users` - Utilisateurs de l'application
- `mt5_accounts` - Comptes MetaTrader 5
- `trades` - Trades effectués sur les comptes MT5

## Relations

```
User (1) ----< (N) Mt5Account (1) ----< (N) Trade
```

Un utilisateur peut avoir plusieurs comptes MT5, et chaque compte MT5 peut avoir plusieurs trades.

## Tables

### users

| Colonne         | Type     | Contraintes      | Description                 |
| --------------- | -------- | ---------------- | --------------------------- |
| id              | bigint   | PRIMARY KEY      | Identifiant unique          |
| email           | string   | NOT NULL, UNIQUE | Email de l'utilisateur      |
| password_digest | string   | NOT NULL         | Mot de passe hashé (bcrypt) |
| first_name      | string   | -                | Prénom                      |
| last_name       | string   | -                | Nom de famille              |
| created_at      | datetime | NOT NULL         | Date de création            |
| updated_at      | datetime | NOT NULL         | Date de mise à jour         |

**Index :**

- `index_users_on_email` (unique)

**Validations :**

- Email : présence, format email valide, unicité
- Password : minimum 6 caractères

---

### mt5_accounts

| Colonne      | Type          | Contraintes           | Description              |
| ------------ | ------------- | --------------------- | ------------------------ |
| id           | bigint        | PRIMARY KEY           | Identifiant unique       |
| user_id      | bigint        | NOT NULL, FOREIGN KEY | Référence vers users.id  |
| mt5_id       | string        | NOT NULL, UNIQUE      | ID du compte MT5         |
| account_name | string        | NOT NULL              | Nom du compte            |
| balance      | decimal(15,2) | DEFAULT 0.0           | Solde actuel             |
| last_sync_at | datetime      | -                     | Dernière synchronisation |
| created_at   | datetime      | NOT NULL              | Date de création         |
| updated_at   | datetime      | NOT NULL              | Date de mise à jour      |

**Index :**

- `index_mt5_accounts_on_user_id`
- `index_mt5_accounts_on_mt5_id` (unique)
- `index_mt5_accounts_on_user_id_and_mt5_id` (unique)

**Relations :**

- `belongs_to :user`
- `has_many :trades, dependent: :destroy`

**Validations :**

- mt5_id : présence, unicité
- account_name : présence
- balance : présence, numericité

**Contraintes :**

- Foreign key vers users (ON DELETE CASCADE)
- Un compte MT5 ne peut être associé qu'à un seul utilisateur

---

### trades

| Colonne        | Type          | Contraintes           | Description                    |
| -------------- | ------------- | --------------------- | ------------------------------ |
| id             | bigint        | PRIMARY KEY           | Identifiant unique             |
| mt5_account_id | bigint        | NOT NULL, FOREIGN KEY | Référence vers mt5_accounts.id |
| trade_id       | string        | NOT NULL              | ID du trade MT5                |
| symbol         | string        | -                     | Paire de devises (ex: EURUSD)  |
| trade_type     | string        | -                     | Type : buy ou sell             |
| volume         | decimal(15,5) | -                     | Volume du trade                |
| open_price     | decimal(15,5) | -                     | Prix d'ouverture               |
| close_price    | decimal(15,5) | -                     | Prix de clôture                |
| profit         | decimal(15,2) | -                     | Profit/Perte                   |
| commission     | decimal(15,2) | -                     | Commission                     |
| swap           | decimal(15,2) | -                     | Frais de swap                  |
| open_time      | datetime      | -                     | Date d'ouverture               |
| close_time     | datetime      | -                     | Date de clôture                |
| status         | string        | -                     | Statut : open ou closed        |
| created_at     | datetime      | NOT NULL              | Date de création               |
| updated_at     | datetime      | NOT NULL              | Date de mise à jour            |

**Index :**

- `index_trades_on_mt5_account_id`
- `index_trades_on_mt5_account_id_and_trade_id` (unique)
- `index_trades_on_close_time`
- `index_trades_on_open_time`

**Relations :**

- `belongs_to :mt5_account`

**Validations :**

- trade_id : présence, unicité dans le scope du compte MT5

**Contraintes :**

- Foreign key vers mt5_accounts (ON DELETE CASCADE)
- Unicité de (mt5_account_id, trade_id) pour éviter les doublons

---

## Exemples de requêtes SQL

### Récupérer tous les comptes d'un utilisateur avec leur solde total

```sql
SELECT u.email, COUNT(m.id) as accounts_count, SUM(m.balance) as total_balance
FROM users u
LEFT JOIN mt5_accounts m ON m.user_id = u.id
WHERE u.id = 1
GROUP BY u.id, u.email;
```

### Récupérer les 20 derniers trades d'un utilisateur

```sql
SELECT t.*, m.account_name, m.mt5_id
FROM trades t
INNER JOIN mt5_accounts m ON t.mt5_account_id = m.id
WHERE m.user_id = 1
ORDER BY t.close_time DESC
LIMIT 20;
```

### Calculer le profit total des 24 dernières heures

```sql
SELECT SUM(t.profit) as total_profit
FROM trades t
INNER JOIN mt5_accounts m ON t.mt5_account_id = m.id
WHERE m.user_id = 1
  AND t.close_time >= NOW() - INTERVAL '24 hours'
  AND t.status = 'closed';
```

### Calculer la moyenne de profit quotidien sur 30 jours

```sql
SELECT AVG(daily_profit) as avg_daily_profit
FROM (
  SELECT DATE(t.close_time) as trade_date, SUM(t.profit) as daily_profit
  FROM trades t
  INNER JOIN mt5_accounts m ON t.mt5_account_id = m.id
  WHERE m.user_id = 1
    AND t.close_time >= NOW() - INTERVAL '30 days'
    AND t.status = 'closed'
  GROUP BY DATE(t.close_time)
) daily_profits;
```

### Compter les jours de trading actifs

```sql
SELECT COUNT(DISTINCT DATE(t.close_time)) as active_trading_days
FROM trades t
INNER JOIN mt5_accounts m ON t.mt5_account_id = m.id
WHERE m.user_id = 1
  AND t.close_time >= NOW() - INTERVAL '30 days';
```

## Performances

### Index recommandés

Les index suivants sont déjà créés pour optimiser les performances :

1. **users.email** - Pour l'authentification
2. **mt5_accounts.mt5_id** - Pour la recherche rapide lors de la synchronisation
3. **mt5_accounts.user_id** - Pour les jointures
4. **trades.mt5_account_id** - Pour les jointures
5. **trades.close_time** - Pour les requêtes de date (projection)
6. **trades.open_time** - Pour les filtres de date
7. **trades (mt5_account_id, trade_id)** - Pour éviter les doublons

### Considérations pour le scaling

- Partitioning de la table `trades` par date si le volume devient important (>1M trades)
- Archivage des trades anciens (>1 an) dans une table séparée
- Mise en cache des projections si calculées fréquemment
- Utilisation de vues matérialisées pour les statistiques complexes

## Maintenance

### Nettoyage des anciennes données

```sql
-- Supprimer les trades de plus d'un an
DELETE FROM trades WHERE close_time < NOW() - INTERVAL '1 year';
```

### Réindexation

```bash
bin/rails db:migrate:status
bin/rails db:migrate
```

### Backup

```bash
pg_dump -U postgres trayo_development > backup.sql
```

### Restore

```bash
psql -U postgres trayo_development < backup.sql
```
