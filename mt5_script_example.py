#!/usr/bin/env python3
"""
Example MT5 Script for Data Synchronization
This script should be adapted to work with MetaTrader 5 API
"""

import requests
import json
from datetime import datetime, timedelta
import time

API_URL = "http://localhost:3000/api/v1/mt5/sync"
API_KEY = "mt5_secret_key_change_in_production"
MT5_API_TOKEN = "your_mt5_api_token_here"
MT5_ACCOUNT_ID = "12345678"
REFRESH_INTERVAL = 300

def get_mt5_account_info():
    """
    This function should be implemented to fetch real data from MT5
    Using MetaTrader5 package: pip install MetaTrader5
    """
    return {
        "account_name": "Demo Account",
        "balance": 10000.50
    }

def get_recent_trades():
    """
    This function should fetch trades from the last 24 hours from MT5
    Returns a list of trades
    """
    trades = []
    
    return trades

def format_trade_for_api(mt5_trade):
    """
    Format MT5 trade object to match API requirements
    """
    return {
        "trade_id": str(mt5_trade.get("ticket")),
        "symbol": mt5_trade.get("symbol"),
        "trade_type": "buy" if mt5_trade.get("type") == 0 else "sell",
        "volume": mt5_trade.get("volume"),
        "open_price": mt5_trade.get("price_open"),
        "close_price": mt5_trade.get("price_close"),
        "profit": mt5_trade.get("profit"),
        "commission": mt5_trade.get("commission"),
        "swap": mt5_trade.get("swap"),
        "open_time": datetime.fromtimestamp(mt5_trade.get("time")).isoformat(),
        "close_time": datetime.fromtimestamp(mt5_trade.get("time_done")).isoformat(),
        "status": "closed" if mt5_trade.get("state") == 2 else "open"
    }

def sync_data_to_api():
    """
    Send MT5 data to the Rails API
    """
    account_info = get_mt5_account_info()
    recent_trades = get_recent_trades()
    
    formatted_trades = [format_trade_for_api(trade) for trade in recent_trades]
    
    payload = {
        "mt5_data": {
            "mt5_id": MT5_ACCOUNT_ID,
            "mt5_api_token": MT5_API_TOKEN,
            "account_name": account_info["account_name"],
            "balance": account_info["balance"],
            "trades": formatted_trades
        }
    }
    
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(API_URL, json=payload, headers=headers)
        
        if response.status_code == 200:
            print(f"[{datetime.now()}] Data synchronized successfully")
            print(f"Trades synced: {len(formatted_trades)}")
            return True
        else:
            print(f"[{datetime.now()}] Error: {response.status_code}")
            print(response.json())
            return False
    except Exception as e:
        print(f"[{datetime.now()}] Connection error: {str(e)}")
        return False

def main():
    """
    Main loop - sync data every REFRESH_INTERVAL seconds
    """
    print(f"MT5 Sync Script Started")
    print(f"API URL: {API_URL}")
    print(f"MT5 Account ID: {MT5_ACCOUNT_ID}")
    print(f"Refresh Interval: {REFRESH_INTERVAL} seconds")
    print("-" * 50)
    
    while True:
        sync_data_to_api()
        time.sleep(REFRESH_INTERVAL)

if __name__ == "__main__":
    main()

