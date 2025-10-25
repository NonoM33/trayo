#!/usr/bin/env python3
"""
Example MT5 Script for Data Synchronization
This script should be adapted to work with MetaTrader 5 API
"""

import requests
import json
from datetime import datetime, timedelta
import time
import logging
import sys

API_URL = "http://localhost:3000/api/v1/mt5/sync"
API_COMPLETE_HISTORY_URL = "http://localhost:3000/api/v1/mt5/sync_complete_history"
API_KEY = "mt5_secret_key_change_in_production"
MT5_API_TOKEN = "your_mt5_api_token_here"
MT5_ACCOUNT_ID = "12345678"
REFRESH_INTERVAL = 300

def setup_logging():
    """
    Setup logging configuration
    """
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('mt5_sync.log'),
            logging.StreamHandler(sys.stdout)
        ]
    )

def get_mt5_account_info():
    """
    This function should be implemented to fetch real data from MT5
    Using MetaTrader5 package: pip install MetaTrader5
    """
    try:
        # Real implementation would use MetaTrader5 package
        # import MetaTrader5 as mt5
        # 
        # if not mt5.initialize():
        #     logging.error("MT5 initialization failed")
        #     return None
        # 
        # account_info = mt5.account_info()
        # if account_info is None:
        #     logging.error("Failed to get account info")
        #     mt5.shutdown()
        #     return None
        # 
        # result = {
        #     "account_name": account_info.name,
        #     "balance": account_info.balance,
        #     "equity": account_info.equity,
        #     "margin": account_info.margin,
        #     "free_margin": account_info.margin_free
        # }
        # 
        # mt5.shutdown()
        # return result
        
        # Demo data for testing
        return {
            "account_name": "Demo Account",
            "balance": 10000.50,
            "equity": 10000.50,
            "margin": 0.0,
            "free_margin": 10000.50
        }
    except Exception as e:
        logging.error(f"Error getting MT5 account info: {str(e)}")
        return None

def get_all_trades_history():
    """
    This function should fetch ALL trades from MT5 history
    Returns a list of all trades with magic numbers
    """
    trades = []
    
    # Real implementation example:
    # import MetaTrader5 as mt5
    # 
    # if not mt5.initialize():
    #     logging.error("MT5 initialization failed")
    #     return []
    # 
    # # Get ALL trades from account history
    # from_date = datetime(2020, 1, 1)  # Start from beginning
    # to_date = datetime.now()
    # 
    # deals = mt5.history_deals_get(from_date, to_date)
    # 
    # if deals is not None:
    #     for deal in deals:
    #         if deal.entry == mt5.DEAL_ENTRY_OUT:  # Only closed trades
    #             trade = {
    #                 "ticket": deal.ticket,
    #                 "symbol": deal.symbol,
    #                 "type": deal.type,
    #                 "volume": deal.volume,
    #                 "price_open": deal.price_open,
    #                 "price_close": deal.price,
    #                 "profit": deal.profit,
    #                 "commission": deal.commission,
    #                 "swap": deal.swap,
    #                 "time": deal.time,
    #                 "time_done": deal.time,
    #                 "state": 2,  # closed
    #                 "magic": deal.magic,
    #                 "comment": deal.comment
    #             }
    #             trades.append(trade)
    # 
    # mt5.shutdown()
    
    return trades

def get_all_withdrawals_history():
    """
    This function should fetch ALL withdrawal transactions from MT5 history
    Returns a list of all withdrawal transactions
    """
    withdrawals = []
    
    # Real implementation example:
    # import MetaTrader5 as mt5
    # 
    # if not mt5.initialize():
    #     logging.error("MT5 initialization failed")
    #     return []
    # 
    # # Get ALL withdrawal transactions from account history
    # from_date = datetime(2020, 1, 1)  # Start from beginning
    # to_date = datetime.now()
    # 
    # deals = mt5.history_deals_get(from_date, to_date)
    # 
    # if deals is not None:
    #     for deal in deals:
    #         # Check if it's a withdrawal transaction
    #         if deal.type == mt5.DEAL_TYPE_BALANCE and deal.entry == mt5.DEAL_ENTRY_OUT:
    #             withdrawal = {
    #                 "ticket": deal.ticket,
    #                 "amount": abs(deal.profit),  # Positive amount for API
    #                 "time": deal.time,
    #                 "comment": deal.comment or "MT5 Withdrawal"
    #             }
    #             withdrawals.append(withdrawal)
    # 
    # mt5.shutdown()
    
    return withdrawals

def get_all_deposits_history():
    """
    This function should fetch ALL deposit transactions from MT5 history
    Returns a list of all deposit transactions
    """
    deposits = []
    
    # Real implementation example:
    # import MetaTrader5 as mt5
    # 
    # if not mt5.initialize():
    #     logging.error("MT5 initialization failed")
    #     return []
    # 
    # # Get ALL deposit transactions from account history
    # from_date = datetime(2020, 1, 1)  # Start from beginning
    # to_date = datetime.now()
    # 
    # deals = mt5.history_deals_get(from_date, to_date)
    # 
    # if deals is not None:
    #     for deal in deals:
    #         # Check if it's a deposit transaction
    #         if deal.type == mt5.DEAL_TYPE_BALANCE and deal.entry == mt5.DEAL_ENTRY_IN:
    #             deposit = {
    #                 "ticket": deal.ticket,
    #                 "amount": abs(deal.profit),  # Positive amount for API
    #                 "time": deal.time,
    #                 "comment": deal.comment or "MT5 Deposit"
    #             }
    #             deposits.append(deposit)
    # 
    # mt5.shutdown()
    
    return deposits

def format_trade_for_api(mt5_trade):
    """
    Format MT5 trade object to match API requirements
    """
    try:
        # Handle None values safely
        trade_id = mt5_trade.get("ticket")
        if trade_id is None:
            trade_id = mt5_trade.get("position_id", "unknown")
        
        # Handle timestamps safely
        open_time = mt5_trade.get("time")
        close_time = mt5_trade.get("time_done")
        
        if open_time:
            open_time_str = datetime.fromtimestamp(open_time).isoformat()
        else:
            open_time_str = datetime.now().isoformat()
            
        if close_time:
            close_time_str = datetime.fromtimestamp(close_time).isoformat()
        else:
            close_time_str = datetime.now().isoformat()
        
        return {
            "trade_id": str(trade_id),
            "symbol": mt5_trade.get("symbol", "UNKNOWN"),
            "trade_type": "buy" if mt5_trade.get("type") == 0 else "sell",
            "volume": mt5_trade.get("volume", 0.0),
            "open_price": mt5_trade.get("price_open", 0.0),
            "close_price": mt5_trade.get("price_close", 0.0),
            "profit": mt5_trade.get("profit", 0.0),
            "commission": mt5_trade.get("commission", 0.0),
            "swap": mt5_trade.get("swap", 0.0),
            "open_time": open_time_str,
            "close_time": close_time_str,
            "status": "closed" if mt5_trade.get("state") == 2 else "open",
            "magic_number": mt5_trade.get("magic", 0),
            "comment": mt5_trade.get("comment", "")
        }
    except Exception as e:
        logging.error(f"Error formatting trade for API: {str(e)}")
        return None

def format_withdrawal_for_api(mt5_withdrawal):
    """
    Format MT5 withdrawal object to match API requirements
    """
    try:
        amount = mt5_withdrawal.get("amount", 0.0)
        if amount is None:
            amount = 0.0
            
        time_stamp = mt5_withdrawal.get("time")
        if time_stamp:
            transaction_date = datetime.fromtimestamp(time_stamp).isoformat()
        else:
            transaction_date = datetime.now().isoformat()
            
        return {
            "transaction_id": str(mt5_withdrawal.get("ticket", "unknown")),
            "amount": abs(float(amount)),  # Positive amount for API
            "transaction_date": transaction_date,
            "description": mt5_withdrawal.get("comment", "MT5 Withdrawal")
        }
    except Exception as e:
        logging.error(f"Error formatting withdrawal for API: {str(e)}")
        return None

def get_recent_trades():
    """
    This function should fetch trades from the last 24 hours from MT5
    Returns a list of recent trades
    """
    trades = []
    
    # Real implementation would fetch recent trades only
    return trades

def get_recent_withdrawals():
    """
    This function should fetch recent withdrawal transactions from MT5
    Returns a list of recent withdrawal transactions
    """
    withdrawals = []
    
    # Real implementation would fetch recent withdrawals only
    return withdrawals

def get_recent_deposits():
    """
    This function should fetch recent deposit transactions from MT5
    Returns a list of recent deposit transactions
    """
    deposits = []
    
    # Real implementation would fetch recent deposits only
    return deposits

def format_deposit_for_api(mt5_deposit):
    """
    Format MT5 deposit object to match API requirements
    """
    try:
        amount = mt5_deposit.get("amount", 0.0)
        if amount is None:
            amount = 0.0
            
        time_stamp = mt5_deposit.get("time")
        if time_stamp:
            transaction_date = datetime.fromtimestamp(time_stamp).isoformat()
        else:
            transaction_date = datetime.now().isoformat()
            
        return {
            "transaction_id": str(mt5_deposit.get("ticket", "unknown")),
            "amount": abs(float(amount)),  # Positive amount for API
            "transaction_date": transaction_date,
            "description": mt5_deposit.get("comment", "MT5 Deposit")
        }
    except Exception as e:
        logging.error(f"Error formatting deposit for API: {str(e)}")
        return None

def sync_data_to_api():
    """
    Send MT5 data to the Rails API
    """
    try:
        account_info = get_mt5_account_info()
        if account_info is None:
            logging.error("Failed to get account info")
            return False
        
        # First, check if complete history sync is required
        payload = {
            "mt5_data": {
                "mt5_id": MT5_ACCOUNT_ID,
                "mt5_api_token": MT5_API_TOKEN,
                "account_name": account_info["account_name"],
                "balance": account_info["balance"]
            }
        }
        
        headers = {
            "X-API-Key": API_KEY,
            "Content-Type": "application/json"
        }
        
        # Check if initialization is required
        response = requests.post(API_URL, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            
            if response_data.get("init_required"):
                logging.info("Complete history synchronization required")
                return sync_complete_history()
            else:
                logging.info("Regular synchronization")
                return sync_regular_data()
                
        else:
            logging.error(f"API Error: {response.status_code}")
            try:
                error_data = response.json()
                logging.error(f"Error details: {error_data}")
            except:
                logging.error(f"Error response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        logging.error(f"Connection error: {str(e)}")
        return False
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        return False

def sync_complete_history():
    """
    Send complete MT5 history to the Rails API
    """
    try:
        account_info = get_mt5_account_info()
        if account_info is None:
            logging.error("Failed to get account info")
            return False
            
        all_trades = get_all_trades_history()
        all_withdrawals = get_all_withdrawals_history()
        all_deposits = get_all_deposits_history()
        
        # Filter out None values from formatting
        formatted_trades = [format_trade_for_api(trade) for trade in all_trades if format_trade_for_api(trade) is not None]
        formatted_withdrawals = [format_withdrawal_for_api(withdrawal) for withdrawal in all_withdrawals if format_withdrawal_for_api(withdrawal) is not None]
        formatted_deposits = [format_deposit_for_api(deposit) for deposit in all_deposits if format_deposit_for_api(deposit) is not None]
        
        payload = {
            "mt5_data": {
                "mt5_id": MT5_ACCOUNT_ID,
                "mt5_api_token": MT5_API_TOKEN,
                "account_name": account_info["account_name"],
                "balance": account_info["balance"],
                "equity": account_info["equity"],
                "margin": account_info["margin"],
                "free_margin": account_info["free_margin"],
                "trades": formatted_trades,
                "withdrawals": formatted_withdrawals,
                "deposits": formatted_deposits
            }
        }
        
        headers = {
            "X-API-Key": API_KEY,
            "Content-Type": "application/json"
        }
        
        response = requests.post(API_COMPLETE_HISTORY_URL, json=payload, headers=headers, timeout=60)
        
        if response.status_code == 200:
            response_data = response.json()
            logging.info("Complete history synchronized successfully")
            logging.info(f"Trades synced: {response_data.get('trades_synced', 0)}")
            logging.info(f"Withdrawals synced: {response_data.get('withdrawals_synced', 0)}")
            logging.info(f"Deposits synced: {response_data.get('deposits_synced', 0)}")
            logging.info(f"Calculated initial balance: {response_data.get('mt5_account', {}).get('calculated_initial_balance', 'N/A')}")
            return True
        else:
            logging.error(f"API Error: {response.status_code}")
            try:
                error_data = response.json()
                logging.error(f"Error details: {error_data}")
            except:
                logging.error(f"Error response: {response.text}")
            return False
    except Exception as e:
        logging.error(f"Connection error: {str(e)}")
        return False

def sync_regular_data():
    """
    Send recent MT5 data to the Rails API (regular sync)
    """
    try:
        account_info = get_mt5_account_info()
        if account_info is None:
            logging.error("Failed to get account info")
            return False
            
        recent_trades = get_recent_trades()
        recent_withdrawals = get_recent_withdrawals()
        recent_deposits = get_recent_deposits()
        
        # Filter out None values from formatting
        formatted_trades = [format_trade_for_api(trade) for trade in recent_trades if format_trade_for_api(trade) is not None]
        formatted_withdrawals = [format_withdrawal_for_api(withdrawal) for withdrawal in recent_withdrawals if format_withdrawal_for_api(withdrawal) is not None]
        formatted_deposits = [format_deposit_for_api(deposit) for deposit in recent_deposits if format_deposit_for_api(deposit) is not None]
        
        payload = {
            "mt5_data": {
                "mt5_id": MT5_ACCOUNT_ID,
                "mt5_api_token": MT5_API_TOKEN,
                "account_name": account_info["account_name"],
                "balance": account_info["balance"],
                "equity": account_info["equity"],
                "margin": account_info["margin"],
                "free_margin": account_info["free_margin"],
                "trades": formatted_trades,
                "withdrawals": formatted_withdrawals,
                "deposits": formatted_deposits
            }
        }
        
        headers = {
            "X-API-Key": API_KEY,
            "Content-Type": "application/json"
        }
        
        response = requests.post(API_URL, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            logging.info("Data synchronized successfully")
            logging.info(f"Trades synced: {response_data.get('trades_synced', 0)}")
            logging.info(f"Withdrawals synced: {response_data.get('withdrawals_synced', 0)}")
            logging.info(f"Deposits synced: {response_data.get('deposits_synced', 0)}")
            return True
        else:
            logging.error(f"API Error: {response.status_code}")
            try:
                error_data = response.json()
                logging.error(f"Error details: {error_data}")
            except:
                logging.error(f"Error response: {response.text}")
            return False
    except Exception as e:
        logging.error(f"Connection error: {str(e)}")
        return False

def main():
    """
    Main loop - sync data every REFRESH_INTERVAL seconds
    """
    setup_logging()
    
    logging.info("MT5 Sync Script Started")
    logging.info(f"API URL: {API_URL}")
    logging.info(f"MT5 Account ID: {MT5_ACCOUNT_ID}")
    logging.info(f"Refresh Interval: {REFRESH_INTERVAL} seconds")
    logging.info("-" * 50)
    
    consecutive_errors = 0
    max_consecutive_errors = 5
    
    while True:
        try:
            success = sync_data_to_api()
            if success:
                consecutive_errors = 0
            else:
                consecutive_errors += 1
                if consecutive_errors >= max_consecutive_errors:
                    logging.error(f"Too many consecutive errors ({max_consecutive_errors}). Stopping script.")
                    break
            
            time.sleep(REFRESH_INTERVAL)
            
        except KeyboardInterrupt:
            logging.info("Script stopped by user")
            break
        except Exception as e:
            logging.error(f"Unexpected error in main loop: {str(e)}")
            consecutive_errors += 1
            if consecutive_errors >= max_consecutive_errors:
                logging.error(f"Too many consecutive errors ({max_consecutive_errors}). Stopping script.")
                break
            time.sleep(REFRESH_INTERVAL)

if __name__ == "__main__":
    main()