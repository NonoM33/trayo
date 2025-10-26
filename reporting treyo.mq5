//+------------------------------------------------------------------+
//|                                                reporting treyo.mq5 |
//|                                     Script de reporting MT5       |
//+------------------------------------------------------------------+
#property copyright "Trayo"
#property version   "1.00"

input string API_URL = "https://treyo.omrender.com/api/v1/mt5/sync";
input string API_COMPLETE_HISTORY_URL = "https://treyo.omrender.com/api/v1/mt5/sync_complete_history";
input string API_KEY = "mt5_secret_key_change_in_production";
input string MT5_API_TOKEN = "your_mt5_api_token_here";
input string CLIENT_EMAIL = "client@example.com";
input int REFRESH_INTERVAL = 300;
input bool INIT_COMPLETE_HISTORY = true;

datetime last_sync_time = 0;

//+------------------------------------------------------------------+
//| Script initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("Trayo Reporting Script Started");
   Print("========================================");
   Print("API URL: ", API_URL);
   Print("Refresh Interval: ", REFRESH_INTERVAL, " seconds");
   Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("========================================");
   
   EventSetTimer(REFRESH_INTERVAL);
   
   if(INIT_COMPLETE_HISTORY)
   {
      Print("Initializing complete history synchronization...");
      SyncCompleteHistory();
   }
   else
   {
      SyncDataToAPI();
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Script deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   Print("========================================");
   Print("Trayo Reporting Script Stopped");
   Print("Reason: ", reason);
   Print("========================================");
}

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
   SyncDataToAPI();
}

//+------------------------------------------------------------------+
//| Sync data to API                                                 |
//+------------------------------------------------------------------+
void SyncDataToAPI()
{
   string account_name = AccountInfoString(ACCOUNT_NAME);
   long account_number = AccountInfoInteger(ACCOUNT_LOGIN);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   Print("------------------------------------------------");
   Print("Starting synchronization...");
   Print("Account: ", account_number, " - ", account_name);
   Print("Balance: ", balance, " | Equity: ", equity);
   
   string trades_json = GetTradesJSON();
   
   string json = StringFormat(
      "{\"mt5_data\":{\"mt5_id\":\"%d\",\"mt5_api_token\":\"%s\",\"account_name\":\"%s\",\"client_email\":\"%s\",\"balance\":%.2f,\"trades\":%s}}",
      account_number,
      MT5_API_TOKEN,
      account_name,
      CLIENT_EMAIL,
      balance,
      trades_json
   );
   
   char post_data[];
   char result_data[];
   string result_headers;
   
   StringToCharArray(json, post_data, 0, StringLen(json));
   
   string headers = "Content-Type: application/json\r\n";
   headers += "X-API-Key: " + API_KEY + "\r\n";
   
   int timeout = 5000;
   int res = WebRequest(
      "POST",
      API_URL,
      headers,
      timeout,
      post_data,
      result_data,
      result_headers
   );
   
   if(res == 200)
   {
      string response = CharArrayToString(result_data);
      Print("[SUCCESS] Data synchronized at ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
      Print("Server response: ", response);
      last_sync_time = TimeCurrent();
      
      // Check if complete history sync is required
      if(StringFind(response, "init_required") >= 0 && StringFind(response, "true") >= 0)
      {
         Print("================================================");
         Print("SERVER REQUIRES COMPLETE HISTORY SYNC");
         Print("Response: ", response);
         Print("Starting complete history synchronization...");
         Print("================================================");
         SyncCompleteHistory();
         return; // Exit early to avoid duplicate sync
      }
   }
   else if(res == -1)
   {
      int error = GetLastError();
      Print("[ERROR] WebRequest failed with error: ", error);
      Print("Solution: Add URL to Tools -> Options -> Expert Advisors -> Allow WebRequest");
      Print("URL to add: ", API_URL);
   }
   else
   {
      string response = CharArrayToString(result_data);
      Print("[ERROR] HTTP ", res);
      Print("Response: ", response);
   }
   
   Print("Next sync in ", REFRESH_INTERVAL, " seconds");
   Print("------------------------------------------------");
}

//+------------------------------------------------------------------+
//| Sync complete history to API                                    |
//+------------------------------------------------------------------+
void SyncCompleteHistory()
{
   string account_name = AccountInfoString(ACCOUNT_NAME);
   long account_number = AccountInfoInteger(ACCOUNT_LOGIN);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);
   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   
   Print("================================================");
   Print("Starting COMPLETE HISTORY synchronization...");
   Print("Account: ", account_number, " - ", account_name);
   Print("Balance: ", balance, " | Equity: ", equity);
   Print("================================================");
   
   // Get all historical data
   string all_trades_json = GetAllTradesJSON();
   string all_withdrawals_json = GetAllWithdrawalsJSON();
   string all_deposits_json = GetAllDepositsJSON();
   
   // Debug: Print what we found
   Print("=== SYNC DATA SUMMARY ===");
   Print("Trades JSON length: ", StringLen(all_trades_json));
   Print("Withdrawals JSON length: ", StringLen(all_withdrawals_json));
   Print("Deposits JSON length: ", StringLen(all_deposits_json));
   Print("Withdrawals data: ", all_withdrawals_json);
   Print("Deposits data: ", all_deposits_json);
   Print("=== END SYNC DATA SUMMARY ===");
   
   // Build complete JSON payload
   string json = StringFormat(
      "{\"mt5_data\":{\"mt5_id\":\"%d\",\"mt5_api_token\":\"%s\",\"account_name\":\"%s\",\"client_email\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"margin\":%.2f,\"free_margin\":%.2f,\"trades\":%s,\"withdrawals\":%s,\"deposits\":%s}}",
      account_number,
      MT5_API_TOKEN,
      account_name,
      CLIENT_EMAIL,
      balance,
      equity,
      margin,
      free_margin,
      all_trades_json,
      all_withdrawals_json,
      all_deposits_json
   );
   
   char post_data[];
   char result_data[];
   string result_headers;
   
   StringToCharArray(json, post_data, 0, StringLen(json));
   
   string headers = "Content-Type: application/json\r\n";
   headers += "X-API-Key: " + API_KEY + "\r\n";
   
   int timeout = 30000;  // 30 seconds timeout for complete history
   int res = WebRequest(
      "POST",
      API_COMPLETE_HISTORY_URL,
      headers,
      timeout,
      post_data,
      result_data,
      result_headers
   );
   
   if(res == 200)
   {
      string response = CharArrayToString(result_data);
      Print("[SUCCESS] Complete history synchronized at ", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS));
      Print("Server response: ", response);
      last_sync_time = TimeCurrent();
      
      // Parse response to show sync results
      Print("================================================");
      Print("COMPLETE HISTORY SYNC COMPLETED SUCCESSFULLY");
      Print("Response: ", response);
      Print("================================================");
   }
   else if(res == -1)
   {
      int error = GetLastError();
      Print("[ERROR] WebRequest failed with error: ", error);
      Print("Solution: Add URL to Tools -> Options -> Expert Advisors -> Allow WebRequest");
      Print("URL to add: ", API_COMPLETE_HISTORY_URL);
   }
   else
   {
      string response = CharArrayToString(result_data);
      Print("[ERROR] HTTP ", res);
      Print("Response: ", response);
   }
   
   Print("================================================");
}

//+------------------------------------------------------------------+
//| Get all trades history as JSON                                    |
//+------------------------------------------------------------------+
string GetAllTradesJSON()
{
   // Get ALL trades from account history (not just last 24h)
   datetime from_time = D'2020.01.01 00:00:00';  // Start from 2020
   datetime to_time = TimeCurrent();
   
   Print("=== TRADES DEBUG ===");
   Print("Searching trades from: ", TimeToString(from_time), " to: ", TimeToString(to_time));
   
   HistorySelect(from_time, to_time);
   
   int total_deals = HistoryDealsTotal();
   
   Print("Total deals found: ", total_deals);
   
   if(total_deals == 0)
   {
      Print("No trades found in complete history");
      Print("=== END TRADES DEBUG ===");
      return "[]";
   }
   
   string trades = "[";
   int count = 0;
   
   for(int i = 0; i < total_deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         long deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);
         
         if(deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL)
         {
            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            double volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
            double price = HistoryDealGetDouble(ticket, DEAL_PRICE);
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
            datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            long position_id = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
            long magic_number = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
            
            string type_str = (deal_type == DEAL_TYPE_BUY) ? "buy" : "sell";
            
            string time_iso = TimeToString(deal_time, TIME_DATE|TIME_SECONDS);
            StringReplace(time_iso, ".", "-");
            StringReplace(time_iso, " ", "T");
            time_iso += "Z";
            
            if(count > 0) trades += ",";
            
            trades += StringFormat(
               "{\"trade_id\":\"%d\",\"symbol\":\"%s\",\"trade_type\":\"%s\",\"volume\":%.2f,\"open_price\":%.5f,\"close_price\":%.5f,\"profit\":%.2f,\"commission\":%.2f,\"swap\":%.2f,\"open_time\":\"%s\",\"close_time\":\"%s\",\"magic_number\":%d,\"comment\":\"%s\",\"status\":\"closed\"}",
               position_id,
               symbol,
               type_str,
               volume,
               price,
               price,
               profit,
               commission,
               swap,
               time_iso,
               time_iso,
               magic_number,
               comment
            );
            
            count++;
         }
      }
   }
   
   trades += "]";
   
   Print("Prepared ", count, " trades for complete sync");
   Print("=== END TRADES DEBUG ===");
   
   return trades;
}

//+------------------------------------------------------------------+
//| Get all withdrawals history as JSON                              |
//+------------------------------------------------------------------+
string GetAllWithdrawalsJSON()
{
   datetime from_time = D'2020.01.01 00:00:00';  // Start from 2020
   datetime to_time = TimeCurrent();
   HistorySelect(from_time, to_time);
   
   int total_deals = HistoryDealsTotal();
   
   Print("=== WITHDRAWALS DEBUG ===");
   Print("Total deals found: ", total_deals);
   Print("Searching from: ", TimeToString(from_time), " to: ", TimeToString(to_time));
   
   if(total_deals == 0)
   {
      Print("No deals found in complete history");
      return "[]";
   }
   
   string withdrawals = "[";
   int count = 0;
   int balance_deals = 0;
   
   for(int i = 0; i < total_deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         long deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);
         long deal_entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         double amount = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
         
         // Debug: Print all deal types found
         if(i < 10) // Only print first 10 for debug
         {
            Print("Deal ", i, ": Type=", deal_type, " Entry=", deal_entry, " Amount=", amount, " Comment=", comment);
         }
         
         // Check if it's a balance transaction
         if(deal_type == DEAL_TYPE_BALANCE)
         {
            balance_deals++;
            
            // Check if it's a withdrawal (negative amount or OUT entry)
            if(deal_entry == DEAL_ENTRY_OUT || amount < 0)
            {
               string time_iso = TimeToString(deal_time, TIME_DATE|TIME_SECONDS);
               StringReplace(time_iso, ".", "-");
               StringReplace(time_iso, " ", "T");
               time_iso += "Z";
               
               if(count > 0) withdrawals += ",";
               
               withdrawals += StringFormat(
                  "{\"transaction_id\":\"%d\",\"amount\":%.2f,\"transaction_date\":\"%s\",\"description\":\"%s\"}",
                  ticket,
                  MathAbs(amount),  // Positive amount for API
                  time_iso,
                  comment
               );
               
               count++;
               Print("Found withdrawal: Ticket=", ticket, " Amount=", MathAbs(amount), " Date=", time_iso);
            }
         }
      }
   }
   
   withdrawals += "]";
   
   Print("Total balance deals found: ", balance_deals);
   Print("Prepared ", count, " withdrawals for complete sync");
   Print("=== END WITHDRAWALS DEBUG ===");
   
   return withdrawals;
}

//+------------------------------------------------------------------+
//| Get all deposits history as JSON                                 |
//+------------------------------------------------------------------+
string GetAllDepositsJSON()
{
   datetime from_time = D'2020.01.01 00:00:00';  // Start from 2020
   datetime to_time = TimeCurrent();
   HistorySelect(from_time, to_time);
   
   int total_deals = HistoryDealsTotal();
   
   Print("=== DEPOSITS DEBUG ===");
   Print("Total deals found: ", total_deals);
   Print("Searching from: ", TimeToString(from_time), " to: ", TimeToString(to_time));
   
   if(total_deals == 0)
   {
      Print("No deals found in complete history");
      return "[]";
   }
   
   string deposits = "[";
   int count = 0;
   int balance_deals = 0;
   
   for(int i = 0; i < total_deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         long deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);
         long deal_entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         double amount = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
         
         // Check if it's a balance transaction
         if(deal_type == DEAL_TYPE_BALANCE)
         {
            balance_deals++;
            
            // Check if it's a deposit (positive amount or IN entry)
            if(deal_entry == DEAL_ENTRY_IN || amount > 0)
            {
               string time_iso = TimeToString(deal_time, TIME_DATE|TIME_SECONDS);
               StringReplace(time_iso, ".", "-");
               StringReplace(time_iso, " ", "T");
               time_iso += "Z";
               
               if(count > 0) deposits += ",";
               
               deposits += StringFormat(
                  "{\"transaction_id\":\"%d\",\"amount\":%.2f,\"transaction_date\":\"%s\",\"description\":\"%s\"}",
                  ticket,
                  MathAbs(amount),  // Positive amount for API
                  time_iso,
                  comment
               );
               
               count++;
               Print("Found deposit: Ticket=", ticket, " Amount=", MathAbs(amount), " Date=", time_iso);
            }
         }
      }
   }
   
   deposits += "]";
   
   Print("Total balance deals found: ", balance_deals);
   Print("Prepared ", count, " deposits for complete sync");
   Print("=== END DEPOSITS DEBUG ===");
   
   return deposits;
}

//+------------------------------------------------------------------+
//| Get trades as JSON (recent only)                                 |
//+------------------------------------------------------------------+
string GetTradesJSON()
{
   datetime from_time = TimeCurrent() - 86400;
   HistorySelect(from_time, TimeCurrent());
   
   int total_deals = HistoryDealsTotal();
   
   if(total_deals == 0)
   {
      Print("No trades found in the last 24 hours");
      return "[]";
   }
   
   Print("Found ", total_deals, " deals in history");
   
   string trades = "[";
   int count = 0;
   
   for(int i = 0; i < total_deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
      {
         long deal_type = HistoryDealGetInteger(ticket, DEAL_TYPE);
         
         if(deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL)
         {
            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            double volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
            double price = HistoryDealGetDouble(ticket, DEAL_PRICE);
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
            datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            long position_id = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
            long magic_number = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
            
            string type_str = (deal_type == DEAL_TYPE_BUY) ? "buy" : "sell";
            
            string time_iso = TimeToString(deal_time, TIME_DATE|TIME_SECONDS);
            StringReplace(time_iso, ".", "-");
            StringReplace(time_iso, " ", "T");
            time_iso += "Z";
            
            if(count > 0) trades += ",";
            
            trades += StringFormat(
               "{\"trade_id\":\"%d\",\"symbol\":\"%s\",\"trade_type\":\"%s\",\"volume\":%.2f,\"open_price\":%.5f,\"close_price\":%.5f,\"profit\":%.2f,\"commission\":%.2f,\"swap\":%.2f,\"open_time\":\"%s\",\"close_time\":\"%s\",\"magic_number\":%d,\"comment\":\"%s\",\"status\":\"closed\"}",
               position_id,
               symbol,
               type_str,
               volume,
               price,
               price,
               profit,
               commission,
               swap,
               time_iso,
               time_iso,
               magic_number,
               comment
            );
            
            count++;
         }
      }
   }
   
   trades += "]";
   
   Print("Prepared ", count, " trades for sync");
   
   return trades;
}

//+------------------------------------------------------------------+
//| Script tick function (optional)                                  |
//+------------------------------------------------------------------+
void OnTick()
{
   // Rien à faire sur chaque tick
   // La synchronisation se fait uniquement via le timer
}
//+------------------------------------------------------------------+