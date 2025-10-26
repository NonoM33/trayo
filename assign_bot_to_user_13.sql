-- Script pour assigner le bot à l'utilisateur actuellement connecté
-- Ce script doit être exécuté après chaque connexion

-- 1. Créer l'utilisateur ID 13 s'il n'existe pas
INSERT OR IGNORE INTO users (
  id, email, first_name, last_name, password_digest, 
  is_admin, commission_rate, created_at, updated_at
) VALUES (
  13, 'renaudlemagicien@gmail.com', 'Renaud', 'Lemagicien', 
  '$2a$12$dummy', 0, 0, datetime('now'), datetime('now')
);

-- 2. Assigner le bot 'Or' à l'utilisateur ID 13
INSERT OR IGNORE INTO bot_purchases (
  user_id,
  trading_bot_id,
  price_paid,
  status,
  magic_number,
  is_running,
  current_drawdown,
  max_drawdown_recorded,
  total_profit,
  trades_count,
  purchase_type,
  created_at,
  updated_at
) VALUES (
  13, 1, 399.99, 'active', 0, 1, 0.0, 0.0, 0.0, 0, 'auto_detected', datetime('now'), datetime('now')
);

-- 3. Vérifier le résultat
SELECT 
  'Utilisateur créé/assigné' as action,
  u.id,
  u.email,
  COUNT(bp.id) as bot_count,
  GROUP_CONCAT(tb.name) as bot_names
FROM users u 
LEFT JOIN bot_purchases bp ON bp.user_id = u.id 
LEFT JOIN trading_bots tb ON tb.id = bp.trading_bot_id 
WHERE u.id = 13
GROUP BY u.id, u.email;
