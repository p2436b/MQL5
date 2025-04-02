//+------------------------------------------------------------------+
//|                                                    PSessions.mq5 |
//|                                     Copyright 2023, Peyman Bayat |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Peyman Bayat"
#property link      "https://github.com/p2436b"
#property version   "1.3"
#property indicator_chart_window

//--- input parameters
input group "--= General =--"
input string FontName="Arial"; // Font 
input int FontSize=10; // Font size 
input ENUM_TIMEFRAMES VisualizationTimeframe = PERIOD_H4; // Visualization Timeframe

input group "--= Tokyo =--"
input string TokyoStart = "03:00";  // Tokyo Session Start Time
input string TokyoEnd = "12:00";  // Tokyo Session End Time
input string TokyoSessionStartLineName = "Tokyo Start"; // Tokyo Session Start Line Name
input string TokyoSessionEndLineName = "Tokyo End"; // Tokyo Session End Line Name
input color TokyoSessionStartLineColor = C'185,74,74'; // Tokyo Session Start Line Color
input color TokyoSessionEndLineColor = C'185,74,74'; // Tokyo Session End Line Color
input bool TokyoIsVisible = true; // Show Tokyo Session

input group "--= London =--"
input string LondonStart = "10:00";  // London Session Start Time
input string LondonEnd = "19:00";  // London Session End Time
input string LondonSessionStartLineName = "London Start"; // London Session Start Line Name
input string LondonSessionEndLineName = "London End"; // London Session End Line Name
input color LondonSessionStartLineColor = C'66,155,62'; // London Session Start Line Color
input color LondonSessionEndLineColor = C'66,155,62'; // London Session End Line Color
input bool LondonIsVisible = true; // Show London Session

input group "--= New York =--"
input string NewYorkStart = "15:00";  // New York Session Start Time
input string NewYorkEnd  = "00:00";  // New York Session End Time
input string NewYorkSessionStartLineName = "NewYork Start"; // New York Session Start Line Name
input string NewYorkSessionEndLineName = "NewYork End"; // New York Session End Line Name
input color NewYorkSessionEndLineColor = C'0,126,168'; // New York Session Start Line Color
input color NewYorkSessionStartLineColor = C'0,126,168'; // New York Session End Line Color
input bool NewYorkIsVisible = true; // Show New York Session

input group "--= NYSE =--"
input string NYSEStart = "16:30";  // NYSE Session Start Time
input string NYSEEnd = "23:50";  // NYSE Session End Time
input string NYSESessionStartLineName = "NYSE Start"; // NYSE Session Start Line Name
input string NYSESessionEndLineName = "NYSE End"; // NYSE Session End Line Name
input color NYSESessionStartLineColor = clrOrange; // NYSE Session Start Line Color
input color NYSESessionEndLineColor = clrOrange; // NYSE Session End Line Color
input bool NYSEIsVisible = true; // Show NYSE Session

//input uint NumberOfPastdays = 0;

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
   DeleteAllDrawings();
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

   DrawAllSessionLines();

   if(_Period > PERIOD_H1)
     {
      DeleteAllDrawings();
     }

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
void CreateSessionLine(string lineName, color lineColor, string start)
  {
   datetime startTime = StringToTime(start);
   if(lineName == NewYorkSessionEndLineName)
     {
      startTime+= PeriodSeconds(PERIOD_D1);
     }

// Draw line label
   ObjectCreate(0, lineName + "lbl", OBJ_TEXT, 0, startTime, ChartGetDouble(0, CHART_PRICE_MAX));
   ObjectSetString(0, lineName + "lbl", OBJPROP_FONT, FontName); 
   ObjectSetInteger(0, lineName + "lbl", OBJPROP_FONTSIZE, FontSize); 
   ObjectSetString(0, lineName + "lbl",OBJPROP_TEXT, " " + lineName);
   ObjectSetDouble(0, lineName + "lbl", OBJPROP_ANGLE, -90);
   ObjectSetInteger(0, lineName + "lbl", OBJPROP_COLOR, lineColor);
//------------------------------------------------------------------------

   ObjectCreate(0, lineName, OBJ_VLINE, 0, startTime, SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   SetSessionLineStyle(lineName, lineColor);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawAllSessionLines()
  {
   if(TokyoIsVisible && ObjectFind(0, TokyoSessionStartLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(TokyoSessionStartLineName, TokyoSessionStartLineColor, TokyoStart);
   if(TokyoIsVisible && ObjectFind(0, TokyoSessionEndLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(TokyoSessionEndLineName, TokyoSessionEndLineColor, TokyoEnd);

   if(LondonIsVisible && ObjectFind(0, LondonSessionStartLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(LondonSessionStartLineName, LondonSessionStartLineColor, LondonStart);
   if(ObjectFind(0, LondonSessionEndLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(LondonSessionEndLineName, LondonSessionEndLineColor, LondonEnd);

   if(NewYorkIsVisible && ObjectFind(0, NewYorkSessionStartLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(NewYorkSessionStartLineName, NewYorkSessionStartLineColor, NewYorkStart);
   if(NewYorkIsVisible && ObjectFind(0, NewYorkSessionEndLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(NewYorkSessionEndLineName, NewYorkSessionEndLineColor, NewYorkEnd);
      
   if(NYSEIsVisible && ObjectFind(0, NYSESessionStartLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(NYSESessionStartLineName, NYSESessionStartLineColor, NYSEStart);
   if(NYSEIsVisible && ObjectFind(0, NYSESessionEndLineName) == -1 && _Period <= VisualizationTimeframe)
      CreateSessionLine(NYSESessionEndLineName, NYSESessionEndLineColor, NYSEEnd);
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
void DeleteAllDrawings()
  {
   DeleteSessionLine(TokyoSessionStartLineName);
   DeleteSessionLine(TokyoSessionStartLineName + "lbl");
   DeleteSessionLine(TokyoSessionEndLineName);
   DeleteSessionLine(TokyoSessionEndLineName + "lbl");

   DeleteSessionLine(LondonSessionStartLineName);
   DeleteSessionLine(LondonSessionStartLineName + "lbl");
   DeleteSessionLine(LondonSessionEndLineName);
   DeleteSessionLine(LondonSessionEndLineName  + "lbl");

   DeleteSessionLine(NewYorkSessionStartLineName);
   DeleteSessionLine(NewYorkSessionStartLineName + "lbl");
   DeleteSessionLine(NewYorkSessionEndLineName);
   DeleteSessionLine(NewYorkSessionEndLineName + "lbl");
   
   DeleteSessionLine(NYSESessionStartLineName);
   DeleteSessionLine(NYSESessionStartLineName + "lbl");
   DeleteSessionLine(NYSESessionEndLineName);
   DeleteSessionLine(NYSESessionEndLineName + "lbl");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      DeleteAllDrawings();
      DrawAllSessionLines();
     }
  }
//+------------------------------------------------------------------+
