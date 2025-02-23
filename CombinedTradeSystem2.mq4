//+------------------------------------------------------------------+
//|                                          CombinedTradeSystem.mq4   |
//|                                                                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"
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
extern double     PipThreshold      = 4;     // Pip Eşik Değeri

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
extern int        Range_Period1     = 20;    // Kısa dönem periyodu
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
extern string     FontName          = "Arial";      // Yazı Tipi
extern int        FontSize          = 7;            // Yazı Boyutu (küçültüldü)
extern int        ColumnWidth       = 50;           // Kolon Genişliği (küçültüldü)
extern int        RowHeight         = 18;           // Satır Yüksekliği (küçültüldü)

// Global Değişkenler
string           IndicatorName;
string           IndicatorObjPrefix;
int              TimeFrames[6];
string           TimeFrameNames[6];

// İndikatör tamponları
double DC20Upper[], DC20Lower[], DC20Mid[];
double DC55Upper[], DC55Lower[], DC55Mid[];
double ADXBuffer[], ADXPlusBuffer[];

// Son alert durumları takibi için
datetime LastAlertTime[];
int LastDCSignal[];

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
   
   IndicatorName = "CombinedTradeSystem";
   IndicatorObjPrefix = "##" + IndicatorName + "##";
   
   // Alert takibi için dizileri hazırla
   ArrayResize(LastAlertTime, ArraySize(TimeFrames));
   ArrayResize(LastDCSignal, ArraySize(TimeFrames));
   ArrayInitialize(LastAlertTime, 0);
   ArrayInitialize(LastDCSignal, SIGNAL_HOLD);
   
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
//| Donchian Channel Middle Line Signal                               |
//+------------------------------------------------------------------+
int CalculateDCOSignal(int timeframe)
{
   double currentClose = iClose(NULL, timeframe, 0);
   double midLine = (iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, ShortPeriod, 1)) +
                    iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, ShortPeriod, 1))) / 2;
   
   if(currentClose > midLine)
      return SIGNAL_LONG;
   else if(currentClose < midLine)
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
   
   double pipValue = PipThreshold * Point * 10;
   
   if(currentClose > lastUpperBand)
   {
      if(currentClose >= previousClose - pipValue)
         return SIGNAL_LONG;
      return SIGNAL_HOLD;
   }
   
   if(currentClose < lastLowerBand)
   {
      if(currentClose <= previousClose + pipValue)
         return SIGNAL_SHORT;
      return SIGNAL_HOLD;
   }
   
   if(currentClose > currentUpperBand - pipValue || currentClose < currentLowerBand + pipValue)
      return SIGNAL_HOLD;
      
   if(currentClose > lastUpperBand - pipValue)
   {
      if(currentClose >= previousClose)
         return SIGNAL_LONG;
      return SIGNAL_HOLD;
   }
   
   if(currentClose < lastLowerBand + pipValue)
   {
      if(currentClose <= previousClose)
         return SIGNAL_SHORT;
      return SIGNAL_HOLD;
   }
   
   return LastDCSignal[TimeFrameIndex(timeframe)];
}

//+------------------------------------------------------------------+
//| Son geçerli kanalı bulma fonksiyonu                              |
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

//+------------------------------------------------------------------+
//| Conqueror3 Sinyali Hesaplama                                      |
//+------------------------------------------------------------------+
int CalculateConqueror3Signal(int timeframe)
{
   double currentClose = iClose(NULL, timeframe, 1);
   double currentMA = iMA(NULL, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double oldMA = iMA(NULL, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, LookBack_Periods + 1);
   double oldClose = iClose(NULL, timeframe, LookBack_Close + 1);
   
   double diffCloseMA = currentClose - currentMA;
   double diffMAs = currentMA - oldMA;
   double diffCloses = currentClose - oldClose;
   
   if(diffCloseMA > 0 && diffMAs > 0 && diffCloses > 0)
      return SIGNAL_LONG;
   
   if(diffCloseMA < 0 && diffMAs < 0 && diffCloses < 0)
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
   
   if(Close0 > MA0 && MA0 > MA1 && Close0 > CloseOld)
      return SIGNAL_LONG;
   
   if(Close0 < MA0 && MA0 < MA1 && Close0 < CloseOld)
      return SIGNAL_SHORT;
   
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| Sinyal 1 Değerlendirme Fonksiyonu (DCO, CON3, CON4)              |
//+------------------------------------------------------------------+
int EvaluateSignal1(int dcoSignal, int con3Signal, int con4Signal)
{
   if(dcoSignal == SIGNAL_LONG && con3Signal == SIGNAL_LONG && con4Signal == SIGNAL_LONG)
      return SIGNAL_LONG;
   
   if(dcoSignal == SIGNAL_SHORT && con3Signal == SIGNAL_SHORT && con4Signal == SIGNAL_SHORT)
      return SIGNAL_SHORT;
   
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| Sinyal 2 Değerlendirme Fonksiyonu (DC, DCO, CON3, CON4)          |
//+------------------------------------------------------------------+
int EvaluateSignal2(int dcSignal, int dcoSignal, int con3Signal, int con4Signal)
{
   if(dcSignal == SIGNAL_LONG && dcoSignal == SIGNAL_LONG && 
      con3Signal == SIGNAL_LONG && con4Signal == SIGNAL_LONG)
      return SIGNAL_LONG;
   
   if(dcSignal == SIGNAL_SHORT && dcoSignal == SIGNAL_SHORT && 
      con3Signal == SIGNAL_SHORT && con4Signal == SIGNAL_SHORT)
      return SIGNAL_SHORT;
   
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| Create cell object                                                |
//+------------------------------------------------------------------+
void CreateCell(string name, int x, int y, string text, color bgColor, color txtColor)
{
   string objName = IndicatorObjPrefix + name;
   
   if(ObjectFind(objName + "BG") < 0)
      ObjectCreate(0, objName + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   
   ObjectSet(objName + "BG", OBJPROP_XDISTANCE, x);
   ObjectSet(objName + "BG", OBJPROP_YDISTANCE, y);
   ObjectSet(objName + "BG", OBJPROP_XSIZE, ColumnWidth);
   ObjectSet(objName + "BG", OBJPROP_YSIZE, RowHeight);
   ObjectSet(objName + "BG", OBJPROP_BGCOLOR, bgColor);
   ObjectSet(objName + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(objName + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   
   if(ObjectFind(objName + "TEXT") < 0)
      ObjectCreate(0, objName + "TEXT", OBJ_LABEL, 0, 0, 0);
   
   ObjectSet(objName + "TEXT", OBJPROP_XDISTANCE, x + 5);
   ObjectSet(objName + "TEXT", OBJPROP_YDISTANCE, y + 4);
   ObjectSetText(objName + "TEXT", text, FontSize, FontName, txtColor);
   ObjectSet(objName + "TEXT", OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Timeframe string dönüştürme yardımcı fonksiyonu                  |
//+------------------------------------------------------------------+
string TimeframeToString(int timeframe)
{
   switch(timeframe)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
      default: return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Timeframe dizin bulma yardımcı fonksiyonu                        |
//+------------------------------------------------------------------+
int TimeFrameIndex(int timeframe)
{
   for(int i = 0; i < ArraySize(TimeFrames); i++)
   {
      if(TimeFrames[i] == timeframe)
         return i;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Renk Döndürme Fonksiyonu                                          |
//+------------------------------------------------------------------+
color GetSignalColor(int signal)
{
   if(signal == SIGNAL_LONG) return LongColor;
   if(signal == SIGNAL_SHORT) return ShortColor;
   return HoldColor;
}

//+------------------------------------------------------------------+
//| Create main table                                                 |
//+------------------------------------------------------------------+
void CreateMainTable()
{
   string headers[9] = {"TF", "DC", "DCO", "CON3", "CON4", "Signal1", "Signal2", "ADX", "ATR"};
   int totalColumns = ArraySize(headers);
   
   for(int col = 0; col < totalColumns; col++)
   {
      CreateCell("Header_" + IntegerToString(col), 
                TableX + col * ColumnWidth, 
                TableY, 
                headers[col], 
                HeaderColor, 
                TextColor);
   }
   
   for(int row = 0; row < ArraySize(TimeFrames); row++)
   {
      CreateCell("TF_" + TimeFrameNames[row], 
                TableX, 
                TableY + (row + 1) * RowHeight,
                TimeFrameNames[row],
                HeaderColor,
                TextColor);
                
      for(int col = 1; col < totalColumns; col++)
      {
         CreateCell("Cell_" + TimeFrameNames[row] + "_" + IntegerToString(col),
                   TableX + col * ColumnWidth,
                   TableY + (row + 1) * RowHeight,
                   "",
                   clrWhite,
                   clrBlack);
      }
   }
}

//+------------------------------------------------------------------+
//| Alert Kontrolü ve Sinyal Değerlendirme                           |
//+------------------------------------------------------------------+
void CheckAndAlert(string timeFrameName, int tfIndex, int dcSignal, int dcoSignal, 
                  int con3Signal, int con4Signal)
{
   if(iVolume(NULL, TimeFrames[tfIndex], 0) > 1) return;
   
   static datetime lastGlobalAlertTime = 0;
   datetime currentTime = TimeCurrent();
   
   if(currentTime - lastGlobalAlertTime < 300) return;
   
   if(LastDCSignal[tfIndex] == dcSignal && 
      currentTime - LastAlertTime[tfIndex] < PeriodSeconds(TimeFrames[tfIndex])) 
      return;
   
   string alertMessage = "";
   
   // Signal2'ye göre alert (tüm sinyaller uyumlu olmalı)
   if(dcSignal == SIGNAL_LONG && dcoSignal == SIGNAL_LONG && 
      con3Signal == SIGNAL_LONG && con4Signal == SIGNAL_LONG)
   {
      alertMessage = Symbol() + " - " + timeFrameName + " - LONG Signal: All indicators aligned bullish";
   }
   else if(dcSignal == SIGNAL_SHORT && dcoSignal == SIGNAL_SHORT && 
           con3Signal == SIGNAL_SHORT && con4Signal == SIGNAL_SHORT)
   {
      alertMessage = Symbol() + " - " + timeFrameName + " - SHORT Signal: All indicators aligned bearish";
   }
   
   if(StringLen(alertMessage) > 0)
   {
      if(EnableSoundAlert) Alert(alertMessage);
      if(EnablePopupAlert) MessageBox(alertMessage, "Signal Alert", MB_OK|MB_ICONINFORMATION);
      
      lastGlobalAlertTime = currentTime;
      LastAlertTime[tfIndex] = currentTime;
      LastDCSignal[tfIndex] = dcSignal;
   }
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                                |
//+------------------------------------------------------------------+
int start()
{
   CreateMainTable();
   
   for(int i = 0; i < ArraySize(TimeFrames); i++)
   {
      int timeframe = TimeFrames[i];
      
      // DC sinyallerini hesapla
      int dcSignalShort = CalculateDCSignal(timeframe, ShortPeriod);
      int dcSignalLong = CalculateDCSignal(timeframe, LongPeriod);

      // DC sinyal durumunu belirle
      int dcSignal;
      if(dcSignalShort == SIGNAL_LONG && dcSignalLong == SIGNAL_LONG)
         dcSignal = SIGNAL_LONG;
      else if(dcSignalShort == SIGNAL_SHORT && dcSignalLong == SIGNAL_SHORT)
         dcSignal = SIGNAL_SHORT;
      else
         dcSignal = SIGNAL_HOLD;
      
      // Diğer sinyalleri hesapla
      int dcoSignal = CalculateDCOSignal(timeframe);
      int con3Signal = CalculateConqueror3Signal(timeframe);
      int con4Signal = CalculateConqueror4Signal(timeframe);
      
      // Signal1 ve Signal2'yi hesapla
      int signal1 = EvaluateSignal1(dcoSignal, con3Signal, con4Signal);
      int signal2 = EvaluateSignal2(dcSignal, dcoSignal, con3Signal, con4Signal);
      
      // Alert kontrolü
      CheckAndAlert(TimeFrameNames[i], i, dcSignal, dcoSignal, con3Signal, con4Signal);
      
      // İndikatör değerlerini hesapla
      double atr = iATR(NULL, timeframe, 14, 0);
      double adx = iADX(NULL, timeframe, 14, PRICE_CLOSE, MODE_MAIN, 0);
      
      // Sinyal renklerini belirle
      color dcColor = GetSignalColor(dcSignal);
      color dcoColor = GetSignalColor(dcoSignal);
      color con3Color = GetSignalColor(con3Signal);
      color con4Color = GetSignalColor(con4Signal);
      color signal1Color = GetSignalColor(signal1);
      color signal2Color = GetSignalColor(signal2);
      
      // ADX renk kontrolü
      color adxColor = clrWhite;
      if(adx >= 27) adxColor = LongColor;
      else if(adx >= 20) adxColor = HoldColor;
      else adxColor = ShortColor;
      
      // Tablo hücrelerini güncelle
      int rowY = TableY + (i + 1) * RowHeight;
      
      // Signal metinlerini belirle
      string dcText = (dcSignal == SIGNAL_LONG) ? "L" : (dcSignal == SIGNAL_SHORT) ? "S" : "H";
      string dcoText = (dcoSignal == SIGNAL_LONG) ? "L" : (dcoSignal == SIGNAL_SHORT) ? "S" : "H";
      string con3Text = (con3Signal == SIGNAL_LONG) ? "L" : (con3Signal == SIGNAL_SHORT) ? "S" : "H";
      string con4Text = (con4Signal == SIGNAL_LONG) ? "L" : (con4Signal == SIGNAL_SHORT) ? "S" : "H";
      string signal1Text = (signal1 == SIGNAL_LONG) ? "L" : (signal1 == SIGNAL_SHORT) ? "S" : "H";
      string signal2Text = (signal2 == SIGNAL_LONG) ? "L" : (signal2 == SIGNAL_SHORT) ? "S" : "H";
      
      // Hücreleri güncelle
      CreateCell("Cell_" + TimeFrameNames[i] + "_1", TableX + ColumnWidth, rowY, dcText, dcColor, TextColor);
      CreateCell("Cell_" + TimeFrameNames[i] + "_2", TableX + 2 * ColumnWidth, rowY, dcoText, dcoColor, TextColor);
      CreateCell("Cell_" + TimeFrameNames[i] + "_3", TableX + 3 * ColumnWidth, rowY, con3Text, con3Color, TextColor);
      CreateCell("Cell_" + TimeFrameNames[i] + "_4", TableX + 4 * ColumnWidth, rowY, con4Text, con4Color, TextColor);
      CreateCell("Cell_" + TimeFrameNames[i] + "_5", TableX + 5 * ColumnWidth, rowY, signal1Text, signal1Color, TextColor);
      CreateCell("Cell_" + TimeFrameNames[i] + "_6", TableX + 6 * ColumnWidth, rowY, signal2Text, signal2Color, TextColor);
      CreateCell("Cell_" + TimeFrameNames[i] + "_7", TableX + 7 * ColumnWidth, rowY, DoubleToStr(adx, 1), adxColor, TextColor);
      CreateCell("Cell_" + TimeFrameNames[i] + "_8", TableX + 8 * ColumnWidth, rowY, DoubleToStr(atr, Digits), clrWhite, clrBlack);
   }
   
   return(0);
}
//+------------------------------------------------------------------+



