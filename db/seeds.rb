puts "Cleaning database..."
Credit.destroy_all
Payment.destroy_all
Withdrawal.destroy_all
Trade.destroy_all
Mt5Account.destroy_all
User.destroy_all

puts "Creating admin user..."
admin = User.create!(
  email: "admin@trayo.com",
  password: "admin123",
  password_confirmation: "admin123",
  first_name: "Admin",
  last_name: "Trayo",
  is_admin: true,
  commission_rate: 0
)

puts "Admin created: #{admin.email}"
puts "Password: admin123"

puts "\nCreating test client..."
client = User.create!(
  email: "client1@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "John",
  last_name: "Doe",
  is_admin: false,
  commission_rate: 20.0
)

puts "Client created: #{client.email}"
puts "Commission rate: #{client.commission_rate}%"

puts "\nCreating MT5 account for client..."
mt5_account = Mt5Account.create!(
  user: client,
  mt5_id: "12345678",
  account_name: "Demo Account",
  balance: 10000.0,
  initial_balance: 10000.0,
  high_watermark: 0.0,
  total_withdrawals: 0.0
)

puts "MT5 Account created: #{mt5_account.mt5_id}"
puts "Client MT5 API Token: #{client.mt5_api_token}"

puts "\n" + "="*60
puts "ADMIN ACCESS:"
puts "URL: http://localhost:3000/admin/login"
puts "Email: admin@trayo.com"
puts "Password: admin123"
puts "="*60

puts "\nAPI TEST:"
puts "Email: client1@example.com"
puts "Password: password123"
puts "MT5 API Token: #{client.mt5_api_token}"
