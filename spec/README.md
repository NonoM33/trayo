# Tests RSpec - Trayo API

## Structure des Tests

```
spec/
├── factories/          # FactoryBot definitions
├── models/             # Tests modèles
├── controllers/        # Tests contrôleurs
│   └── api/
│       └── v2/         # Tests REST v2
├── graphql/            # Tests GraphQL
│   ├── queries/        # Tests queries
│   └── mutations/      # Tests mutations
├── channels/           # Tests WebSocket channels
├── concerns/           # Tests concerns
├── requests/           # Tests intégration
└── support/            # Helpers et configuration
```

## Configuration

### SimpleCov (Couverture)

Pour activer la couverture de code :

```bash
COVERAGE=true bundle exec rspec
```

Le rapport sera généré dans `coverage/` avec un seuil minimum de 95%.

### Database Cleaner

Les tests utilisent DatabaseCleaner pour nettoyer la base de données entre chaque test.

### FactoryBot

Toutes les factories sont dans `spec/factories/` :
- `users.rb`
- `mt5_accounts.rb`
- `trades.rb`
- `trading_bots.rb`
- `bot_purchases.rb`
- `vps.rb`
- `payments.rb`
- `credits.rb`
- `withdrawals.rb`
- `deposits.rb`

## Exécution des Tests

```bash
# Tous les tests
bundle exec rspec

# Avec couverture
COVERAGE=true bundle exec rspec

# Un fichier spécifique
bundle exec rspec spec/models/user_spec.rb

# Un test spécifique
bundle exec rspec spec/models/user_spec.rb:25

# Tests par tag
bundle exec rspec --tag focus
```

## Helpers Disponibles

### `json_response`
Parse et retourne la réponse JSON :
```ruby
json = json_response
expect(json['data']).to be_present
```

### `auth_headers(user)`
Retourne les headers d'authentification :
```ruby
get '/api/v2/accounts', headers: auth_headers(user)
```

### `graphql_query(query, variables: {}, context: {})`
Exécute une requête GraphQL :
```ruby
graphql_query(query, variables: { id: 1 }, context: { headers: auth_headers(user) })
```

## Objectif de Couverture

- **Minimum** : 95%
- **Groupes** :
  - Controllers : > 95%
  - Models : > 95%
  - GraphQL : > 95%
  - Channels : > 95%
  - Concerns : > 95%

## Tests à Implémenter

### Modèles (100%)
- [x] User
- [x] Mt5Account
- [x] Trade
- [ ] TradingBot
- [ ] BotPurchase
- [ ] Vps
- [ ] Payment
- [ ] Credit
- [ ] Withdrawal
- [ ] Deposit

### Contrôleurs REST v2 (100%)
- [x] AuthController
- [x] AccountsController
- [ ] TradesController
- [ ] BotsController
- [ ] BotPurchasesController
- [ ] VpsController
- [ ] PaymentsController
- [ ] CreditsController
- [ ] StatsController
- [ ] UsersController
- [ ] EventsController

### GraphQL (100%)
- [x] Queries (user, mt5Accounts, dashboard)
- [ ] Queries (trades, bots, stats, etc.)
- [x] Mutations (loginUser, registerUser, purchaseBot)
- [ ] Mutations (startBot, stopBot, updateProfile, etc.)
- [ ] Subscriptions

### Concerns (100%)
- [x] CursorPagination
- [ ] Filterable
- [ ] Searchable

### Channels (100%)
- [ ] AccountChannel
- [ ] TradeChannel
- [ ] BotChannel
- [ ] PaymentChannel

## Notes

- Utiliser `shoulda-matchers` pour les validations et associations
- Utiliser `factory_bot` pour créer les données de test
- Utiliser `faker` pour générer des données réalistes
- Tous les tests doivent être indépendants et isolés

