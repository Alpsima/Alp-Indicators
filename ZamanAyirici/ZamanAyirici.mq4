//+------------------------------------------------------------------+
//|                                                ZamanAyirici.mq4  |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property strict

extern color LineColor = clrRed;       // Çizgi rengi
extern int   LineWidth = 1;            // Çizgi kalınlığı
extern int   DaysToDraw = 5;          // Geriye dönük gün sayısı
extern int   DayStartHour = 1;        // Gün başlangıç saati (varsayılan 01:00)
extern ENUM_LINE_STYLE LineStyle = STYLE_SOLID;  // Çizgi stili

int lastPeriod = 0;

int init()
{
   // Saat değeri kontrolü
   if(DayStartHour < 0 || DayStartHour > 23)
   {
      Alert("Gün başlangıç saati 0-23 arasında olmalıdır!");
      return(INIT_FAILED);
   }
   
   // Mevcut zaman dilimini kaydet
   lastPeriod = Period();
   // Çizgileri çiz
   RedrawLines();
   return(0);
}

int deinit()
{
   // İndikatör kaldırıldığında çizgileri sil
   RemoveLines();
   return(0);
}

int start()
{
   // Zaman dilimi değiştiyse
   if(Period() != lastPeriod)
   {
      lastPeriod = Period();
      RemoveLines();
      RedrawLines();
   }
   return(0);
}

void RedrawLines()
{
   // Sadece H1 ve daha küçük zaman dilimlerinde çalış
   if(Period() > PERIOD_H1)
   {
      RemoveLines(); // Daha yüksek zaman dilimlerinde çizgileri sil
      return;
   }

   // Önceki çizgileri temizle
   RemoveLines();

   // Şu anki zamanı al
   datetime now = TimeCurrent();
   
   // Günün başlangıç saatine göre (örn. 01:00) midnight zamanını hesapla
   datetime midnight = now - (now % 86400) + DayStartHour * 3600;
   
   // Eğer şu anki zaman, bugünün başlangıç saatinden önceyse
   // bir önceki günün başlangıç saatini al
   if(now < midnight)
      midnight -= 86400;

   // Geriye dönük çizgileri ekle
   for(int i = 0; i <= DaysToDraw; i++)
   {
      datetime lineTime = midnight - i * 86400;
      if(lineTime < Time[Bars - 1])
         break; // Grafiğin başlangıcını aştıysa döngüyü sonlandır

      string name = "ZamanV" + IntegerToString(i);
      if(ObjectFind(name) != 0)
      {
         ObjectCreate(name, OBJ_VLINE, 0, lineTime, 0);

         // Çizgi özellikleri
         ObjectSet(name, OBJPROP_COLOR, LineColor);
         ObjectSet(name, OBJPROP_WIDTH, LineWidth);
         ObjectSet(name, OBJPROP_STYLE, LineStyle);  // Burada değişiklik yapıldı
         ObjectSet(name, OBJPROP_BACK, true);          // Çizgiyi arka plana gönder
         ObjectSet(name, OBJPROP_SELECTABLE, false);   // Çizgiyi seçilemez yap
         ObjectSetText(name, "");                      // Çizgi ismini boş bırak
      }
   }
}

void RemoveLines()
{
   int totalObjects = ObjectsTotal();
   for(int i = totalObjects - 1; i >= 0; i--)
   {
      string objName = ObjectName(i);
      if(StringSubstr(objName, 0, 6) == "ZamanV") // "ZamanV" ile başlayan objeler
         ObjectDelete(objName);
   }
}
//+------------------------------------------------------------------+
