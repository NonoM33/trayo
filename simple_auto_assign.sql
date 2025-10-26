-- Script SQL simple pour détecter et assigner automatiquement les bots
-- Version compatible SQLite

-- 1. Identifier les utilisateurs qui ont des trades avec des magic numbers
-- mais pas de bots assignés correspondants

-- D'abord, afficher les utilisateurs qui ont des trades mais pas de bots
SELECT 
  u.email,
  COUNT(DISTINCT t.magic_number) as magic_numbers_count,
  GROUP_CONCAT(DISTINCT t.magic_number) as magic_numbers,
  COUNT(bp.id) as assigned_bots_count
FROM users u
JOIN mt5_accounts m ON m.user_id = u.id
JOIN trades t ON t.mt5_account_id = m.id
LEFT JOIN bot_purchases bp ON bp.user_id = u.id
WHERE t.magic_number IS NOT NULL
GROUP BY u.id, u.email
HAVING assigned_bots_count = 0;

-- 2. Pour chaque magic number détecté, vérifier s'il y a un bot correspondant
-- et s'il n'est pas déjà assigné

-- Exemple pour client@trayo.com avec magic number 0
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
)
SELECT 
  u.id,
  tb.id,
  tb.price,
  'active',
  0,
  1,
  0.0,
  0.0,
  0.0,
  0,
  'auto_detected',
  datetime('now'),
  datetime('now')
FROM users u, trading_bots tb
WHERE u.email = 'client@trayo.com'
AND tb.magic_number_prefix = 0
AND NOT EXISTS (
  SELECT 1 FROM bot_purchases bp 
  WHERE bp.user_id = u.id 
  AND bp.trading_bot_id = tb.id
);

-- 3. Vérifier le résultat
SELECT 
  u.email,
  tb.name as bot_name,
  bp.purchase_type,
  bp.created_at
FROM users u
JOIN bot_purchases bp ON bp.user_id = u.id
JOIN trading_bots tb ON tb.id = bp.trading_bot_id
WHERE u.email = 'client@trayo.com';
