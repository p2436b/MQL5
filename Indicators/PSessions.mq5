//+------------------------------------------------------------------+
//|                                                    PSessions.mq5 |
//|                                     Copyright 2023, Peyman Bayat |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Peyman Bayat"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

//--- input parameters
input string TokyoStart = "03:00";  // Tokyo Session Start Time
input string TokyoEnd = "11:00";  // Tokyo Session End Time
input string TokyoStartLineName = "TokyoSessionStart";
input string TokyoEndLineName = "TokyoSessionEnd";
input color TokyoSessionLineColor = C'153,38,38';

input string LondonStart = "10:00";  // London Session Start Time
input string LondonEnd = "17:00";  // London Session End Time
input string LondonStartLineName = "LondonSessionStart";
input string LondonEndLineName = "LondonSessionEnd";
input color LondonSessionLineColor = C'66,155,62';

input string NewYorkStart = "15:00";  // New York Session Start Time
input string NewYorkEnd = "00:00";  // New York Session End Time
input string NewYorkStartLineName = "NewYorkSessionStart";
input string NewYorkEndLineName = "NewYorkSessionEnd";
input color NewYorkSessionLineColor = C'19,197,255';


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   CreateSessionBox("NYBox", NewYorkSessionLineColor, NewYorkStart, NewYorkEnd);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteSessionLine(TokyoStartLineName);
   DeleteSessionLine(LondonStartLineName);
   DeleteSessionLine(NewYorkStartLineName);
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
   ResetLastError();

   /*if(ObjectFind(0, TokyoStartLineName) == -1 && _Period < PERIOD_H4)
     {
      CreateSessionLine(TokyoStartLineName, TokyoSessionLineColor, TokyoStart);
     }
   if(ObjectFind(0, TokyoEndLineName) == -1 && _Period < PERIOD_H4)
     {
      CreateSessionLine(TokyoEndLineName, TokyoSessionLineColor, TokyoEnd);
     }

   if(ObjectFind(0, LondonStartLineName) == -1 && _Period < PERIOD_H4)
     {
      CreateSessionLine(LondonStartLineName, LondonSessionLineColor, LondonStart);
     }
   if(ObjectFind(0, LondonEndLineName) == -1 && _Period < PERIOD_H4)
     {
      CreateSessionLine(LondonEndLineName, LondonSessionLineColor, LondonEnd);
     }

   if(ObjectFind(0, NewYorkStartLineName) == -1 && _Period < PERIOD_H4)
     {
      CreateSessionLine(NewYorkStartLineName, NewYorkSessionLineColor, NewYorkStart);
     }
   if(ObjectFind(0, NewYorkEndLineName) == -1 && _Period < PERIOD_H4)
     {
      CreateSessionLine(NewYorkEndLineName, NewYorkSessionLineColor, NewYorkEnd);
     }

   if(_Period > PERIOD_H1)
     {
      DeleteSessionLine(TokyoStartLineName);
      DeleteSessionLine(LondonStartLineName);
      DeleteSessionLine(NewYorkStartLineName);
     }*/

   return(rates_total);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetSessionLineStyle(string lineName, color lineColor)
  {
   ObjectSetInteger(0, lineName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, lineName,OBJPROP_BACK, true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateSessionLine(string lineName, color lineColor, string startTime)
  {
   datetime time = StringToTime(startTime);
   ObjectCreate(0, lineName, OBJ_VLINE, 0, time, SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   SetSessionLineStyle(lineName, lineColor);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteSessionLine(string lineName)
  {
   if(ObjectFind(0, lineName) != -1)
     {
      ObjectDelete(0, lineName);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateSessionBox(string boxName, color boxColor, string startTime, string endTime)
  {
   datetime sTime= StringToTime(startTime);
   datetime eTime = StringToTime(endTime);

   MqlRates rates[];
   CopyRates(_Symbol, PERIOD_CURRENT, sTime,eTime,rates);
   ObjectCreate(0, boxName, OBJ_RECTANGLE, 0, sTime, rates[0].low, eTime, rates[rates.Size()-1].high);
   SetSessionLineStyle(boxName, boxColor);
  }
//+------------------------------------------------------------------+
//test
