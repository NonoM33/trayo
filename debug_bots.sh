#!/bin/bash

echo "🔍 DIAGNOSTIC COMPLET DES BOTS"
echo "=============================="

cd /Users/renaud.cosson-ext/trayo

echo ""
echo "📊 1. Vérification des utilisateurs clients:"
sqlite3 db/development.sqlite3 "
SELECT 
  id, email, first_name, last_name, is_admin 
FROM users 
WHERE is_admin = 0 
ORDER BY email;
"

echo ""
echo "📊 2. Vérification des bot_purchases:"
sqlite3 db/development.sqlite3 "
SELECT 
  bp.id,
  bp.user_id,
  bp.trading_bot_id,
  bp.status,
  bp.purchase_type,
  u.email,
  tb.name as bot_name
FROM bot_purchases bp 
JOIN users u ON u.id = bp.user_id 
JOIN trading_bots tb ON tb.id = bp.trading_bot_id 
ORDER BY u.email;
"

echo ""
echo "📊 3. Vérification des trading_bots:"
sqlite3 db/development.sqlite3 "
SELECT id, name, magic_number_prefix, price FROM trading_bots;
"

echo ""
echo "📊 4. Vérification des trades par utilisateur:"
sqlite3 db/development.sqlite3 "
SELECT 
  u.email,
  COUNT(t.id) as trade_count,
  GROUP_CONCAT(DISTINCT t.magic_number) as magic_numbers
FROM users u 
LEFT JOIN mt5_accounts m ON m.user_id = u.id 
LEFT JOIN trades t ON t.mt5_account_id = m.id 
WHERE u.is_admin = 0
GROUP BY u.id, u.email
ORDER BY u.email;
"

echo ""
echo "📊 5. Test de la relation User -> BotPurchases:"
sqlite3 db/development.sqlite3 "
-- Simuler la requête Rails: SELECT * FROM bot_purchases WHERE user_id = X
SELECT 
  'client@trayo.com' as email,
  COUNT(*) as bot_purchases_count
FROM bot_purchases bp 
JOIN users u ON u.id = bp.user_id 
WHERE u.email = 'client@trayo.com'

UNION ALL

SELECT 
  'cosson@trayo.com' as email,
  COUNT(*) as bot_purchases_count
FROM bot_purchases bp 
JOIN users u ON u.id = bp.user_id 
WHERE u.email = 'cosson@trayo.com'

UNION ALL

SELECT 
  'renaudlemagicien@gmail.com' as email,
  COUNT(*) as bot_purchases_count
FROM bot_purchases bp 
JOIN users u ON u.id = bp.user_id 
WHERE u.email = 'renaudlemagicien@gmail.com';
"

echo ""
echo "✅ Diagnostic terminé !"
echo "Consultez les logs Rails pour voir les détails du contrôleur."
