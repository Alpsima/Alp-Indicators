//+------------------------------------------------------------------+
//|                                   CombinedTradeSystemSummary3.mq4   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window

// Görünüm Ayarları
extern color      HeaderColor       = C'40,40,40';  // Başlık Rengi
extern color      TextColor         = clrWhite;     // Yazı Rengi 
extern color      LongColor        = clrForestGreen;   // Long Sinyal Rengi
extern color      ShortColor       = clrCrimson;       // Short Sinyal Rengi
extern color      HoldColor        = clrRoyalBlue;     // Hold Sinyal Rengi
extern string     FontName         = "Arial";      // Yazı Tipi
extern int        FontSize         = 7;            // Yazı Boyutu
extern int        DistributionFontSize = 8;        // Dağılım Yazı Boyutu
extern color      DistributionTextColor = clrWhite; // Dağılım Yazı Rengi
extern int        ColumnWidth      = 50;           // Kolon Genişliği
extern int        RowHeight        = 18;           // Satır Yüksekliği
extern int        TableSpacingX    = 100;          // Tablolar arası yatay boşluk
extern int        TableSpacingY    = 80;           // Tablolar arası dikey boşluk
extern int        TablesPerRow     = 4;            // Her satırdaki tablo sayısı
extern int        TableX          = 75;            // İlk tablo X pozisyonu
extern int        TableY          = 50;            // İlk tablo Y pozisyonu
extern int        TitleFontSize    = 10;           // Başlık yazı boyutu
extern int        TitleSpacing     = 40;           // Başlık-tablo arası mesafe
extern color      BackgroundColor  = clrWhite;     // Arka plan rengi
extern color      TitleColor       = clrYellow;    // Başlık rengi

// ATR Bazlı Eşik Ayarları
extern string     ATRSettings       = "===== ATR Ayarları =====";
extern int        ATR_Period        = 14;    // ATR Periyodu
extern double     Mult_AB           = 0.5;   // (A-B) için ATR çarpanı
extern double     Mult_BC           = 0.4;   // (B-C) için ATR çarpanı
extern double     Mult_AD           = 0.6;   // (A-D) için ATR çarpanı

// İndikatör Ayarları
extern string     IndicatorSettings = "===== İndikatör Ayarları =====";
extern int        ShortPeriod      = 20;    // Kısa Donchian Periyodu
extern int        LongPeriod       = 55;    // Uzun Donchian Periyodu
extern int        MVA_Period       = 10;    // Moving Average periyodu
extern int        LookBack_Periods = 20;    // MA karşılaştırma periyodu
extern int        LookBack_Close   = 40;    // Kapanış karşılaştırma periyodu
extern int        Con4_MVA_Period  = 10;    // Conqueror4 MA periyodu
extern int        Range_Period1    = 25;    // Kısa dönem periyodu
extern int        Range_Period2    = 55;    // Uzun dönem periyodu
extern int        ADX_Period       = 14;    // ADX Periyodu
extern double     ADX_Threshold    = 27.0;  // ADX Eşik Değeri

// Timeframe Ağırlık Ayarları
extern string     WeightSettings    = "===== Timeframe Ağırlıkları =====";
extern double     Weight_W1        = 30.0;  // W1 Timeframe Ağırlığı (%)
extern double     Weight_D1        = 25.0;  // D1 Timeframe Ağırlığı (%)
extern double     Weight_H4        = 20.0;  // H4 Timeframe Ağırlığı (%)
extern double     Weight_H1        = 15.0;  // H1 Timeframe Ağırlığı (%)
extern double     Weight_M30       = 7.0;   // M30 Timeframe Ağırlığı (%)
extern double     Weight_M15       = 3.0;   // M15 Timeframe Ağırlığı (%)

// Dağılım Formatı Ayarları
extern string     DistributionSettings = "===== Dağılım Formatı =====";
extern int        DistributionPrecision = 0;    // Dağılım yüzde hassasiyeti
extern string     DistributionPrefix = "D%: ";   // Dağılım başlık öneki
extern int        DistributionSpacing = 2;      // Dağılım değerleri arası boşluk

// Sabitler
#define SIGNAL_LONG    1
#define SIGNAL_SHORT  -1
#define SIGNAL_HOLD    0

// Global Değişkenler
string           IndicatorName = "CombinedTradeSystemSummary";
string           IndicatorObjPrefix;
string           ActiveSymbols[];
double           DummyBuffer[];

// Timeframe Bilgileri
string           TimeframeList[6] = {"W", "D", "4H", "1H", "30M", "15M"};
int              TimeframeValues[6] = {PERIOD_W1, PERIOD_D1, PERIOD_H4, PERIOD_H1, PERIOD_M30, PERIOD_M15};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                           |
//+------------------------------------------------------------------+
int init()
{
   // Önce tüm nesneleri temizle
   ObjectsDeleteAll(0, IndicatorObjPrefix);
   
   IndicatorObjPrefix = "##" + IndicatorName + "##";
   
   // Boş buffer ayarla (indikatör gereksinimi için)
   ArrayInitialize(DummyBuffer, 0);
   SetIndexBuffer(0, DummyBuffer);
   SetIndexStyle(0, DRAW_NONE);
   
   // Gösterge penceresini ayarla
   IndicatorShortName(IndicatorName);
   IndicatorDigits(1);
   
   // Arka plan rengini ayarla
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, BackgroundColor);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                         |
//+------------------------------------------------------------------+
int deinit()
{
   Print("İndikatör kapatılıyor... Nesneler temizleniyor...");
   ObjectsDeleteAll(0, IndicatorObjPrefix);
   return(0);
}

//+------------------------------------------------------------------+
//| Donchian Channel Middle Line Signal                               |
//+------------------------------------------------------------------+
int CalculateDCOSignal(string symbol, int timeframe)
{
   double currentClose = iClose(symbol, timeframe, 0);
   double midLine = (iHigh(symbol, timeframe, iHighest(symbol, timeframe, MODE_HIGH, ShortPeriod, 1)) +
                    iLow(symbol, timeframe, iLowest(symbol, timeframe, MODE_LOW, ShortPeriod, 1))) / 2;
   
   double atr = iATR(symbol, timeframe, ATR_Period, 0);
   double threshold = atr * Mult_AB;
   
   if(currentClose > midLine + threshold)
      return SIGNAL_LONG;
   else if(currentClose < midLine - threshold)
      return SIGNAL_SHORT;
         
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| Donchian Channel Sinyali                                          |
//+------------------------------------------------------------------+
int CalculateDCSignal(string symbol, int timeframe)
{   
   if(iVolume(symbol, timeframe, 0) > 1)
      return SIGNAL_HOLD;
      
   double currentClose = iClose(symbol, timeframe, 0);
   double previousClose = iClose(symbol, timeframe, 1);
   
   double currentUpperBand = iHigh(symbol, timeframe, iHighest(symbol, timeframe, MODE_HIGH, ShortPeriod, 1));
   double currentLowerBand = iLow(symbol, timeframe, iLowest(symbol, timeframe, MODE_LOW, ShortPeriod, 1));
   
   double lastUpperBand, lastLowerBand;
   if(!FindLastValidChannel(symbol, timeframe, ShortPeriod, lastUpperBand, lastLowerBand))
   {
      lastUpperBand = currentUpperBand;
      lastLowerBand = currentLowerBand;
   }
   
   double atr = iATR(symbol, timeframe, ATR_Period, 0);
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
   
   return SIGNAL_HOLD;
}

//+------------------------------------------------------------------+
//| Conqueror3 Sinyali                                                |
//+------------------------------------------------------------------+
int CalculateConqueror3Signal(string symbol, int timeframe)
{
   double currentClose = iClose(symbol, timeframe, 1);
   double currentMA = iMA(symbol, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   double oldMA = iMA(symbol, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, LookBack_Periods + 1);
   double oldClose = iClose(symbol, timeframe, LookBack_Close + 1);
   
   double atr = iATR(symbol, timeframe, ATR_Period, 0);
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
//| Conqueror4 Sinyali                                                |
//+------------------------------------------------------------------+
int CalculateConqueror4Signal(string symbol, int timeframe)
{
   double MA0 = iMA(symbol, timeframe, Con4_MVA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA1 = iMA(symbol, timeframe, Con4_MVA_Period, 0, MODE_SMA, PRICE_CLOSE, Range_Period1);
   double Close0 = iClose(symbol, timeframe, 0);
   double CloseOld = iClose(symbol, timeframe, Range_Period2);
   
   double atr = iATR(symbol, timeframe, ATR_Period, 0);
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
//| FindLastValidChannel fonksiyonu                                    |
//+------------------------------------------------------------------+
bool FindLastValidChannel(string symbol, int timeframe, int period, double &lastUpperBand, double &lastLowerBand)
{
   int minBarsForChannel = 3;
   int totalBars = iBars(symbol, timeframe);
   
   double tempUpper, tempLower;
   int consecutiveBars = 0;
   
   for(int i = period; i < totalBars-period; i++)
   {
      tempUpper = iHigh(symbol, timeframe, iHighest(symbol, timeframe, MODE_HIGH, period, i));
      tempLower = iLow(symbol, timeframe, iLowest(symbol, timeframe, MODE_LOW, period, i));
      
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
//| Signal Değerlendirme Fonksiyonları                                |
//+------------------------------------------------------------------+
void GetSignalState(string symbol, int timeframe, int &signals[])
{
   ArrayResize(signals, 7);
   
   // DC Sinyali
   signals[0] = CalculateDCSignal(symbol, timeframe);
   
   // DCO Sinyali
   signals[1] = CalculateDCOSignal(symbol, timeframe);
   
   // CON3 Sinyali
   signals[2] = CalculateConqueror3Signal(symbol, timeframe);

   // CON4 Sinyali
   signals[3] = CalculateConqueror4Signal(symbol, timeframe);
   
   // Signal1 (DCO, CON3, CON4)
   signals[4] = EvaluateSignal1(signals[1], signals[2], signals[3]);
   
   // Signal2 (DC, DCO, CON3, CON4)
   signals[5] = EvaluateSignal2(signals[0], signals[1], signals[2], signals[3]);
   
   // ADX - Doğrudan iADX değerini alıyoruz
   signals[6] = (int)(iADX(symbol, timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0) * 100);  // 100 ile çarpıp tam sayı yapıyoruz
}

//+------------------------------------------------------------------+
//| Signal1 Değerlendirme (DCO, CON3, CON4)                          |
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
//| Signal2 Değerlendirme (DC, DCO, CON3, CON4)                      |
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
//| Aktif grafikleri tespit et                                        |
//+------------------------------------------------------------------+
void DetectActiveCharts()
{
   ArrayResize(ActiveSymbols, 0);
   int symbolCount = 0;
   
   long chartID = ChartFirst();
   while(chartID >= 0)
   {
      string symbol = ChartSymbol(chartID);
      
      // CombinedTradeSystem yüklenmiş mi kontrol et
      if(HasCombinedTradeSystem(symbol, chartID))
      {
         // Sembol zaten listeye eklendi mi kontrol et
         bool exists = false;
         for(int i = 0; i < ArraySize(ActiveSymbols); i++)
         {
            if(ActiveSymbols[i] == symbol)
            {
               exists = true;
               break;
            }
         }
         
         // Yeni sembol ise listeye ekle
         if(!exists)
         {
            ArrayResize(ActiveSymbols, symbolCount + 1);
            ActiveSymbols[symbolCount] = symbol;
            symbolCount++;
         }
      }
      
      chartID = ChartNext(chartID);
   }
}

//+------------------------------------------------------------------+
//| CombinedTradeSystem kontrolü                                      |
//+------------------------------------------------------------------+
bool HasCombinedTradeSystem(string symbol, long chartID)
{
   // Grafikteki indikatörleri kontrol et
   int total = ChartIndicatorsTotal(chartID, 0);
   for(int i = 0; i < total; i++)
   {
      string indName = ChartIndicatorName(chartID, 0, i);
      if(StringFind(indName, "CombinedTradeSystem") >= 0)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Ağırlıklı sinyal dağılımını hesapla                              |
//+------------------------------------------------------------------+
void CalculateWeightedSignalDistribution(string symbol, double &longPercent, double &shortPercent, double &holdPercent)
{
    double weights[6];
    weights[0] = Weight_W1;
    weights[1] = Weight_D1;
    weights[2] = Weight_H4;
    weights[3] = Weight_H1;
    weights[4] = Weight_M30;
    weights[5] = Weight_M15;
    
    double weightedLong = 0, weightedShort = 0, weightedHold = 0;
    
    // Her timeframe için ağırlıklı hesaplama
    for(int tf = 0; tf < ArraySize(TimeframeList); tf++)
    {
        int signals[];
        GetSignalState(symbol, TimeframeValues[tf], signals);
        
        // Sadece DCO, CON3 ve CON4 sinyalleri için (index 1,2,3)
        for(int i = 1; i <= 3; i++)
        {
            double weight = weights[tf] / 3.0;  // Her indikatör için ağırlığı 3'e böl
            
            if(signals[i] == SIGNAL_LONG) weightedLong += weight;
            else if(signals[i] == SIGNAL_SHORT) weightedShort += weight;
            else weightedHold += weight;
        }
    }
    
    // Sonuçları ata
    longPercent = weightedLong;
    shortPercent = weightedShort;
    holdPercent = weightedHold;
}

//+------------------------------------------------------------------+
//| Tablo pozisyonunu hesapla                                         |
//+------------------------------------------------------------------+
void CalculateTablePosition(int index, int &x, int &y)
{
   int row = index / TablesPerRow;
   int col = index % TablesPerRow;
   
   // Tek tablonun toplam genişliği
   int totalWidth = 8 * ColumnWidth;  // 8 sütun
   
   x = TableX + col * (totalWidth + TableSpacingX);
   y = TableY + row * ((ArraySize(TimeframeList) + 1) * RowHeight + TitleSpacing + TableSpacingY);
}

//+------------------------------------------------------------------+
//| Tablo oluşturma fonksiyonu                                        |
//+------------------------------------------------------------------+
void CreateTable(string symbol, int baseX, int baseY)
{
   // Başlıklar
   string headers[8] = {"TF", "DC", "DCO", "CON3", "CON4", "Sig1", "Sig2", "ADX"};
   
   // Sembol başlığı - daha belirgin ve daha yüksekte
   CreateLabel(symbol + "_Title", symbol, baseX, baseY - TitleSpacing, TitleFontSize, TitleColor);
   
   // Başlık satırı
   for(int i = 0; i < ArraySize(headers); i++)
   {
      CreateTableCell(symbol + "_Header_" + IntegerToString(i), 
                     headers[i], 
                     baseX + i * ColumnWidth, 
                     baseY, 
                     HeaderColor);
   }
   
   // Her timeframe için sinyal değerlerini al ve göster
   for(int row = 0; row < ArraySize(TimeframeList); row++)
   {
      int y = baseY + (row + 1) * RowHeight;
      int signals[7];  // DC, DCO, CON3, CON4, Sig1, Sig2, ADX
      
      GetSignalState(symbol, TimeframeValues[row], signals);
      
      // Timeframe sütunu
      CreateTableCell(symbol + "_TF_" + IntegerToString(row), 
                     TimeframeList[row], 
                     baseX, 
                     y, 
                     HeaderColor);
      
      // Sinyal sütunları
      for(int col = 0; col < 6; col++)
      {
         string signalText = (signals[col] == SIGNAL_LONG) ? "L" : 
                            (signals[col] == SIGNAL_SHORT) ? "S" : "H";
         color signalColor = (signals[col] == SIGNAL_LONG) ? LongColor :
                            (signals[col] == SIGNAL_SHORT) ? ShortColor : HoldColor;
                            
         CreateTableCell(symbol + "_Data_" + IntegerToString(row) + "_" + IntegerToString(col), 
                        signalText,
                        baseX + (col + 1) * ColumnWidth,
                        y,
                        signalColor);
      }
      
      // ADX sütunu
      double adx = signals[6] / 100.0;  // Tam sayıdan geri double'a çeviriyoruz
      color adxColor = (adx >= ADX_Threshold) ? LongColor : 
                      ((adx >= 20.0) ? HoldColor : ShortColor);
      
      CreateTableCell(symbol + "_Data_" + IntegerToString(row) + "_6",
                     DoubleToStr(adx, 1),  // Bir ondalık basamak gösteriyoruz
                     baseX + 7 * ColumnWidth,
                     y,
                     adxColor);
   }
   
   // Dağılım bilgisini ekle
   double longPercent = 0, shortPercent = 0, holdPercent = 0;
   CalculateWeightedSignalDistribution(symbol, longPercent, shortPercent, holdPercent);
   
   string distribution = DistributionPrefix + 
                        "L(" + DoubleToStr(MathRound(longPercent), DistributionPrecision) + ")" + 
                        StringRepeat(" ", DistributionSpacing) +
                        "S(" + DoubleToStr(MathRound(shortPercent), DistributionPrecision) + ")" +
                        StringRepeat(" ", DistributionSpacing) +
                        "H(" + DoubleToStr(MathRound(holdPercent), DistributionPrecision) + ")";
                        
   CreateLabel(symbol + "_Distribution", distribution,
               baseX, baseY + (ArraySize(TimeframeList) + 2) * RowHeight,
               DistributionFontSize, DistributionTextColor);
}

//+------------------------------------------------------------------+
//| Tek hücre oluşturma fonksiyonu                                    |
//+------------------------------------------------------------------+
void CreateTableCell(string name, string text, int x, int y, color bgColor)
{
   string objName = IndicatorObjPrefix + name;
   
   // Arka plan dikdörtgeni
   if(ObjectFind(0, objName + "BG") < 0)
      ObjectCreate(0, objName + "BG", OBJ_RECTANGLE_LABEL, 1, 0, 0);
      
   ObjectSetInteger(0, objName + "BG", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName + "BG", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName + "BG", OBJPROP_XSIZE, ColumnWidth);
   ObjectSetInteger(0, objName + "BG", OBJPROP_YSIZE, RowHeight);
   ObjectSetInteger(0, objName + "BG", OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, objName + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, objName + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   
   // Metin etiketi
   CreateLabel(name + "_Text", text, x + 5, y + 2, FontSize, TextColor);
}

//+------------------------------------------------------------------+
//| Etiket oluşturma fonksiyonu                                       |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, int fontSize, color textColor)
{
   string objName = IndicatorObjPrefix + name;
   
   if(ObjectFind(0, objName) < 0)
      ObjectCreate(0, objName, OBJ_LABEL, 1, 0, 0);
      
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetString(0, objName, OBJPROP_FONT, FontName);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                                |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   static datetime lastUpdate = 0;
   datetime currentTime = TimeCurrent();
   
   // Her saniyede bir güncelle
   if(currentTime - lastUpdate < 1) return(rates_total);
   lastUpdate = currentTime;
   
   // Mevcut objeleri temizle
   ObjectsDeleteAll(0, IndicatorObjPrefix);
   
   // Aktif grafikleri tespit et
   DetectActiveCharts();
   
   // Her sembol için tablo oluştur
   for(int i = 0; i < ArraySize(ActiveSymbols); i++)
   {
      int x, y;
      CalculateTablePosition(i, x, y);
      CreateTable(ActiveSymbols[i], x, y);
   }
   
   return(rates_total);
}
//+------------------------------------------------------------------+







