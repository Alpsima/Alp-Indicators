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
   Print("Haber dosyası okuma başladı");
   ArrayResize(activeNews, 0);
   
   string filename = NewsFile;
   Print("Dosya yolu: ", filename);
   
   int handle = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI, ",");
   if(handle == INVALID_HANDLE)
   {
      Print("Haber dosyası açılamadı: ", filename, " - Hata kodu: ", GetLastError());
      return false;
   }
   
   Print("Dosya başarıyla açıldı");
   datetime currentTime = TimeCurrent();
   Print("Mevcut zaman: ", TimeToString(currentTime));
   
   // Başlık satırını atla
   if(FileIsEnding(handle)) 
   { 
      Print("Dosya boş");
      FileClose(handle); 
      return false; 
   }
   FileReadString(handle);
   
   while(!FileIsEnding(handle))
   {
      string dateStr = FileReadString(handle);
      string timeStr = FileReadString(handle);
      string currency = FileReadString(handle);
      string

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
   Print("Haber dosyası okuma başladı");
   ArrayResize(activeNews, 0);
   
   string filename = NewsFile;
   Print("Dosya yolu: ", filename);
   
   int handle = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI, ",");
   if(handle == INVALID_HANDLE)
   {
      Print("Haber dosyası açılamadı: ", filename, " - Hata kodu: ", GetLastError());
      return false;
   }
   
   Print("Dosya başarıyla açıldı");
   datetime currentTime = TimeCurrent();
   Print("Mevcut zaman: ", TimeToString(currentTime));
   
   // Başlık satırını atla
   if(FileIsEnding(handle)) 
   { 
      Print("Dosya boş");
      FileClose(handle); 
      return false; 
   }
   FileReadString(handle);
   
   while(!FileIsEnding(handle))
   {
      string dateStr = FileReadString(handle);
      string timeStr = FileReadString(handle);
      string currency = FileReadString(handle);
      string event = FileReadString(handle);
      string impact = FileReadString(handle);
      
      Print("Okunan haber: ", dateStr, " ", timeStr, " ", currency, " ", event, " ", impact);
      
      datetime newsTime = StrToTime(dateStr + " " + timeStr);
      Print("Çevrilen haber zamanı: ", TimeToString(newsTime));
      
      // Süresi dolmuş haberleri atla
      if(newsTime < currentTime - NewsAfterMinutes * 60) 
      {
         Print("Haber süresi dolmuş: ", TimeToString(newsTime));
         continue;
      }
      
      // Gelecek haberleri kontrol et
      if(newsTime > currentTime + 24 * 60 * 60) 
      {
         Print("Haber 24 saatten uzakta: ", TimeToString(newsTime));
         continue;
      }
      
      // Etki seviyesi kontrolü
      if(impact == "High" && !FilterHighImpact) 
      {
         Print("Yüksek etkili haber filtre edildi");
         continue;
      }
      if(impact == "Medium" && !FilterMediumImpact) 
      {
         Print("Orta etkili haber filtre edildi");
         continue;
      }
      if(impact == "Low" && !FilterLowImpact) 
      {
         Print("Düşük etkili haber filtre edildi");
         continue;
      }
      
      // Para birimi kontrolü
      if(currency != currentSymbolCurrencies[0] && 
         currency != currentSymbolCurrencies[1]) 
      {
         Print("Para birimi uyumsuz: ", currency);
         continue;
      }
      
      // Haber bilgilerini kaydet
      int idx = ArraySize(activeNews);
      ArrayResize(activeNews, idx + 1);
      activeNews[idx].time = newsTime;
      activeNews[idx].currency = currency;
      activeNews[idx].event = event;
      activeNews[idx].impact = impact;
      activeNews[idx].minutesUntil = (int)((newsTime - currentTime) / 60);
      
      Print("Haber kaydedildi: ", currency, " ", event, " - Kalan süre: ", activeNews[idx].minutesUntil, " dakika");
   }
   
   Print("Toplam ", ArraySize(activeNews), " aktif haber bulundu");
   FileClose(handle);
   return true;
}

//+------------------------------------------------------------------+
//| Risk tablosunu güncelleme fonksiyonu                              |
//+------------------------------------------------------------------+
void UpdateRiskTable()
{
   Print("Risk tablosu güncelleniyor");
   string prefix = IndicatorObjPrefix + "Risk_";
   
   // Risk tablosu başlığı
   Print("Risk tablosu başlığı oluşturuluyor");
   CreateCell(prefix + "Header", RiskTableX, RiskTableY, 
             "Risk Faktörleri", HeaderColor, TextColor);
             
   int currentRow = 1;
   int rowY = RiskTableY + currentRow * RowHeight;
   
   // Spread kontrolü
   currentSpread = MarketInfo(Symbol(), MODE_SPREAD) * Point * 10;
   Print("Mevcut spread: ", currentSpread);
   if(currentSpread > 0)
   {
      string spreadText = "Spread: " + DoubleToStr(currentSpread, 1) + " pips";
      color spreadColor = currentSpread > PipThreshold ? clrCrimson : clrForestGreen;
      Print("Spread durumu: ", spreadText, " - Renk: ", spreadColor);
      CreateCell(prefix + "Spread", RiskTableX, rowY, spreadText, 
                HeaderColor, spreadColor);
      currentRow++;
      rowY = RiskTableY + currentRow * RowHeight;
   }
   
   // Volatilite (ATR) kontrolü
   currentATR = iATR(NULL, PERIOD_CURRENT, ATR_Period, 0);
   Print("Mevcut ATR: ", currentATR);
   if(currentATR > 0)
   {
      string atrText = "ATR: " + DoubleToStr(currentATR, Digits);
      color atrColor = currentATR > PipThreshold * Point * 10 ? clrCrimson : clrForestGreen;
      Print("ATR durumu: ", atrText, " - Renk: ", atrColor);
      CreateCell(prefix + "ATR", RiskTableX, rowY, atrText, 
                HeaderColor, atrColor);
      currentRow++;
      rowY = RiskTableY + currentRow * RowHeight;
   }
   
   // Yaklaşan haberleri göster
   Print("Aktif haber sayısı: ", ArraySize(activeNews));
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
            
            Print("Haber gösteriliyor: ", newsText, " - Renk: ", newsColor);
            CreateCell(prefix + "News" + IntegerToString(i), 
                      RiskTableX, rowY, newsText, HeaderColor, newsColor);
            
            // Kalan süreyi göster
            rowY += RowHeight;
            currentRow++;
            string timeText = activeNews[i].minutesUntil > 0 ?
                           IntegerToString(activeNews[i].minutesUntil) + " dk sonra" :
                           "Şu anda aktif";
            
            Print("Zaman bilgisi gösteriliyor: ", timeText);
            CreateCell(prefix + "NewsTime" + IntegerToString(i), 
                      RiskTableX, rowY, timeText, HeaderColor, newsColor);
            
            currentRow++;
            rowY = RiskTableY + currentRow * RowHeight;
         }
      }
   }
   Print("Risk tablosu güncelleme tamamlandı");
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
//| FindLastValidChannel fonksiyonu                                    |
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
//| Signal evaluation functions                                       |
//+------------------------------------------------------------------+
int EvaluateSignal1(int dcoSignal, int con3Signal, int con4Signal)
{
   if(dcoSignal == SIGNAL_LONG && con3Signal == SIGNAL_LONG && con4Signal == SIGNAL_LONG)
      return SIGNAL_LONG;
   
   if(dcoSignal == SIGNAL_SHORT && con3Signal == SIGNAL_SHORT && con4Signal == SIGNAL_SHORT)
      return SIGNAL_SHORT;
   
   return SIGNAL_HOLD;
}

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
//| Helper functions                                                   |
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

int TimeFrameIndex(int timeframe)
{
   for(int i = 0; i < ArraySize(TimeFrames); i++)
   {
      if(TimeFrames[i] == timeframe)
         return i;
   }
   return 0;
}

color GetSignalColor(int signal)
{
   if(signal == SIGNAL_LONG) return LongColor;
   if(signal == SIGNAL_SHORT) return ShortColor;
   return HoldColor;
}

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
//| Table creation functions                                           |
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
//| Alert functions                                                    |
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
   
   // Yaklaşan haber kontrolü
   if(UseNewsFilter && hasUpcomingNews)
   {
      return; // Yaklaşan haber varsa alert verme
   }
   
   // Signal2'ye göre alert (tüm sinyaller uyumlu olmalı)
   if(dcSignal == SIGNAL_LONG && dcoSignal == SIGNAL_LONG && 
      con3Signal == SIGNAL_LONG && con4Signal == SIGNAL_LONG)
   {
      alertMessage = Symbol() + " - " + timeFrameName + " - LONG Signal: Perfect Storm";
   }
   else if(dcSignal == SIGNAL_SHORT && dcoSignal == SIGNAL_SHORT && 
           con3Signal == SIGNAL_SHORT && con4Signal == SIGNAL_SHORT)
   {
      alertMessage = Symbol() + " - " + timeFrameName + " - SHORT Signal: Perfect Storm";
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
   // Haber verilerini güncelle
   if(UseNewsFilter)
   {
      static datetime lastNewsCheck = 0;
      datetime currentTime = TimeCurrent();
      
      if(currentTime - lastNewsCheck > 300) // Her 5 dakikada bir güncelle
      {
         ReadNewsFile();
         lastNewsCheck = currentTime;
      }
   }
   
   // Risk tablosunu güncelle
   UpdateRiskTable();
   
   // Ana sinyal tablosunu oluştur
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
      double atr = iATR(NULL, timeframe, ATR_Period, 0);
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
      CreateCell("Cell_" + TimeFrameNames[i] + "_8", TableX + 8 * ColumnWidth, rowY, DoubleToStr(atr, Digits), ATRColumnColor, TextColor);
   }
   
   return(0);
}
//+------------------------------------------------------------------+







