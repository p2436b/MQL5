//+------------------------------------------------------------------+
//|                                              PeriodSeperator.mq5 |
//|                                        Copyright 2024, Peyman B. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Peyman B."
#property link      ""
#property version   "1.00"
#property indicator_chart_window

//--- input parameters
input color    LineColor= clrDeepSkyBlue; // Line Color
input          ENUM_LINE_STYLE LineStyle= STYLE_DOT; // Line Style
input bool     HasRay = false; // Has Ray
input int      TimeHour= 12; // Draw Line Hour
input int      TimeMinute= 0; // Draw Line Minute
input int      Counts= 2; // Sperator Count(s)

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
   for(int i=ObjectsTotal(0, -1, OBJ_VLINE);i>0;i--)
     {
      string objName = ObjectName(0,i);
      if(StringFind(objName, "VerticalLine_") != -1)
        {
         ObjectDelete(0, objName);
        }
     }
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
   static datetime lastTime = 0;
   static uint counts= 0;

   for(int i = rates_total-1; i >= prev_calculated; i--)
     {
      MqlDateTime barTime;
      TimeToStruct(time[i], barTime);

      if(barTime.hour == 1 && barTime.min == 0 && time[i] != lastTime && counts != Counts)
        {
         Print(counts, "-", Counts);
         string name = "SperatorLine_" + IntegerToString(i);
         ObjectCreate(0, name, OBJ_VLINE, 0, time[i], 0);
         ObjectSetInteger(0, name, OBJPROP_COLOR, LineColor);
         ObjectSetInteger(0, name, OBJPROP_STYLE, LineStyle);
         ObjectSetInteger(0, name, OBJPROP_RAY, HasRay);
         lastTime = time[i];
         counts++;
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
