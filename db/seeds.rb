puts "Checking existing data..."

puts "Checking admin user..."
admin = User.find_by(email: "admin@trayo.com")
if admin
  puts "Admin user already exists: #{admin.email}"
else
  admin = User.create!(
    email: "admin@trayo.com",
    password: "admin123",
    password_confirmation: "admin123",
    first_name: "Admin",
    last_name: "Trayo",
    commission_rate: 0,
    is_admin: true,
    mt5_api_token: SecureRandom.hex(32)
  )
  puts "✓ Admin created: #{admin.email}"
end

puts "Checking test client..."
client = User.find_by(email: "renaudlemagicien@gmail.com")
if client
  puts "Test client already exists: #{client.email}"
else
  client = User.create!(
    email: "renaudlemagicien@gmail.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Renaud",
    last_name: "Cosson",
    phone: "+33612345678",
    commission_rate: 25.0,
    is_admin: false,
    mt5_api_token: SecureRandom.hex(32)
  )
  puts "✓ Client created: #{client.email}"
end

puts "Checking MT5 account for test client..."
mt5_account = client.mt5_accounts.find_by(mt5_id: 319138)
if mt5_account
  puts "MT5 account already exists: #{mt5_account.account_name}"
else
  mt5_account = client.mt5_accounts.create!(
    mt5_id: 319138,
    account_name: "Cosson Renaud 001",
    balance: 1837.62,
    initial_balance: 1700.00,
    high_watermark: 1700.00,
    total_withdrawals: 0.0
  )
  puts "✓ MT5 account created: #{mt5_account.account_name}"
end

if mt5_account.trades.empty?
  puts "Creating sample trades..."
  [
    { symbol: "EURUSD", profit: 45.23, close_time: 10.days.ago },
    { symbol: "GBPUSD", profit: 32.15, close_time: 8.days.ago },
    { symbol: "USDJPY", profit: -18.40, close_time: 6.days.ago },
    { symbol: "AUDUSD", profit: 67.89, close_time: 4.days.ago },
    { symbol: "EURJPY", profit: 10.75, close_time: 2.days.ago }
  ].each do |trade_data|
    mt5_account.trades.create!(
      mt5_ticket: rand(1000000..9999999),
      symbol: trade_data[:symbol],
      volume: 0.1,
      open_price: 1.1000,
      close_price: 1.1050,
      profit: trade_data[:profit],
      open_time: trade_data[:close_time] - 2.hours,
      close_time: trade_data[:close_time],
      trade_type: "buy"
    )
  end
  puts "✓ Sample trades created"
else
  puts "Sample trades already exist (#{mt5_account.trades.count} trades)"
end

puts "Checking trading bots..."
bots_data = [
  {
    name: "Alpha Trader Pro",
    description: "Bot de scalping haute fréquence optimisé pour EUR/USD",
    price: 499.00,
    status: "active",
    is_active: true,
    risk_level: "medium",
    projection_monthly_min: 500.00,
    projection_monthly_max: 1500.00,
    projection_yearly: 12000.00,
    win_rate: 75.5,
    max_drawdown_limit: 500.00,
    strategy_description: "Alpha Trader Pro utilise des algorithmes avancés de machine learning pour détecter les opportunités de scalping sur EUR/USD. Le bot effectue 30-80 trades par jour avec un stop-loss serré de 5 pips et un take-profit dynamique.\n\nStratégie basée sur l'analyse de microstructure de marché et l'identification de zones de liquidité. Performance optimale durant les sessions de Londres et New York.",
    features: ["Trading automatique 24/7", "Stop-loss automatique", "Gestion dynamique du risque", "Analyse en temps réel", "Notifications par email"]
  },
  {
    name: "Trend Master Elite",
    description: "Suiveur de tendance long terme pour tous les marchés",
    price: 899.00,
    status: "active",
    is_active: true,
    risk_level: "low",
    projection_monthly_min: 800.00,
    projection_monthly_max: 2000.00,
    projection_yearly: 18000.00,
    win_rate: 82.3,
    max_drawdown_limit: 800.00,
    strategy_description: "Trend Master Elite identifie et suit les tendances majeures sur plusieurs paires de devises. Utilise des moyennes mobiles exponentielles combinées à l'ADX et des filtres de volatilité.\n\nLe bot entre en position uniquement lors de tendances confirmées et utilise un trailing stop progressif pour maximiser les gains. Idéal pour les comptes de 5000€ et plus.",
    features: ["Multi-paires de devises", "Trailing stop intelligent", "Filtres de volatilité avancés", "Ratio risque/rendement 1:3", "Backtesting sur 10 ans"]
  },
  {
    name: "Grid Master Pro",
    description: "Système de grille adaptatif pour marchés en range",
    price: 699.00,
    status: "active",
    is_active: true,
    risk_level: "medium",
    projection_monthly_min: 600.00,
    projection_monthly_max: 1800.00,
    projection_yearly: 14400.00,
    win_rate: 88.7,
    max_drawdown_limit: 1000.00,
    strategy_description: "Grid Master Pro place des ordres d'achat et de vente à intervalles réguliers autour du prix actuel. Chaque grille est adaptative en fonction de la volatilité du marché.\n\nParfait pour les marchés en consolidation. Le système ajuste automatiquement la taille des lots et les niveaux de grille selon les conditions de marché. Sécurité maximale avec stop-loss global.",
    features: ["Grille adaptative", "Gestion automatique des lots", "Stop-loss global", "Optimisé pour marchés range", "Tableau de bord détaillé"]
  },
  {
    name: "News Hunter X",
    description: "Expert en trading de nouvelles économiques",
    price: 1299.00,
    status: "active",
    is_active: true,
    risk_level: "high",
    projection_monthly_min: 1000.00,
    projection_monthly_max: 3500.00,
    projection_yearly: 30000.00,
    win_rate: 71.2,
    max_drawdown_limit: 1500.00,
    strategy_description: "News Hunter X analyse et trade automatiquement les annonces économiques majeures (NFP, CPI, Fed, BCE, etc). Execution en quelques millisecondes avec serveurs VPS optimisés.\n\nLe bot positionne des ordres pending avant l'annonce et les déclenche selon la déviation par rapport aux prévisions. Stratégie agressive mais très rentable pour traders expérimentés.",
    features: ["Réaction en millisecondes", "Calendrier économique intégré", "Positions pré-calculées", "Risk management avancé", "Support VPS recommandé"]
  }
]

bots_created = 0
bots_data.each do |bot_data|
  unless TradingBot.exists?(name: bot_data[:name])
    TradingBot.create!(bot_data)
    bots_created += 1
  end
end

if bots_created > 0
  puts "✓ #{bots_created} trading bot(s) created"
else
  puts "Trading bots already exist (#{TradingBot.count} bots)"
end

puts "\n" + "="*60
puts "✓ Seeding completed successfully!"
puts "="*60
puts "\n📊 Database Summary:"
puts "  • Users: #{User.count} (#{User.admins.count} admins, #{User.clients.count} clients)"
puts "  • MT5 Accounts: #{Mt5Account.count}"
puts "  • Trades: #{Trade.count}"
puts "  • Trading Bots: #{TradingBot.count}"
puts "  • Payments: #{Payment.count}"
puts "  • Credits: #{Credit.count}"
puts "  • Bonus Deposits: #{BonusDeposit.count}"
puts "\n🔑 Login credentials:"
puts "  Admin: admin@trayo.com / admin123"
puts "  Client: renaudlemagicien@gmail.com / password123"
puts "="*60
