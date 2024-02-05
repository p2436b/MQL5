//+------------------------------------------------------------------+
//|                                                      PTrader.mq5 |
//|                                        Copyright 2024, Peyman B. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Peyman B."
#property link      "https://www.instagram.com/p2436b"
#property version   "1.00"

#include <Trade/Trade.mqh>

input uint MagicNumber = 2436; // Magic Number
input double RiskPercentage = 1; // Risk Percentage
input double RiskRewardRatio = 1; // Risk Reward Ratio

double _stopLossPoints = 5000;
string _stopLossName = "StopLoss";
string _takeProfitName = "TakeProfit";

CTrade _trade;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   _trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0, _takeProfitName);
   ObjectDelete(0, _stopLossName);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double stopLossPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - _stopLossPoints * _Point;
   double takeProfitPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID) + _stopLossPoints * RiskRewardRatio * _Point;

   DrawLine(_stopLossName, stopLossPrice, clrRed);
   DrawLine(_takeProfitName, takeProfitPrice, clrGreen);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLine(string name, double price, color _color)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_HLINE, 0, NULL, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, _color);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, 1);
     }
   else
     {
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
     }
   ObjectSetInteger(0, name, OBJPROP_SELECTED, 1);
  }
//+------------------------------------------------------------------+
