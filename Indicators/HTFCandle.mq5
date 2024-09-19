//+------------------------------------------------------------------+
//|                                                    HTFCandle.mq5 |
//|                                     Copyright 2023, Peyman Bayat |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Peyman Bayat"
#property link      ""
#property version   "1.00"
#property indicator_chart_window

input group "Time Settings";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1; // Box Time Interva
input group "Candle Settings";
input bool InpBoxCandle = true; // Box the Candle
input bool InpBoxCandleBody = true; // Box the Candle Body
input bool InpBoxCurrentCandle = true; // Box the Current Candle
input bool InpShowHighLowRange = true; // Show H/L Range Pips
input bool InpShowOpenClosePips; // Show O/C Pips
input group "Color Settings";
input color InpLongBoxColor = C'200,230,200'; // Long Boxes Color
input color InpShortBoxColor = C'230,170,170'; // Short Boxes Color
input color InpBoxBorderColor = C'205,205,205'; // Border Color

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "CandleBorder", -1,  OBJ_RECTANGLE);
   ObjectsDeleteAll(0, "CandleBody", -1,  OBJ_RECTANGLE);
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
   MqlRates higherTimeframeRates[];
   ArrayResize(higherTimeframeRates, rates_total);
   int copied = CopyRates(Symbol(), InpTimeframe, 0, rates_total, higherTimeframeRates);

   if(copied == 0)
     {
      Print("Error copying data from the higher timeframe");
      return(INIT_FAILED);
     }

   for(int i = 0; i < rates_total; i++)
     {
      datetime openTime = higherTimeframeRates[i].time;
      double openPrice = higherTimeframeRates[i].open;
      double highPrice = higherTimeframeRates[i].high;
      double lowPrice = higherTimeframeRates[i].low;
      double closePrice = higherTimeframeRates[i].close;
      if(InpBoxCandle)
        {
         string candleBorderName = "CandleBorder" + IntegerToString(i);
         ObjectCreate(0, candleBorderName, OBJ_RECTANGLE, 0, openTime, highPrice, openTime + PeriodSeconds(InpTimeframe), lowPrice);
         ObjectSetInteger(0, candleBorderName, OBJPROP_COLOR, InpBoxBorderColor);
        }
      else
        {
         ObjectsDeleteAll(0, "CandleBorder", -1,  OBJ_RECTANGLE);
        }
      if(InpBoxCandleBody)
        {
         string candleBodyName = "CandleBody" + IntegerToString(i);
         ObjectCreate(0, candleBodyName, OBJ_RECTANGLE, 0, openTime, openPrice, openTime + PeriodSeconds(InpTimeframe), closePrice);
         ObjectSetInteger(0, candleBodyName, OBJPROP_FILL, true);
         ObjectSetInteger(0, candleBodyName, OBJPROP_BACK, true);

         ObjectSetInteger(0, candleBodyName, OBJPROP_COLOR, closePrice > openPrice ?  InpLongBoxColor : InpShortBoxColor);
        }
      else
        {
         ObjectsDeleteAll(0, "CandleBody", -1,  OBJ_RECTANGLE);
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
