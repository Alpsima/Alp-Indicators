//+------------------------------------------------------------------+
//|                                          CombinedTradeSystem2.mq4  |
//|                                                                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "2.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 8

// Sinyal Sabitleri
#define SIGNAL_LONG    1
#define SIGNAL_SHORT  -1
#define SIGNAL_HOLD    0

// Temel Ayarlar
extern string     GeneralSettings    = "===== Genel Ayarlar =====";
extern int        ShortPeriod       = 20;    // Kısa Donchian Periyodu
extern int        LongPeriod        = 55;    // Uzun Donchian Periyodu
extern int        EarlyExitBars     = 5;     // Early Exit Bar Sayısı
extern double     PipThreshold      = 4.0;   // Pip Eşik Değeri

// ATR Bazlı Eşik Ayarları
extern string     ATRSettings       = "===== ATR Ayarları =====";
extern int        ATR_Period        = 14;    // ATR Periyodu
extern double     Mult_AB           = 0.5;   // (A-B) için ATR çarpanı
extern double     Mult_BC           = 0.4;   // (B-C) için ATR çarpanı
extern double     Mult_AD           = 0.6;   // (A-D) için ATR çarpanı

// Haber Filtresi Ayarları
extern string     NewsSettings      = "===== Haber Ayarları =====";
extern bool       UseNewsFilter     = true;    // Haber Filtresi Kullan
extern bool       FilterHighImpact  = true;    // Yüksek Etkili Haberler
extern bool       FilterMediumImpact= false;   // Orta Etkili Haberler
extern bool       FilterLowImpact   = false;   // Düşük Etkili Haberler
extern int        NewsBeforeMinutes = 30;      // Haber Öncesi (Dakika)
extern int        NewsAfterMinutes  = 30;      // Haber Sonrası (Dakika)
extern string     NewsFile          = "forex_calendar.csv";  // Haber CSV dosyası

// Alert Ayarları
extern string     AlertSettings     = "===== Alert Ayarları =====";
extern bool       EnableSoundAlert  = true;    // Sesli Alert
extern bool       EnablePopupAlert  = true;    // Popup Mesaj

// Conqueror3 Ayarları
extern string     Con3Settings      = "===== Conqueror3 Ayarları =====";
extern int        MVA_Period        = 10;    // Moving Average periyodu
extern int        LookBack_Periods  = 20;    // MA karşılaştırma periyodu
extern int        LookBack_Close    = 40;    // Kapanış karşılaştırma periyodu

// Conqueror4 Ayarları
extern string     Con4Settings      = "===== Conqueror4 Ayarları =====";
extern int        Con4_MVA_Period   = 10;    // Conqueror4 MA periyodu
extern int        Range_Period1     = 25;    // Kısa dönem periyodu
extern int        Range_Period2     = 55;    // Uzun dönem periyodu

// Görünüm Ayarları
extern string     DisplaySettings    = "===== Görünüm Ayarları =====";
extern int        TableX            = 1300;  // Tablo X Koordinatı
extern int        TableY            = 20;    // Tablo Y Koordinatı
extern color      HeaderColor       = C'40,40,40';  // Başlık Rengi
extern color      TextColor         = clrWhite;     // Yazı Rengi
extern color      LongColor         = clrForestGreen;   // Long Sinyal Rengi
extern color      ShortColor        = clrCrimson;       // Short Sinyal Rengi
extern color      HoldColor         = clrRoyalBlue;     // Hold Sinyal Rengi
extern color      ATRColumnColor    = C'40,40,40';  // ATR Kolon Rengi
extern string     FontName          = "Arial";      // Yazı Tipi
extern int        FontSize          = 8;            // Yazı Boyutu
extern int        ColumnWidth       = 60;           // Kolon Genişliği
extern int        RowHeight         = 20;           // Satır Yüksekliği

// Risk Tablosu Ayarları
extern string     RiskTableSettings = "===== Risk Tablosu Ayarları =====";
extern int        RiskTableX        = 20;    // Risk Tablosu X Koordinatı
extern int        RiskTableY        = 20;    // Risk Tablosu Y Koordinatı

// Global Değişkenler
string           IndicatorName;
string           IndicatorObjPrefix;
int              TimeFrames[6];
string           TimeFrameNames[6];

// Haber yapısı ve dizisi
struct NewsEvent {
    datetime time;
    string currency;
    string event;
    string impact;
    int minutesUntil;
};
NewsEvent activeNews[];

// Para birimi bilgisi
string currentSymbolCurrencies[2];  // Örn: EUR/USD için [EUR, USD]

// İndikatör tamponları
double DC20Upper[], DC20Lower[], DC20Mid[];
double DC55Upper[], DC55Lower[], DC55Mid[];
double ADXBuffer[], ADXPlusBuffer[];

// Son alert durumları takibi için
datetime LastAlertTime[];
int LastDCSignal[];

// Risk faktörleri için
bool hasHighSpread = false;
bool hasHighVolatility = false;
bool hasUpcomingNews = false;
double currentATR = 0;
double currentSpread = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                           |
//+------------------------------------------------------------------+
int init()
{
   // Timeframe dizilerini doldur
   TimeFrames[0] = PERIOD_W1;
   TimeFrames[1] = PERIOD_D1;
   TimeFrames[2] = PERIOD_H4;
   TimeFrames[3] = PERIOD_H1;
   TimeFrames[4] = PERIOD_M30;
   TimeFrames[5] = PERIOD_M15;
   
   TimeFrameNames[0] = "W";
   TimeFrameNames[1] = "D";
   TimeFrameNames[2] = "4H";
   TimeFrameNames[3] = "1H";
   TimeFrameNames[4] = "30M";
   TimeFrameNames[5] = "15M";
   
   IndicatorName = "CombinedTradeSystem2";
   IndicatorObjPrefix = "##" + IndicatorName + "##";
   
   // Alert takibi için dizileri hazırla
   ArrayResize(LastAlertTime, ArraySize(TimeFrames));
   ArrayResize(LastDCSignal, ArraySize(TimeFrames));
   ArrayInitialize(LastAlertTime, 0);
   ArrayInitialize(LastDCSignal, SIGNAL_HOLD);
   
   // Para birimlerini ayarla
   GetSymbolCurrencies();
   
   // Buffer ayarları
   SetIndexBuffer(0, DC20Upper);
   SetIndexBuffer(1, DC20Lower);
   SetIndexBuffer(2, DC20Mid);
   SetIndexBuffer(3, DC55Upper);
   SetIndexBuffer(4, DC55Lower);
   SetIndexBuffer(5, DC55Mid);
   SetIndexBuffer(6, ADXBuffer);
   SetIndexBuffer(7, ADXPlusBuffer);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                         |
//+------------------------------------------------------------------+
int deinit()
{
   ObjectsDeleteAll(0, IndicatorObjPrefix);
   return(0);
}

//+------------------------------------------------------------------+
//| Para birimlerini ayıklama fonksiyonu                              |
//+------------------------------------------------------------------+
void GetSymbolCurrencies()
{
   string symbol = Symbol();
   
   // Normal forex çiftleri için (örn: EURUSD)
   if(StringLen(symbol) == 6)
   {
      currentSymbolCurrencies[0] = StringSubstr(symbol, 0, 3);
      currentSymbolCurrencies[1] = StringSubstr(symbol, 3, 3);
   }
   // Metaller için (örn: XAUUSD)
   else if(StringLen(symbol) == 6 && 
           (StringSubstr(symbol, 0, 3) == "XAU" || 
            StringSubstr(symbol, 0, 3) == "XAG"))
   {
      currentSymbolCurrencies[0] = StringSubstr(symbol, 0, 3);
      currentSymbolCurrencies[1] = StringSubstr(symbol, 3, 3);
   }
   // Endeksler için özel kontrol
   else
   {
      if(StringFind(symbol, "US30") != -1 || 
         StringFind(symbol, "SPX500") != -1 || 
         StringFind(symbol, "NAS100") != -1)
      {
         currentSymbolCurrencies[0] = "USD";
         currentSymbolCurrencies[1] = "USD";
      }
      else if(StringFind(symbol, "GER30") != -1 || 
              StringFind(symbol, "FRA40") != -1)
      {
         currentSymbolCurrencies[0] = "EUR";
         currentSymbolCurrencies[1] = "EUR";
      }
      else if(StringFind(symbol, "UK100") != -1)
      {
         currentSymbolCurrencies[0] = "GBP";
         currentSymbolCurrencies[1] = "GBP";
      }
   }
}

//+------------------------------------------------------------------+
//| Haber dosyasını okuma fonksiyonu                                  |
//+------------------------------------------------------------------+
bool ReadNewsFile()
{
   ArrayResize(activeNews, 0);
   
   string filename = NewsFile;
   int handle = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI, ",");
   if(handle == INVALID_HANDLE)
   {
      Print("Haber dosyası açılamadı: ", filename);
      return false;
   }
   
   datetime currentTime = TimeCurrent();
   
   // Başlık satırını atla
   if(FileIsEnding(handle)) { FileClose(handle); return false; }
   FileReadString(handle);
   
   while(!FileIsEnding(handle))
   {
      // CSV formatı: Date,Time,Currency,Event,Impact
      string dateStr = FileReadString(handle);
      string timeStr = FileReadString(handle);
      string currency = FileReadString(handle);
      string event = FileReadString(handle);
      string impact = FileReadString(handle);
      
      // Tarihi datetime'a çevir
      datetime newsTime = StrToTime(dateStr + " " + timeStr);
      
      // Süresi dolmuş haberleri atla
      if(newsTime < currentTime - NewsAfterMinutes * 60) continue;
      
      // Gelecek haberleri kontrol et
      if(newsTime > currentTime + 24 * 60 * 60) continue;
      
      // Etki seviyesi kontrolü
      if(impact == "High" && !FilterHighImpact) continue;
      if(impact == "Medium" && !FilterMediumImpact) continue;
      if(impact == "Low" && !FilterLowImpact) continue;
      
      // Para birimi kontrolü
      if(currency != currentSymbolCurrencies[0] && 
         currency != currentSymbolCurrencies[1]) continue;
      
      // Haber bilgilerini kaydet
      int idx = ArraySize(activeNews);
      ArrayResize(activeNews, idx + 1);
      activeNews[idx].time = newsTime;
      activeNews[idx].currency = currency;
      activeNews[idx].event = event;
      activeNews[idx].impact = impact;
      activeNews[idx].minutesUntil = (int)((newsTime - currentTime) / 60);
   }
   
   FileClose(handle);
   return true;
}

//+------------------------------------------------------------------+
//| Risk tablosunu güncelleme fonksiyonu                              |
//+------------------------------------------------------------------+
void UpdateRiskTable()
{
   string prefix = IndicatorObjPrefix + "Risk_";
   
   // Risk tablosu başlığı
   CreateCell(prefix + "Header", RiskTableX, RiskTableY, 
             "Risk Faktörleri", HeaderColor, TextColor);
             
   int currentRow = 1;
   int rowY = RiskTableY + currentRow * RowHeight;
   
   // Spread kontrolü
   currentSpread = MarketInfo(Symbol(), MODE_SPREAD) * Point * 10;
   if(currentSpread > 0)
   {
      string spreadText = "Spread: " + DoubleToStr(currentSpread, 1) + " pips";
      color spreadColor = currentSpread > PipThreshold ? clrCrimson : clrForestGreen;
      CreateCell(prefix + "Spread", RiskTableX, rowY, spreadText, 
                HeaderColor, spreadColor);
      currentRow++;
      rowY = RiskTableY + currentRow * RowHeight;
   }
   
   // Volatilite (ATR) kontrolü
   currentATR = iATR(NULL, PERIOD_CURRENT, ATR_Period, 0);
   if(currentATR > 0)
   {
      string atrText = "ATR: " + DoubleToStr(currentATR, Digits);
      color atrColor = currentATR > PipThreshold * Point * 10 ? clrCrimson : clrForestGreen;
      CreateCell(prefix + "ATR", RiskTableX, rowY, atrText, 
                HeaderColor, atrColor);
      currentRow++;
      rowY = RiskTableY + currentRow * RowHeight;
   }
   
   // Yaklaşan haberleri göster
   if(ArraySize(activeNews) > 0)
   {
      for(int i = 0; i < ArraySize(activeNews); i++)
      {
         if(activeNews[i].minutesUntil >= -NewsAfterMinutes && 
            activeNews[i].minutesUntil <= NewsBeforeMinutes)
         {
            string newsText = activeNews[i].currency + " " + 
                            activeNews[i].event + " (" + 
                            activeNews[i].impact + ")";
            
            color newsColor = activeNews[i].impact == "High" ? clrCrimson :
                            activeNews[i].impact == "Medium" ? clrDarkOrange :
                            clrForestGreen;
                            
            CreateCell(prefix + "News" + IntegerToString(i), 
                      RiskTableX, rowY, newsText, HeaderColor, newsColor);
            
            // Kalan süreyi göster
            rowY += RowHeight;
            currentRow++;
            string timeText = activeNews[i].minutesUntil > 0 ?
                           IntegerToString(activeNews[i].minutesUntil) + " dk sonra" :
                           "Şu anda aktif";
            
            CreateCell(prefix + "NewsTime" + IntegerToString(i), 
                      RiskTableX, rowY, timeText, HeaderColor, newsColor);
            
            currentRow++;
            rowY = RiskTableY + currentRow * RowHeight;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Donchian Channel Middle Line Signal                               |
//+------------------------------------------------------------------+
int CalculateDCOSignal(int timeframe)
{
   double currentClose = iClose(NULL, timeframe, 0);
   double midLine = (iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, ShortPeriod, 1)) +
                    iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, ShortPeriod, 1))) / 2;
   
   double atr = iATR(NULL, timeframe, ATR_Period, 0);
   double threshold = atr * Mult_AB;
   
   if(currentClose > midLine + threshold)
      return SIGNAL_LONG;
   else if(currentClose < midLine - threshold)
      return SIGNAL_SHORT;
      
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| Donchian Channel Sinyali Hesaplama                                |
//+------------------------------------------------------------------+
int CalculateDCSignal(int timeframe, int period)
{   
   if(iVolume(NULL, timeframe, 0) > 1)
      return LastDCSignal[TimeFrameIndex(timeframe)];
      
   double currentClose = iClose(NULL, timeframe, 0);
   double previousClose = iClose(NULL, timeframe, 1);
   
   double currentUpperBand = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, period, 1));
   double currentLowerBand = iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, period, 1));
   
   double lastUpperBand, lastLowerBand;
   if(!FindLastValidChannel(timeframe, period, lastUpperBand, lastLowerBand))
   {
      lastUpperBand = currentUpperBand;
      lastLowerBand = currentLowerBand;
   }
   
   double atr = iATR(NULL, timeframe, ATR_Period, 0);
   double threshold = atr * Mult_AB;
   
   if(currentClose > lastUpperBand + threshold)
   {
      if(currentClose >= previousClose - threshold)
         return SIGNAL_LONG;
      return SIGNAL_HOLD;
   }
   
   if(currentClose < lastLowerBand - threshold)
   {
      if(currentClose <= previousClose + threshold)
         return SIGNAL_SHORT;
      return SIGNAL_HOLD;
   }
   
   return LastDCSignal[TimeFrameIndex(timeframe)];
}

//+------------------------------------------------------------------+
//| Conqueror3 Sinyali Hesaplama                                      |
//+------------------------------------------------------------------+
int CalculateConqueror3Signal(int timeframe)
{
   double currentClose = iClose(NULL, timeframe, 1);
   double currentMA = iMA(NULL, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double oldMA = iMA(NULL, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, LookBack_Periods + 1);
   double oldClose = iClose(NULL, timeframe, LookBack_Close + 1);
   
   double atr = iATR(NULL, timeframe, ATR_Period, 0);
   double threshold_AB = atr * Mult_AB;
   double threshold_BC = atr * Mult_BC;
   double threshold_AD = atr * Mult_AD;
   
   double diffCloseMA = currentClose - currentMA;
   double diffMAs = currentMA - oldMA;
   double diffCloses = currentClose - oldClose;
   
   if(diffCloseMA > threshold_AB && diffMAs > threshold_BC && diffCloses > threshold_AD)
      return SIGNAL_LONG;
   
   if(diffCloseMA < -threshold_AB && diffMAs < -threshold_BC && diffCloses < -threshold_AD)
      return SIGNAL_SHORT;
   
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| Conqueror4 Sinyali Hesaplama                                      |
//+------------------------------------------------------------------+
int CalculateConqueror4Signal(int timeframe)
{
   double MA0 = iMA(NULL, timeframe, Con4_MVA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA1 = iMA(NULL, timeframe, Con4_MVA_Period, 0, MODE_SMA, PRICE_CLOSE, Range_Period1);
   double Close0 = iClose(NULL, timeframe, 0);
   double CloseOld = iClose(NULL, timeframe, Range_Period2);
   
   double atr = iATR(NULL, timeframe, ATR_Period, 0);
   double threshold_AB = atr * Mult_AB;
   double threshold_BC = atr * Mult_BC;
   double threshold_AD = atr * Mult_AD;
   
   if(Close0 > MA0 + threshold_AB && MA0 > MA1 + threshold_BC && Close0 > CloseOld + threshold_AD)
      return SIGNAL_LONG;
   
   if(Close0 < MA0 - threshold_AB && MA0 < MA1 - threshold_BC && Close0 < CloseOld - threshold_AD)
      return SIGNAL_SHORT;
   
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| FindLastValidChannel fonksiyonu (değişiklik yok)                  |
//+------------------------------------------------------------------+
bool FindLastValidChannel(int timeframe, int period, double &lastUpperBand, double &lastLowerBand)
{
   int minBarsForChannel = 3;
   int totalBars = iBars(NULL, timeframe);
   
   double tempUpper, tempLower;
   int consecutiveBars = 0;
   
   for(int i = period; i < totalBars-period; i++)
   {
      tempUpper = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, period, i));
      tempLower = iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, period, i));
      
      if(consecutiveBars == 0)
      {
         lastUpperBand = tempUpper;
         lastLowerBand = tempLower;
         consecutiveBars++;
      }
      else if(MathAbs(tempUpper - lastUpperBand) < Point && MathAbs(tempLower - lastLowerBand) < Point)
      {
         consecutiveBars++;
         if(consecutiveBars >= minBarsForChannel)
            return true;
      }
      else
      {
         consecutiveBars = 0;
      }
   }
   return false;
}


