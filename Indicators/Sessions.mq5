//+------------------------------------------------------------------+
//|                                                     Sessions.mq5 |
//|                                    Copyright 2024, Peyman Bayat. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Peyman Bayat."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0

//--- input parameters
input color    InpLondonColor=C'143,188,139';
input datetime InpLondonTime=D'2024.08.05 10:00:00';

input color    InpNewYorkColor=clrCornflowerBlue;
input datetime InpNewYorkTime=D'2024.08.05 10:00:00';

input color    InpWallStreet=clrDarkSalmon;
input datetime InpWallStreetTime=D'2024.08.05 10:00:00';

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(IsStopped())
      return 0;

   int bar = iBarShift(NULL, 0, InpLondonTime, true);
   if(bar >= 0)
     {
      ObjectCreate(0, "London" + bar,OBJ_VLINE,0,time[bar], NULL);
      //Print(prev_calculated, "   -    ", rates_total, "   -    ", i);
     }


   return(rates_total);
  }
//+------------------------------------------------------------------+
