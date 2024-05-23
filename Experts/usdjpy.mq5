//+------------------------------------------------------------------+
//|                                                                  |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Peyman B."
#property version   "1.00"

#include <Trade/Trade.mqh>

//--- input parameters
input int TradeHour = 9;
input int TradeMin = 15;
input double Volume = 0.1;
input double RiskRewardRatio = 2;

CTrade _trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime currentTime = TimeCurrent();

   if(HistorySelect(currentTime - (currentTime % 86400), currentTime))
     {
      if(HistoryOrdersTotal())
         return;
     }   
   MqlDateTime time;
   TimeToStruct(currentTime, time);

   datetime tradeTime = StringToTime(StringFormat("%d:%d", TradeHour, TradeMin));
   if(currentTime >= tradeTime)
     {
      int tradeBarIndex = iBarShift(_Symbol, PERIOD_CURRENT, tradeTime);
      double tradeBarHigh = iHigh(_Symbol, PERIOD_CURRENT, tradeBarIndex);
      double tradeBarLow = iLow(_Symbol, PERIOD_CURRENT, tradeBarIndex);
      ObjectCreate(0, "TradeBox" + (time.year+time.day), OBJ_RECTANGLE, 0, tradeTime, tradeBarHigh, TimeCurrent(), tradeBarLow);
      if(tradeBarIndex >= 2 && PositionsTotal() == 0)
        {
         double closedBarClose = iClose(_Symbol, PERIOD_CURRENT, 1);
         if(closedBarClose > tradeBarHigh)
           {
            double diff = (tradeBarLow - closedBarClose) * RiskRewardRatio;
            Print("Buy, Price: ", closedBarClose, ", SL: ", tradeBarLow, ", TP: ", closedBarClose - diff);
            _trade.Buy(Volume, NULL, closedBarClose, tradeBarLow, closedBarClose - diff);
           }
         if(closedBarClose < tradeBarLow)
           {
            double diff = (tradeBarHigh - closedBarClose) * RiskRewardRatio;
            Print("Sell, Price: ", closedBarClose, ", SL: ", tradeBarHigh, ", TP: ", closedBarClose - diff);
            _trade.Sell(Volume, NULL, closedBarClose, tradeBarHigh, closedBarClose - diff);
           }
        }
     }
  }
//+------------------------------------------------------------------+
