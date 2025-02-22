//+------------------------------------------------------------------+
//|                                                    Conqueror6.mq4 |
//|                                            Copyright 2024, Your Name |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 Green
#property indicator_color2 Red
#property indicator_color3 Blue
#property indicator_color4 clrDarkGray
#property indicator_minimum 0
#property indicator_maximum 1.2

#define HISTOGRAM_HEIGHT 1.0

// Hesaplama Parametreleri
extern int Max_Bars = 300;         // Hesaplanacak maksimum mum sayısı
extern int MVA_Period = 10;        // MA periyodu
extern int Range_Period1 = 25;     // İlk MA karşılaştırma periyodu
extern int Range_Period2 = 55;     // Fiyat karşılaştırma periyodu
extern int ATR_Period = 14;        // ATR periyodu

// ATR Çarpanları
extern double Mult_AB = 0.5;       // A-B için ATR çarpanı
extern double Mult_BC = 0.4;       // B-C için ATR çarpanı
extern double Mult_AD = 0.6;       // A-D için ATR çarpanı

// Moving Average Ayarları
extern color MA_Color = clrDarkGray;  
extern int MA_Width = 1;             

// Arrow Ayarları
extern bool Show_Arrows = true;      

// Tablo görünüm ayarları
extern int X_Coord = 1710;         
extern int Y_Coord = 210;          
extern int TF_Column_Width = 60;   
extern int Value_Column_Width = 60;
extern int Row_Height = 25;       
extern string Font_Type = "Arial"; 
extern int Font_Size = 8;         
extern color Font_Color = Black;   
extern color TF_Header_Back = C'40,40,40';
extern color TF_Header_Text = White;      
extern color Row_Border_Color = White;     
extern color TF_Column_Back = White;       
extern color TF_Column_Text = Black;       

// Gösterge tamponları
double Up[];
double Dn[];
double Neutral[];
double MA_Buffer[];

// Global değişkenler
string IndicatorName;
string IndicatorObjPrefix;

//+------------------------------------------------------------------+
int init()
{
   IndicatorName = "Conqueror6";
   IndicatorObjPrefix = "__" + IndicatorName + "__";
   IndicatorShortName(IndicatorName);
   
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, Up);
   SetIndexLabel(0, "Up");
   
   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(1, Dn);
   SetIndexLabel(1, "Down");
   
   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(2, Neutral);
   SetIndexLabel(2, "Neutral");
   
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, MA_Width, MA_Color);
   SetIndexBuffer(3, MA_Buffer);
   SetIndexLabel(3, "MA");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
int deinit()
{
   ObjectsDeleteAll(ChartID(), IndicatorObjPrefix);
   return(0);
}

//+------------------------------------------------------------------+
color GetTimeframeColor(int timeframe)
{
   double MA0 = iMA(NULL, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   double MA1 = iMA(NULL, timeframe, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, Range_Period1);
   double Close0 = iClose(NULL, timeframe, 0);
   double CloseOld = iClose(NULL, timeframe, Range_Period2);
   double ATR = iATR(NULL, timeframe, ATR_Period, 0);
   
   // ATR bazlı kontroller
   double diff_ab = Close0 - MA0;
   double diff_bc = MA0 - MA1;
   double diff_ad = Close0 - CloseOld;
   
   if(diff_ab > (ATR * Mult_AB) && 
      diff_bc > (ATR * Mult_BC) && 
      diff_ad > (ATR * Mult_AD))
      return indicator_color1;
   else if(diff_ab < -(ATR * Mult_AB) && 
           diff_bc < -(ATR * Mult_BC) && 
           diff_ad < -(ATR * Mult_AD))
      return indicator_color2;
   else
      return indicator_color3;
}

//+------------------------------------------------------------------+
void DrawTimeframeTable()
{
   string timeframes[6] = {"M15", "M30", "H1", "H4", "D1", "W1"};
   int tf_values[6] = {PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1};
   
   int total_width = TF_Column_Width + Value_Column_Width;
   int total_height = 7 * Row_Height;
   
   string bgName = IndicatorObjPrefix + "TF_BG";
   if(ObjectFind(bgName) < 0)
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(bgName, OBJPROP_XDISTANCE, X_Coord);
   ObjectSet(bgName, OBJPROP_YDISTANCE, Y_Coord);
   ObjectSet(bgName, OBJPROP_XSIZE, total_width);
   ObjectSet(bgName, OBJPROP_YSIZE, total_height);
   ObjectSet(bgName, OBJPROP_BGCOLOR, TF_Header_Back);
   ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   
   for(int i = 0; i < 6; i++)
   {
      int y_pos = Y_Coord + (i + 1) * Row_Height;
      
      string tfBgName = IndicatorObjPrefix + "TF_BG_" + timeframes[i];
      if(ObjectFind(tfBgName) < 0)
         ObjectCreate(0, tfBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSet(tfBgName, OBJPROP_XDISTANCE, X_Coord);
      ObjectSet(tfBgName, OBJPROP_YDISTANCE, y_pos);
      ObjectSet(tfBgName, OBJPROP_XSIZE, TF_Column_Width);
      ObjectSet(tfBgName, OBJPROP_YSIZE, Row_Height);
      ObjectSet(tfBgName, OBJPROP_BGCOLOR, TF_Column_Back);
      ObjectSet(tfBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      
      string tfName = IndicatorObjPrefix + "TF_" + timeframes[i];
      if(ObjectFind(tfName) < 0)
         ObjectCreate(0, tfName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(tfName, OBJPROP_XDISTANCE, X_Coord + 5);
      ObjectSet(tfName, OBJPROP_YDISTANCE, y_pos + (Row_Height - Font_Size) / 2);
      ObjectSetText(tfName, timeframes[i], Font_Size, Font_Type, TF_Column_Text);
      
      string colorName = IndicatorObjPrefix + "Color_" + timeframes[i];
      if(ObjectFind(colorName) < 0)
         ObjectCreate(0, colorName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSet(colorName, OBJPROP_XDISTANCE, X_Coord + TF_Column_Width);
      ObjectSet(colorName, OBJPROP_YDISTANCE, y_pos);
      ObjectSet(colorName, OBJPROP_XSIZE, Value_Column_Width);
      ObjectSet(colorName, OBJPROP_YSIZE, Row_Height);
      ObjectSet(colorName, OBJPROP_BGCOLOR, GetTimeframeColor(tf_values[i]));
      ObjectSet(colorName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   }
}

//+------------------------------------------------------------------+
void CheckAndDeleteArrow(int bar)
{
   if(!Show_Arrows) return;
   
   string ObjName = IndicatorObjPrefix + "Conqueror"+Time[bar];
   if(ObjectFind(ObjName) != -1)
   {
      ObjectDelete(ObjName);
   }
}

//+------------------------------------------------------------------+
void DrawArrow(int bar, int Status)
{
   if(!Show_Arrows) return;
   
   string ObjName = IndicatorObjPrefix + "Conqueror"+Time[bar];
   if(ObjectFind(ObjName) == -1)
   {
      ObjectCreate(ObjName, OBJ_ARROW, 0, Time[bar], Close[bar]);
   }
   ObjectSet(ObjName, OBJPROP_PRICE1, Low[bar]);
   ObjectSet(ObjName, OBJPROP_WIDTH, MA_Width);
   
   if(Status == 0)
   {
      ObjectSet(ObjName, OBJPROP_COLOR, indicator_color1);
      ObjectSet(ObjName, OBJPROP_ARROWCODE, 241);
   }
   if(Status == 1)
   {
      ObjectSet(ObjName, OBJPROP_COLOR, indicator_color2);
      ObjectSet(ObjName, OBJPROP_ARROWCODE, 242);
   }
   if(Status == 2)
   {
      ObjectSet(ObjName, OBJPROP_COLOR, indicator_color3);
      ObjectSet(ObjName, OBJPROP_ARROWCODE, 242);
   }
   if(Status == 3)
   {
      ObjectSet(ObjName, OBJPROP_COLOR, indicator_color3);
      ObjectSet(ObjName, OBJPROP_ARROWCODE, 241);
   }
}

//+------------------------------------------------------------------+
int start()
{
   int bars_to_calculate = MathMin(Bars-1, Max_Bars);
   
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) return(-1);
   if(counted_bars > 0) counted_bars--;
   
   int limit = bars_to_calculate - counted_bars;
   
   if(counted_bars == 0)
   {
      ArrayInitialize(Up, 0);
      ArrayInitialize(Dn, 0);
      ArrayInitialize(Neutral, 0);
      ArrayInitialize(MA_Buffer, 0);
   }
   
   for(int pos = limit; pos >= 0; pos--)
   {
      double MA0 = iMA(NULL, 0, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, pos);
      double MA1 = iMA(NULL, 0, MVA_Period, 0, MODE_SMA, PRICE_CLOSE, pos+Range_Period1);
      double atr = iATR(NULL, 0, ATR_Period, pos);
      
      MA_Buffer[pos] = MA0;
      
      Up[pos] = 0;
      Dn[pos] = 0;
      Neutral[pos] = 0;
      
      // ATR bazlı kontroller
      double diff_ab = Close[pos] - MA0;
      double diff_bc = MA0 - MA1;
      double diff_ad = Close[pos] - Close[pos+Range_Period2];
      
      if(diff_ab > (atr * Mult_AB) && 
         diff_bc > (atr * Mult_BC) && 
         diff_ad > (atr * Mult_AD))
      {
         Up[pos] = HISTOGRAM_HEIGHT;
      }
      else if(diff_ab < -(atr * Mult_AB) && 
              diff_bc < -(atr * Mult_BC) && 
              diff_ad < -(atr * Mult_AD))
      {
         Dn[pos] = HISTOGRAM_HEIGHT;
      }
      else
      {
         Neutral[pos] = HISTOGRAM_HEIGHT;
      }
      
      if(Up[pos] > 0 && Up[pos+1] == 0)
      {
         DrawArrow(pos, 0);
      }
      else if(Dn[pos] > 0 && Dn[pos+1] == 0)
      {
         DrawArrow(pos, 1);
      }
      else if(Neutral[pos] > 0 && Neutral[pos+1] == 0)
      {
         if(Up[pos+1] > 0)
         {
            DrawArrow(pos, 2);
         }
         else
         {
            DrawArrow(pos, 3);
         }
      }
      
      if(MathAbs(Up[pos] - Up[pos+1]) < 0.0001 && 
         MathAbs(Dn[pos] - Dn[pos+1]) < 0.0001 && 
         MathAbs(Neutral[pos] - Neutral[pos+1]) < 0.0001)
      {
         CheckAndDeleteArrow(pos);
      }
   }
   
   DrawTimeframeTable();
   
   return(0);
}

