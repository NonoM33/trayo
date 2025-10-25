#!/usr/bin/env ruby

# Script pour modifier le token MT5 d'un utilisateur existant
require 'net/http'
require 'uri'
require 'json'

# URL de l'API
url = URI('http://localhost:3000/admin/clients')

# Créer une requête GET pour lister les utilisateurs
http = Net::HTTP.new(url.host, url.port)
request = Net::HTTP::Get.new(url)

# Ajouter les headers nécessaires
request['Accept'] = 'application/json'
request['Content-Type'] = 'application/json'

# Faire la requête
response = http.request(request)

puts "Status: #{response.code}"
puts "Response: #{response.body}"

# Pour l'instant, créons un utilisateur de test avec un token fixe
# en utilisant l'interface web

puts "\nPour créer un utilisateur de test:"
puts "1. Allez sur http://localhost:3000/admin/login"
puts "2. Connectez-vous avec admin@trayo.com / admin123"
puts "3. Allez dans Clients > Nouveau client"
puts "4. Créez un utilisateur avec l'email test@trayo.com"
puts "5. Modifiez le token MT5 pour 'test_token_123'"
