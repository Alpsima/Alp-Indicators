//+------------------------------------------------------------------+
//|                                                    ZamanAyirici.mq4 |
//|                                                         Copyright © |
//+------------------------------------------------------------------+

#property copyright "Alp Indicators"
#property link      "https://github.com/Alpsima/Alp-Indicators"
#property version   "1.10"
#property strict
#property indicator_chart_window

// Çizgi stilleri için enum tanımı
enum ENUM_LINE_STYLE_CUSTOM {
   STYLE_SOLID = STYLE_SOLID,    // Solid
   STYLE_DASH = STYLE_DASH,      // Dash
   STYLE_DOT = STYLE_DOT         // Dot
};

// Giriş parametreleri
extern color LineColor = clrRed;        // Çizgi Rengi
extern int LineWidth = 1;               // Çizgi Kalınlığı
extern ENUM_LINE_STYLE_CUSTOM LineStyle = STYLE_SOLID;  // Çizgi Stili

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init() {
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit() {
   ObjectsDeleteAll(0, "ZamanAyirici_");
   return(0);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+---------------------------
