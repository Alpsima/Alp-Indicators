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
