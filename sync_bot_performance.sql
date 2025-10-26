-- Script pour synchroniser les performances des bots avec les trades
-- Ce script met à jour les statistiques des bot_purchases basées sur les trades réels

-- 1. Vérifier les trades disponibles pour chaque utilisateur
SELECT 
  u.email,
  u.id as user_id,
  COUNT(t.id) as trade_count,
  SUM(t.profit) as total_profit,
  GROUP_CONCAT(DISTINCT t.magic_number) as magic_numbers
FROM users u 
LEFT JOIN mt5_accounts m ON m.user_id = u.id 
LEFT JOIN trades t ON t.mt5_account_id = m.id 
WHERE u.is_admin = 0
GROUP BY u.id, u.email
ORDER BY u.email;

-- 2. Mettre à jour les performances des bot_purchases
UPDATE bot_purchases 
SET 
  total_profit = (
    SELECT COALESCE(SUM(t.profit), 0)
    FROM trades t 
    JOIN mt5_accounts m ON m.id = t.mt5_account_id 
    JOIN users u ON u.id = m.user_id 
    WHERE u.id = bot_purchases.user_id 
    AND t.magic_number = (
      SELECT tb.magic_number_prefix 
      FROM trading_bots tb 
      WHERE tb.id = bot_purchases.trading_bot_id
    )
  ),
  trades_count = (
    SELECT COUNT(t.id)
    FROM trades t 
    JOIN mt5_accounts m ON m.id = t.mt5_account_id 
    JOIN users u ON u.id = m.user_id 
    WHERE u.id = bot_purchases.user_id 
    AND t.magic_number = (
      SELECT tb.magic_number_prefix 
      FROM trading_bots tb 
      WHERE tb.id = bot_purchases.trading_bot_id
    )
  )
WHERE EXISTS (
  SELECT 1 
  FROM trades t 
  JOIN mt5_accounts m ON m.id = t.mt5_account_id 
  JOIN users u ON u.id = m.user_id 
  WHERE u.id = bot_purchases.user_id 
  AND t.magic_number = (
    SELECT tb.magic_number_prefix 
    FROM trading_bots tb 
    WHERE tb.id = bot_purchases.trading_bot_id
  )
);

-- 3. Vérifier les résultats
SELECT 
  bp.id,
  u.email,
  tb.name as bot_name,
  bp.total_profit,
  bp.trades_count,
  bp.purchase_type
FROM bot_purchases bp 
JOIN users u ON u.id = bp.user_id 
JOIN trading_bots tb ON tb.id = bp.trading_bot_id 
ORDER BY u.email, tb.name;
