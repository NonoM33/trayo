//+------------------------------------------------------------------+
//|                                                    TrayoSync.mq5 |
//|                                     Expert Advisor de sync API   |
//+------------------------------------------------------------------+
#property copyright "Trayo"
#property version   "1.00"
#property strict

input string API_URL = "http://localhost:3000/api/v1/mt5/sync";
input string API_KEY = "mt5_secret_key_change_in_production";
input string MT5_API_TOKEN = "your_mt5_api_token_here";
input int REFRESH_INTERVAL = 300;

datetime last_sync_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("========================================");
   Print("TrayoSync Expert Advisor Started");
   Print("========================================");
   Print("API URL: ", API_URL);
   Print("Refresh Interval: ", REFRESH_INTERVAL, " seconds");
   Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("========================================");
   
   EventSetTimer(REFRESH_INTERVAL);
   
   SyncDataToAPI();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   Print("========================================");
   Print("TrayoSync Expert Advisor Stopped");
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
      "{\"mt5_data\":{\"mt5_id\":\"%d\",\"mt5_api_token\":\"%s\",\"account_name\":\"%s\",\"balance\":%.2f,\"trades\":%s}}",
      account_number,
      MT5_API_TOKEN,
      account_name,
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
//| Get trades as JSON                                               |
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
//| Expert tick function (optional)                                  |
//+------------------------------------------------------------------+
void OnTick()
{
   // Rien à faire sur chaque tick
   // La synchronisation se fait uniquement via le timer
}
//+------------------------------------------------------------------+
