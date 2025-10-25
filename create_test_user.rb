#!/usr/bin/env ruby

# Script pour créer un utilisateur de test MT5
require_relative 'config/environment'

puts "Création de l'utilisateur de test MT5..."

# Vérifier si l'utilisateur existe déjà
existing_user = User.find_by(mt5_api_token: "test_token_123")
if existing_user
  puts "Utilisateur de test existe déjà: #{existing_user.email}"
else
  # Créer l'utilisateur de test
  test_user = User.create!(
    email: "test@trayo.com",
    password: "test123",
    password_confirmation: "test123",
    first_name: "Test",
    last_name: "User",
    commission_rate: 0,
    is_admin: false,
    mt5_api_token: "test_token_123"
  )
  puts "✓ Utilisateur de test créé: #{test_user.email}"
  puts "✓ Token MT5: #{test_user.mt5_api_token}"
end

puts "Script terminé."
