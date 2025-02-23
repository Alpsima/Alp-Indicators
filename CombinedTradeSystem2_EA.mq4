//+------------------------------------------------------------------+
//| CombinedTradeSystem2_EA.mq4                                       |
//| Copyright 2024                                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"
#property strict

// Extern değişkenler
extern double RiskPercent = 1.0;        // Risk yüzdesi
extern double StopLoss_ATR = 1.5;       // ATR bazlı Stop Loss
extern double TakeProfit_ATR = 3.0;     // ATR bazlı Take Profit
extern bool UseTrailingStop = true;      // Trailing Stop kullanımı
extern int ATR_Period = 14;             // ATR periyodu
extern int MaxSpread = 35;              // Maksimum spread (points)
extern int MaxRetries = 3;              // Maksimum deneme sayısı
extern int RetryDelay = 5000;           // Yeniden deneme gecikmesi (ms)

// Global değişkenler
double g_atr;
int g_ticket = -1;
bool g_triggered = false;
datetime g_lastActionTime = 0;
int g_retryCount = 0;

// İndikatör tamponları
double DC20Upper[], DC20Lower[], DC20Mid[];
double DC55Upper[], DC55Lower[], DC55Mid[];
double ADXBuffer[], ADXPlusBuffer[];

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("CombinedTradeSystem2_EA başlatılıyor...");
   
   // Tamponların hazırlanması
   ArraySetAsSeries(DC20Upper, true);
   ArraySetAsSeries(DC20Lower, true);
   ArraySetAsSeries(DC20Mid, true);
   ArraySetAsSeries(DC55Upper, true);
   ArraySetAsSeries(DC55Lower, true);
   ArraySetAsSeries(DC55Mid, true);
   ArraySetAsSeries(ADXBuffer, true);
   ArraySetAsSeries(ADXPlusBuffer, true);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("CombinedTradeSystem2_EA durduruluyor...");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsTradeAllowed())
   {
      Print("Trading not allowed!");
      return;
   }
   
   // ATR hesaplama
   g_atr = iATR(NULL, 0, ATR_Period, 1);
   
   // Spread kontrolü
   double current_spread = MarketInfo(Symbol(), MODE_SPREAD);
   if(current_spread > MaxSpread)
   {
      Print("Spread çok yüksek: ", current_spread);
      return;
   }
   
   // Gösterge değerlerini al
   if(!GetIndicatorValues())
   {
      Print("Gösterge değerleri alınamadı!");
      return;
   }
   
   // Perfect Storm sinyali kontrolü
   int signal = CheckPerfectStormSignal();
   
   // İşlem yönetimi
   ManageTrades(signal);
}

//+------------------------------------------------------------------+
//| Gösterge değerlerini alma                                         |
//+------------------------------------------------------------------+
bool GetIndicatorValues()
{
   // CombinedTradeSystem2 gösterge değerlerini al
   for(int i = 0; i < 10; i++)
   {
      DC20Upper[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 0, i);
      DC20Lower[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 1, i);
      DC20Mid[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 2, i);
      DC55Upper[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 3, i);
      DC55Lower[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 4, i);
      DC55Mid[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 5, i);
      ADXBuffer[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 6, i);
      ADXPlusBuffer[i] = iCustom(NULL, 0, "CombinedTradeSystem2", 7, i);
      
      if(GetLastError() != 0)
      {
         Print("Gösterge değeri alma hatası: ", GetLastError());
         return false;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Perfect Storm sinyali kontrolü                                     |
//+------------------------------------------------------------------+
int CheckPerfectStormSignal()
{
   // Conqueror5 sinyali (ilk indikatör)
   int signal1 = 0;
   if(Close[1] > DC20Upper[1]) signal1 = 1;
   else if(Close[1] < DC20Lower[1]) signal1 = -1;
   
   // Conqueror6 sinyali (ikinci indikatör)
   int signal2 = 0;
   if(Close[1] > DC55Upper[1]) signal2 = 1;
   else if(Close[1] < DC55Lower[1]) signal2 = -1;
   
   // DChannel sinyali (üçüncü indikatör)
   int signal3 = 0;
   if(Close[1] > DC20Mid[1]) signal3 = 1;
   else if(Close[1] < DC20Mid[1]) signal3 = -1;
   
   // Perfect Storm kontrolü
   if(signal1 == 1 && signal2 == 1 && signal3 == 1) return 1;  // Long
   if(signal1 == -1 && signal2 == -1 && signal3 == -1) return -1;  // Short
   
   return 0;  // Hold
}

//+------------------------------------------------------------------+
//| İşlem yönetimi                                                     |
//+------------------------------------------------------------------+
void ManageTrades(int signal)
{
   // Açık pozisyon kontrolü
   if(OrdersTotal() > 0)
   {
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == 20240223)
            {
               // Trailing Stop
               if(UseTrailingStop) ManageTrailingStop();
               
               // Pozisyon kapatma sinyali
               if((OrderType() == OP_BUY && signal == -1) ||
                  (OrderType() == OP_SELL && signal == 1))
               {
                  ClosePosition();
               }
               return;
            }
         }
      }
   }
   
   // Yeni pozisyon açma
   if(signal != 0 && TimeCurrent() - g_lastActionTime > 300)
   {
      OpenPosition(signal);
   }
}

//+------------------------------------------------------------------+
//| Trailing Stop yönetimi                                            |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == 20240223)
         {
            double atr = iATR(NULL, 0, ATR_Period, 1);
            double newSL;
            
            if(OrderType() == OP_BUY)
            {
               newSL = Bid - (atr * StopLoss_ATR);
               if(newSL > OrderStopLoss() && Bid - OrderOpenPrice() > atr)
               {
                  ModifyPosition(newSL, OrderTakeProfit());
               }
            }
            else if(OrderType() == OP_SELL)
            {
               newSL = Ask + (atr * StopLoss_ATR);
               if(newSL < OrderStopLoss() && OrderOpenPrice() - Ask > atr)
               {
                  ModifyPosition(newSL, OrderTakeProfit());
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Pozisyon açma                                                     |
//+------------------------------------------------------------------+
void OpenPosition(int signal)
{
   double lotSize = CalculateLotSize();
   double sl = 0, tp = 0;
   int orderType;
   double orderPrice;
   
   if(signal == 1)  // Long
   {
      orderType = OP_BUY;
      orderPrice = Ask;
      sl = orderPrice - (g_atr * StopLoss_ATR);
      tp = orderPrice + (g_atr * TakeProfit_ATR);
   }
   else if(signal == -1)  // Short
   {
      orderType = OP_SELL;
      orderPrice = Bid;
      sl = orderPrice + (g_atr * StopLoss_ATR);
      tp = orderPrice - (g_atr * TakeProfit_ATR);
   }
   else return;
   
   g_retryCount = 0;
   while(g_retryCount < MaxRetries)
   {
      g_ticket = OrderSend(Symbol(), orderType, lotSize, orderPrice, 3, sl, tp,
                          "CombinedTradeSystem2", 20240223, 0, orderType == OP_BUY ? clrBlue : clrRed);
      
      if(g_ticket > 0)
      {
         Print("Pozisyon açıldı. Ticket: ", g_ticket);
         g_lastActionTime = TimeCurrent();
         break;
      }
      
      g_retryCount++;
      Print("Pozisyon açma hatası: ", GetLastError(), " Deneme: ", g_retryCount);
      Sleep(RetryDelay);
   }
}

//+------------------------------------------------------------------+
//| Pozisyon kapatma                                                  |
//+------------------------------------------------------------------+
void ClosePosition()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == 20240223)
         {
            g_retryCount = 0;
            while(g_retryCount < MaxRetries)
            {
               bool result = false;
               if(OrderType() == OP_BUY)
                  result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrRed);
               else if(OrderType() == OP_SELL)
                  result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrBlue);
                  
               if(result)
               {
                  Print("Pozisyon kapatıldı. Ticket: ", OrderTicket());
                  g_lastActionTime = TimeCurrent();
                  break;
               }
               
               g_retryCount++;
               Print("Pozisyon kapatma hatası: ", GetLastError(), " Deneme: ", g_retryCount);
               Sleep(RetryDelay);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Pozisyon modifikasyonu                                            |
//+------------------------------------------------------------------+
void ModifyPosition(double sl, double tp)
{
   g_retryCount = 0;
   while(g_retryCount < MaxRetries)
   {
      bool result = OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0);
      
      if(result)
      {
         Print("Pozisyon modifiye edildi. Ticket: ", OrderTicket());
         break;
      }
      
      g_retryCount++;
      Print("Pozisyon modifikasyon hatası: ", GetLastError(), " Deneme: ", g_retryCount);
      Sleep(RetryDelay);
   }
}

//+------------------------------------------------------------------+
//| Lot büyüklüğü hesaplama                                          |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double lotSize = 0;
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   
   double riskAmount = AccountBalance() * RiskPercent / 100;
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   
   if(tickSize == 0) return minLot;
   
   double valuePerPip = tickValue / tickSize;
   double pipDistance = g_atr * StopLoss_ATR / Point;
   
   if(valuePerPip != 0 && pipDistance != 0)
      lotSize = NormalizeDouble(riskAmount / (pipDistance * valuePerPip), 2);
   
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   return NormalizeDouble(lotSize, 2);
}
