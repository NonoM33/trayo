#!/usr/bin/env ruby

# Script simple pour créer un utilisateur de test
require 'sqlite3'

# Chemin vers la base de données SQLite
db_path = File.join(__dir__, 'db', 'development.sqlite3')

if File.exist?(db_path)
  db = SQLite3::Database.new(db_path)
  
  # Vérifier si l'utilisateur existe déjà
  existing = db.execute("SELECT id FROM users WHERE mt5_api_token = ?", "test_token_123")
  
  if existing.empty?
    # Créer l'utilisateur de test
    db.execute("INSERT INTO users (email, encrypted_password, first_name, last_name, commission_rate, is_admin, mt5_api_token, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
               "test@trayo.com", 
               "$2a$12$test", # Mot de passe crypté factice
               "Test", 
               "User", 
               0, 
               false, 
               "test_token_123",
               Time.current.to_s,
               Time.current.to_s)
    
    puts "✓ Utilisateur de test créé avec succès"
    puts "✓ Email: test@trayo.com"
    puts "✓ Token MT5: test_token_123"
  else
    puts "Utilisateur de test existe déjà"
  end
  
  db.close
else
  puts "Base de données SQLite non trouvée à: #{db_path}"
end
