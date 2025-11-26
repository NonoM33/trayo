//+------------------------------------------------------------------+
//|                                                reporting treyo.mq5 |
//|                                     Script de reporting MT5       |
//+------------------------------------------------------------------+
#property copyright "Trayo"
#property version   "1.00"

input string API_URL = "https://trayo.fr/api/v1/mt5/sync";
input string API_COMPLETE_HISTORY_URL = "https://trayo.fr/api/v1/mt5/sync_complete_history";
input string API_KEY = "mt5_secret_key_change_in_production";
input string MT5_API_TOKEN = "25eb820906140c0eea3eae64f465542137533e931239fc2af5757916e6cb032a";
input string CLIENT_EMAIL = "renaud@renaud.com";
input int REFRESH_INTERVAL = 10;
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
   
   string open_positions_json = GetOpenPositionsJSON();
   
   string active_experts_json = GetActiveExpertsJSON();
   
   string broker_name = AccountInfoString(ACCOUNT_COMPANY);
   string broker_server = AccountInfoString(ACCOUNT_SERVER);
   string broker_password = ""; // L'utilisateur devra le modifier manuellement
   
   string json = StringFormat(
      "{\"mt5_data\":{\"mt5_id\":\"%d\",\"mt5_api_token\":\"%s\",\"account_name\":\"%s\",\"client_email\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"broker_name\":\"%s\",\"broker_server\":\"%s\",\"trades\":%s,\"open_positions\":%s,\"active_experts\":%s}}",
      account_number,
      MT5_API_TOKEN,
      account_name,
      CLIENT_EMAIL,
      balance,
      equity,
      broker_name,
      broker_server,
      trades_json,
      open_positions_json,
      active_experts_json
   );
   
   char post_data[];
   char result_data[];
   string result_headers;
   
   StringToCharArray(json, post_data, 0, StringLen(json));
   
   string headers = "Content-Type: application/json\r\n";
   headers += "X-API-Key: " + API_KEY + "\r\n";
   
   int timeout = 30000;
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
   else if(res == 1001)
   {
      Print("[ERROR] HTTP 1001 - Protocol Error");
      Print("This usually means:");
      Print("1. Localhost URL requires HTTP (not HTTPS)");
      Print("2. The server is not responding");
      Print("3. SSL certificate issue if using HTTPS");
      Print("Try changing API_URL to: http://127.0.0.1:3000/api/v1/mt5/sync");
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
   string active_experts_json = GetActiveExpertsJSON();
   
   // Debug: Print what we found
   Print("=== SYNC DATA SUMMARY ===");
   Print("Trades JSON length: ", StringLen(all_trades_json));
   Print("Withdrawals JSON length: ", StringLen(all_withdrawals_json));
   Print("Deposits JSON length: ", StringLen(all_deposits_json));
   Print("Active Experts: ", active_experts_json);
   Print("=== END SYNC DATA SUMMARY ===");
   
   // Build complete JSON payload
   string json = StringFormat(
      "{\"mt5_data\":{\"mt5_id\":\"%d\",\"mt5_api_token\":\"%s\",\"account_name\":\"%s\",\"client_email\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"margin\":%.2f,\"free_margin\":%.2f,\"trades\":%s,\"withdrawals\":%s,\"deposits\":%s,\"active_experts\":%s}}",
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
      all_deposits_json,
      active_experts_json
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
   Print("=== TRADES DEBUG ===");
   Print("Searching ALL positions from beginning of history");
   
   // Sélectionner tout l'historique depuis le début (0) jusqu'à maintenant
   if(!HistorySelect(0, TimeCurrent()))
   {
      Print("Failed to select history");
      Print("=== END TRADES DEBUG ===");
      return "[]";
   }
   
   int total_deals = HistoryDealsTotal();
   
   if(total_deals == 0)
   {
      Print("No deals found in complete history");
      Print("=== END TRADES DEBUG ===");
      return "[]";
   }
   
   Print("Total deals found: ", total_deals);
   
   // DEBUG: Compter les types de deals et afficher des exemples
   int entry_in_count = 0;
   int entry_out_count = 0;
   int closed_positions = 0;
   ulong positions_seen[];
   int pos_count = 0;
   
   for(int i = 0; i < total_deals; i++)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket > 0)
      {
         long deal_entry = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
         ulong position_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
         datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
         
         if(deal_entry == DEAL_ENTRY_IN)
         {
            entry_in_count++;
            
            // Vérifier si cette position a été fermée
            bool is_closed = false;
            for(int j = i + 1; j < total_deals; j++)
            {
               ulong next_deal = HistoryDealGetTicket(j);
               if(next_deal > 0)
               {
                  ulong next_pos_id = HistoryDealGetInteger(next_deal, DEAL_POSITION_ID);
                  long next_entry = HistoryDealGetInteger(next_deal, DEAL_ENTRY);
                  if(next_pos_id == position_id && next_entry == DEAL_ENTRY_OUT)
                  {
                     is_closed = true;
                     closed_positions++;
                     break;
                  }
               }
            }
            
            // Afficher les 5 premières positions ouvertes et fermées
            if(pos_count < 5)
            {
               string symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
               Print("  Position #", position_id, " (", symbol, ") opened at ", TimeToString(deal_time), " - ", is_closed ? "CLOSED" : "OPEN");
               pos_count++;
            }
         }
         else if(deal_entry == DEAL_ENTRY_OUT)
         {
            entry_out_count++;
         }
      }
   }
   
   Print("DEALS BREAKDOWN:");
   Print("  Total Entry IN: ", entry_in_count);
   Print("  Total Entry OUT: ", entry_out_count);
   Print("  Closed positions: ", closed_positions);
   Print("  Still open: ", entry_in_count - closed_positions);
   
   string trades = "[";
   int count = 0;
   
   // Collecter toutes les positions uniques fermées
   ulong positions_done[];
   int positions_count = 0;
   
   // Parcourir tous les deals pour trouver les positions fermées
   for(int i = 0; i < total_deals; i++)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket > 0)
      {
         long deal_entry = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
         ulong position_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
         
         // Chercher les deals de sortie (DEAL_ENTRY_OUT)
         if(deal_entry == DEAL_ENTRY_OUT)
         {
            // Vérifier si cette position a déjà été traitée
            bool already_done = false;
            for(int j = 0; j < positions_count; j++)
            {
               if(positions_done[j] == position_id)
               {
                  already_done = true;
                  break;
               }
            }
            
            if(!already_done)
            {
               ArrayResize(positions_done, positions_count + 1);
               positions_done[positions_count] = position_id;
               positions_count++;
               
               // Sauvegarder la sélection globale
               if(HistorySelectByPosition(position_id))
               {
                  int position_deals = HistoryDealsTotal();
                  
                  datetime open_time = 0;
                  datetime close_time = 0;
                  double open_price = 0.0;
                  double close_price = 0.0;
                  double volume = 0.0;
                  double total_profit = 0.0;
                  double total_commission = 0.0;
                  double total_swap = 0.0;
                  long magic_number = 0;
                  string symbol = "";
                  string comment = "";
                  string type_str = "";
                  
                  for(int j = 0; j < position_deals; j++)
                  {
                     ulong deal = HistoryDealGetTicket(j);
                     if(deal > 0)
                     {
                        long deal_type_inner = HistoryDealGetInteger(deal, DEAL_TYPE);
                        long deal_entry_inner = HistoryDealGetInteger(deal, DEAL_ENTRY);
                        datetime deal_time = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
                        double deal_profit = HistoryDealGetDouble(deal, DEAL_PROFIT);
                        double deal_commission = HistoryDealGetDouble(deal, DEAL_COMMISSION);
                        double deal_swap = HistoryDealGetDouble(deal, DEAL_SWAP);
                        
                        if(deal_entry_inner == DEAL_ENTRY_IN)
                        {
                           open_time = deal_time;
                           open_price = HistoryDealGetDouble(deal, DEAL_PRICE);
                           volume = HistoryDealGetDouble(deal, DEAL_VOLUME);
                           symbol = HistoryDealGetString(deal, DEAL_SYMBOL);
                           magic_number = HistoryDealGetInteger(deal, DEAL_MAGIC);
                           comment = HistoryDealGetString(deal, DEAL_COMMENT);
                           
                           if(deal_type_inner == DEAL_TYPE_BUY)
                              type_str = "buy";
                           else if(deal_type_inner == DEAL_TYPE_SELL)
                              type_str = "sell";
                        }
                        else if(deal_entry_inner == DEAL_ENTRY_OUT)
                        {
                           close_time = deal_time;
                           close_price = HistoryDealGetDouble(deal, DEAL_PRICE);
                        }
                        
                        total_profit += deal_profit;
                        total_commission += deal_commission;
                        total_swap += deal_swap;
                     }
                  }
                  
                  // RESTAURER la sélection globale !
                  HistorySelect(0, TimeCurrent());
                  
                  if(open_time > 0 && close_time > 0 && close_time >= open_time)
                  {
                     string open_time_iso = TimeToString(open_time, TIME_DATE|TIME_SECONDS);
                     StringReplace(open_time_iso, ".", "-");
                     StringReplace(open_time_iso, " ", "T");
                     open_time_iso += "Z";
                     
                     string close_time_iso = TimeToString(close_time, TIME_DATE|TIME_SECONDS);
                     StringReplace(close_time_iso, ".", "-");
                     StringReplace(close_time_iso, " ", "T");
                     close_time_iso += "Z";
            
            if(count > 0) trades += ",";
            
            string comment_safe = comment != "" ? comment : "No comment";
            StringReplace(comment_safe, "\"", "'");
            StringReplace(comment_safe, "\n", " ");
            StringReplace(comment_safe, "\r", " ");
            
            trades += StringFormat(
               "{\"trade_id\":\"%d\",\"symbol\":\"%s\",\"trade_type\":\"%s\",\"volume\":%.2f,\"open_price\":%.5f,\"close_price\":%.5f,\"profit\":%.2f,\"commission\":%.2f,\"swap\":%.2f,\"open_time\":\"%s\",\"close_time\":\"%s\",\"magic_number\":%d,\"comment\":\"%s\",\"status\":\"closed\"}",
               position_id,
               symbol,
               type_str,
               volume,
                        open_price,
                        close_price,
                        total_profit,
                        total_commission,
                        total_swap,
                        open_time_iso,
                        close_time_iso,
               magic_number,
               comment_safe
            );
            
            count++;
                  }
               }
            }
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
   Print("=== WITHDRAWALS DEBUG ===");
   Print("Searching ALL withdrawals from beginning of history");
   
   if(!HistorySelect(0, TimeCurrent()))
   {
      Print("Failed to select history");
      return "[]";
   }
   
   int total_deals = HistoryDealsTotal();
   Print("Total deals found: ", total_deals);
   
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
   Print("=== DEPOSITS DEBUG ===");
   Print("Searching ALL deposits from beginning of history");
   
   if(!HistorySelect(0, TimeCurrent()))
   {
      Print("Failed to select history");
      return "[]";
   }
   
   int total_deals = HistoryDealsTotal();
   Print("Total deals found: ", total_deals);
   
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
            long deal_entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
            ulong position_id = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
            
            if(deal_entry == DEAL_ENTRY_OUT)
            {
               if(HistorySelectByPosition(position_id))
               {
                  int position_deals = HistoryDealsTotal();
                  
                  datetime open_time = 0;
                  datetime close_time = 0;
                  double open_price = 0.0;
                  double close_price = 0.0;
                  double volume = 0.0;
                  double total_profit = 0.0;
                  double total_commission = 0.0;
                  double total_swap = 0.0;
                  long magic_number = 0;
                  string symbol = "";
                  string comment = "";
                  string type_str = "";
                  
                  for(int j = 0; j < position_deals; j++)
                  {
                     ulong deal_ticket = HistoryDealGetTicket(j);
                     if(deal_ticket > 0)
                     {
                        long deal_type_inner = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
                        long deal_entry_inner = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
                        datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
                        double deal_profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
                        double deal_commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
                        double deal_swap = HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
                        
                        if(deal_entry_inner == DEAL_ENTRY_IN)
                        {
                           open_time = deal_time;
                           open_price = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
                           volume = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
                           symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
                           magic_number = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
                           comment = HistoryDealGetString(deal_ticket, DEAL_COMMENT);
                           
                           if(deal_type_inner == DEAL_TYPE_BUY)
                              type_str = "buy";
                           else if(deal_type_inner == DEAL_TYPE_SELL)
                              type_str = "sell";
                        }
                        else if(deal_entry_inner == DEAL_ENTRY_OUT)
                        {
                           close_time = deal_time;
                           close_price = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
                        }
                        
                        total_profit += deal_profit;
                        total_commission += deal_commission;
                        total_swap += deal_swap;
                     }
                  }
                  
                  if(open_time > 0 && close_time > 0 && close_time >= open_time)
                  {
                     string open_time_iso = TimeToString(open_time, TIME_DATE|TIME_SECONDS);
                     StringReplace(open_time_iso, ".", "-");
                     StringReplace(open_time_iso, " ", "T");
                     open_time_iso += "Z";
                     
                     string close_time_iso = TimeToString(close_time, TIME_DATE|TIME_SECONDS);
                     StringReplace(close_time_iso, ".", "-");
                     StringReplace(close_time_iso, " ", "T");
                     close_time_iso += "Z";
            
            if(count > 0) trades += ",";
            
            string comment_safe = comment != "" ? comment : "No comment";
            StringReplace(comment_safe, "\"", "'");
            StringReplace(comment_safe, "\n", " ");
            StringReplace(comment_safe, "\r", " ");
            
            trades += StringFormat(
               "{\"trade_id\":\"%d\",\"symbol\":\"%s\",\"trade_type\":\"%s\",\"volume\":%.2f,\"open_price\":%.5f,\"close_price\":%.5f,\"profit\":%.2f,\"commission\":%.2f,\"swap\":%.2f,\"open_time\":\"%s\",\"close_time\":\"%s\",\"magic_number\":%d,\"comment\":\"%s\",\"status\":\"closed\"}",
               position_id,
               symbol,
               type_str,
               volume,
                        open_price,
                        close_price,
                        total_profit,
                        total_commission,
                        total_swap,
                        open_time_iso,
                        close_time_iso,
               magic_number,
               comment_safe
            );
            
            count++;
                  }
               }
            }
         }
      }
   }
   
   trades += "]";
   
   Print("Prepared ", count, " trades for sync");
   
   return trades;
}

//+------------------------------------------------------------------+
//| Get active expert advisors (magic numbers)                       |
//+------------------------------------------------------------------+
string GetActiveExpertsJSON()
{
   string experts = "[";
   int count = 0;
   
   // Récupérer les magic numbers depuis l'historique (30 derniers jours)
   datetime from_time = TimeCurrent() - (30 * 24 * 3600);
   if(!HistorySelect(from_time, TimeCurrent()))
   {
      Print("Failed to select history for active experts");
      return "[]";
   }
   
   int total_deals = HistoryDealsTotal();
   ulong active_magic_numbers[];
   int magic_count = 0;
   
   Print("=== ACTIVE EXPERTS DEBUG ===");
   Print("Scanning last 30 days for active magic numbers...");
   
   // Scanner les positions ouvertes
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i) > 0)
      {
         long magic = PositionGetInteger(POSITION_MAGIC);
         
         // Vérifier si le magic number n'est pas déjà dans la liste
         bool found = false;
         for(int j = 0; j < magic_count; j++)
         {
            if(active_magic_numbers[j] == magic)
            {
               found = true;
               break;
            }
         }
         
         if(!found && magic > 0)
         {
            ArrayResize(active_magic_numbers, magic_count + 1);
            active_magic_numbers[magic_count] = magic;
            magic_count++;
            Print("Found active magic number from open position: ", magic);
         }
      }
   }
   
   // Scanner l'historique sur 30 jours pour détecter les EAs actifs
   datetime recent_from = TimeCurrent() - (30 * 24 * 3600);  // 30 derniers jours
   if(HistorySelect(recent_from, TimeCurrent()))
   {
      Print("Scanning last 30 days for active magic numbers...");
      
      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong deal_ticket = HistoryDealGetTicket(i);
         if(deal_ticket > 0)
         {
            long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
            
            if(magic > 0)
            {
               // Vérifier si le magic number n'est pas déjà dans la liste
               bool found = false;
               for(int j = 0; j < magic_count; j++)
               {
                  if(active_magic_numbers[j] == magic)
                  {
                     found = true;
                     break;
                  }
               }
               
               if(!found)
               {
                  ArrayResize(active_magic_numbers, magic_count + 1);
                  active_magic_numbers[magic_count] = magic;
                  magic_count++;
                  Print("Found trade from magic number: ", magic);
               }
            }
         }
      }
   }
   
   // Détection supplémentaire : chercher dans les paramètres des EAs actifs
   Print("Scanning all charts for EA parameters...");
   int total_charts = ChartGetInteger(0, CHART_WINDOWS_TOTAL);
   Print("Total windows: ", total_charts);
   
   for(int chart_id = 0; chart_id < total_charts; chart_id++)
   {
      long chart_window = ChartGetInteger(0, CHART_WINDOW_HANDLE, chart_id);
      if(chart_window > 0)
      {
         string symbol = ChartSymbol(chart_window);
         Print("Chart ", chart_id, ": ", symbol);
      }
   }
   
   Print("Total magic numbers found: ", magic_count);
   
   // Vérifier l'activité récente de chaque magic number
   if(magic_count > 0)
   {
      Print("=== ÉTAT DES EAs (ACTIVITÉ RÉCENTE) ===");
      
      for(int i = 0; i < magic_count; i++)
      {
         long magic = active_magic_numbers[i];
         
         // Chercher des positions ouvertes avec ce magic number
         bool has_open_positions = false;
         int open_positions_count = 0;
         
         for(int p = 0; p < PositionsTotal(); p++)
         {
            if(PositionGetTicket(p) > 0)
            {
               long position_magic = PositionGetInteger(POSITION_MAGIC);
               if(position_magic == magic)
               {
                  has_open_positions = true;
                  open_positions_count++;
               }
            }
         }
         
         // Chercher des trades très récents (dernières 24h)
         bool has_recent_trades = false;
         datetime recent_trade_time = 0;
         
         datetime last_24h = TimeCurrent() - 86400;
         if(HistorySelect(last_24h, TimeCurrent()))
         {
            for(int d = 0; d < HistoryDealsTotal(); d++)
            {
               ulong deal = HistoryDealGetTicket(d);
               if(deal > 0)
               {
                  long deal_magic = HistoryDealGetInteger(deal, DEAL_MAGIC);
                  if(deal_magic == magic)
                  {
                     has_recent_trades = true;
                     datetime deal_time = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
                     if(deal_time > recent_trade_time)
                        recent_trade_time = deal_time;
                  }
               }
            }
         }
         
         // Afficher le statut
         string status = "ARRÊTÉ";
         if(has_open_positions)
            status = "ACTIF (positions ouvertes)";
         else if(has_recent_trades)
            status = "ACTIF (trade récent)";
         
         Print("  Magic #", i + 1, ": ", magic, " - ", status);
         if(has_open_positions)
            Print("    → ", open_positions_count, " position(s) ouverte(s)");
         if(has_recent_trades)
            Print("    → Dernier trade: ", TimeToString(recent_trade_time, TIME_DATE|TIME_SECONDS));
      }
      Print("===========================================");
   }
   else
   {
      Print("⚠️  AUCUN MAGIC NUMBER DÉTECTÉ - Tous les EAs sont probablement arrêtés");
   }
   
   Print("=== END ACTIVE EXPERTS DEBUG ===");
   
   // RESTAURER la sélection globale
   HistorySelect(0, TimeCurrent());
   
   // Construire le JSON
   for(int i = 0; i < magic_count; i++)
   {
      if(count > 0) experts += ",";
      experts += StringFormat("{\"magic_number\":%d,\"source\":\"auto_detected\"}", active_magic_numbers[i]);
      count++;
   }
   
   experts += "]";
   
   Print("JSON envoyé: ", experts);
   
   return experts;
}

//+------------------------------------------------------------------+
//| Get open positions as JSON                                       |
//+------------------------------------------------------------------+
string GetOpenPositionsJSON()
{
   string positions = "[";
   int count = 0;
   
   int total_positions = PositionsTotal();
   
   Print("=== OPEN POSITIONS DEBUG ===");
   Print("Total open positions: ", total_positions);
   
   if(total_positions == 0)
   {
      Print("No open positions found");
      Print("=== END OPEN POSITIONS DEBUG ===");
      return "[]";
   }
   
   for(int i = 0; i < total_positions; i++)
   {
      if(PositionGetTicket(i) > 0)
      {
         ulong position_ticket = PositionGetInteger(POSITION_TICKET);
         string symbol = PositionGetString(POSITION_SYMBOL);
         long magic_number = PositionGetInteger(POSITION_MAGIC);
         ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double current_price = 0.0;
         double swap = PositionGetDouble(POSITION_SWAP);
         double profit = PositionGetDouble(POSITION_PROFIT);
         datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
         double commission = 0.0;
         string comment = PositionGetString(POSITION_COMMENT);
         
         if(position_type == POSITION_TYPE_BUY)
            current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
         else if(position_type == POSITION_TYPE_SELL)
            current_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
         
         string type_str = (position_type == POSITION_TYPE_BUY) ? "buy" : "sell";
         
         string open_time_iso = TimeToString(open_time, TIME_DATE|TIME_SECONDS);
         StringReplace(open_time_iso, ".", "-");
         StringReplace(open_time_iso, " ", "T");
         open_time_iso += "Z";
         
         string current_time_iso = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
         StringReplace(current_time_iso, ".", "-");
         StringReplace(current_time_iso, " ", "T");
         current_time_iso += "Z";
         
         if(count > 0) positions += ",";
         
         positions += StringFormat(
            "{\"trade_id\":\"%d\",\"symbol\":\"%s\",\"trade_type\":\"%s\",\"volume\":%.2f,\"open_price\":%.5f,\"close_price\":%.5f,\"profit\":%.2f,\"commission\":%.2f,\"swap\":%.2f,\"open_time\":\"%s\",\"close_time\":\"%s\",\"magic_number\":%d,\"comment\":\"%s\",\"status\":\"open\"}",
            position_ticket,
            symbol,
            type_str,
            volume,
            open_price,
            current_price,
            profit,
            commission,
            swap,
            open_time_iso,
            current_time_iso,
            magic_number,
            comment
         );
         
         count++;
      }
   }
   
   positions += "]";
   
   Print("Prepared ", count, " open positions");
   Print("=== END OPEN POSITIONS DEBUG ===");
   
   return positions;
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