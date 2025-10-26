#!/bin/bash

# Script de surveillance automatique des bots
# Ce script peut être exécuté via cron pour détecter automatiquement les nouveaux bots

echo "🤖 Démarrage du worker de détection automatique des bots..."
echo "============================================================"

# Aller dans le répertoire du projet
cd /Users/renaud.cosson-ext/trayo

# Exécuter le script SQL de détection automatique
echo "🔍 Exécution de la détection automatique..."
sqlite3 db/development.sqlite3 < simple_auto_assign.sql

# Vérifier les résultats
echo ""
echo "📊 Vérification des résultats:"
sqlite3 db/development.sqlite3 "
SELECT 
  u.email,
  COUNT(bp.id) as bot_count,
  GROUP_CONCAT(tb.name) as bot_names
FROM users u 
LEFT JOIN bot_purchases bp ON bp.user_id = u.id 
LEFT JOIN trading_bots tb ON tb.id = bp.trading_bot_id 
WHERE u.email LIKE '%trayo%'
GROUP BY u.email
ORDER BY u.email;
"

echo ""
echo "✅ Worker terminé !"
echo "🕐 $(date)"
