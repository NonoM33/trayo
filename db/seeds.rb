puts "Cleaning database..."
Trade.destroy_all
Mt5Account.destroy_all
User.destroy_all

puts "Creating test user..."
user = User.create!(
  email: "demo@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Demo",
  last_name: "User"
)

puts "User created: #{user.email}"
puts "User ID: #{user.id}"

puts "\nYou can use this user to test the API:"
puts "Email: demo@example.com"
puts "Password: password123"
puts "\nTo create an MT5 account, use the sync endpoint with user_id: #{user.id}"
