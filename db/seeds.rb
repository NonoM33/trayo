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
    name: "Scalper Pro",
    description: "High-frequency scalping bot optimized for EUR/USD. Makes 20-50 trades per day with tight stop losses.",
    price: 299.99,
    bot_type: "Scalper",
    status: "active",
    features: { featured: true, risk_level: "Medium", timeframe: "M1-M5" }
  },
  {
    name: "Trend Master",
    description: "Long-term trend following strategy. Works on multiple currency pairs with advanced trend detection.",
    price: 499.99,
    bot_type: "Trend Following",
    status: "active",
    features: { featured: true, risk_level: "Low", timeframe: "H1-H4" }
  },
  {
    name: "Grid Trader Elite",
    description: "Advanced grid trading system with dynamic lot sizing and risk management. Perfect for ranging markets.",
    price: 399.99,
    bot_type: "Grid Trading",
    status: "active",
    features: { featured: false, risk_level: "Medium-High", timeframe: "H1" }
  },
  {
    name: "News Hunter",
    description: "Automated news trading bot that reacts to economic announcements with millisecond precision.",
    price: 599.99,
    bot_type: "News Trading",
    status: "active",
    features: { featured: true, risk_level: "High", timeframe: "M1" }
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
