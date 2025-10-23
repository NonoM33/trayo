# API Documentation

## Base URL

`http://localhost:3000/api/v1`

## Authentication

### Register

**POST** `/register`

**Body:**

```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

### Login

**POST** `/login`

**Body:**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

## MT5 Data Sync (For MT5 Script)

### Sync Data

**POST** `/mt5/sync`

**Headers:**

```
X-API-Key: your_mt5_api_key
```

**Body:**

```json
{
  "mt5_data": {
    "mt5_id": "12345678",
    "user_id": 1,
    "account_name": "Demo Account",
    "balance": 10000.5,
    "trades": [
      {
        "trade_id": "123456",
        "symbol": "EURUSD",
        "trade_type": "buy",
        "volume": 0.1,
        "open_price": 1.1234,
        "close_price": 1.125,
        "profit": 16.0,
        "commission": -0.5,
        "swap": 0.0,
        "open_time": "2025-10-23T10:00:00Z",
        "close_time": "2025-10-23T11:00:00Z",
        "status": "closed"
      }
    ]
  }
}
```

**Response:**

```json
{
  "message": "Data synchronized successfully",
  "mt5_account": {
    "id": 1,
    "mt5_id": "12345678",
    "account_name": "Demo Account",
    "balance": 10000.5,
    "last_sync_at": "2025-10-23T12:00:00Z"
  },
  "trades_synced": 1
}
```

## Client Endpoints (Require JWT Token)

All client endpoints require the `Authorization` header:

```
Authorization: Bearer your_jwt_token
```

### Get Balance

**GET** `/accounts/balance`

**Response:**

```json
{
  "accounts": [
    {
      "id": 1,
      "mt5_id": "12345678",
      "account_name": "Demo Account",
      "balance": 10000.5,
      "last_sync_at": "2025-10-23T12:00:00Z"
    }
  ],
  "total_balance": 10000.5
}
```

### Get Recent Trades

**GET** `/accounts/trades`

**Response:**

```json
{
  "trades": [
    {
      "id": 1,
      "trade_id": "123456",
      "account_name": "Demo Account",
      "symbol": "EURUSD",
      "trade_type": "buy",
      "volume": 0.1,
      "open_price": 1.1234,
      "close_price": 1.125,
      "profit": 16.0,
      "commission": -0.5,
      "swap": 0.0,
      "open_time": "2025-10-23T10:00:00Z",
      "close_time": "2025-10-23T11:00:00Z",
      "status": "closed"
    }
  ]
}
```

### Get Projection

**GET** `/accounts/projection?days=30`

**Query Parameters:**

- `days` (optional, default: 30): Number of days for projection

**Response:**

```json
{
  "projections": [
    {
      "account_id": 1,
      "mt5_id": "12345678",
      "account_name": "Demo Account",
      "current_balance": 10000.5,
      "projected_balance": 11500.75,
      "daily_average": 50.0,
      "projected_profit": 1500.0,
      "confidence": "high",
      "based_on_days": 25
    }
  ],
  "summary": {
    "total_current_balance": 10000.5,
    "total_projected_balance": 11500.75,
    "projected_difference": 1500.25,
    "projection_days": 30
  }
}
```

## Environment Variables

- `MT5_API_KEY`: API key for MT5 script authentication (default: "mt5_secret_key_change_in_production")
- `SECRET_KEY_BASE`: Rails secret key base for JWT encoding

## Database Setup

```bash
bin/rails db:create
bin/rails db:migrate
```

## Running the Server

```bash
bin/rails server
```

## Notes

- The projection algorithm calculates based on the last 30 days of trading activity
- Confidence levels:
  - "high": 20+ trading days in the last 30 days
  - "medium": 10-19 trading days
  - "low": Less than 10 trading days
- Trades are automatically deduplicated by `trade_id` within each MT5 account
- The MT5 sync endpoint can be called as frequently as needed - it will update existing records without creating duplicates
