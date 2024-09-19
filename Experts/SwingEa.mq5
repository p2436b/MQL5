//+------------------------------------------------------------------+
//|                                                      SwingEa.mq5 |
//|                                    Copyright 2023, Peyman Bayat. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Peyman Bayat."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

input double TradeLotsSize = 0;
input double RiskPercentage = 2;
input int PointsSLD = 20;
input double FactorTP = 1.0;
input int PointsBE = 50;
input int PointsPuffer = 10;
input int TradeTrigger = 20;
input int PointsTSL = 10;
input bool ActiveBSL = true;
input bool ActiveTSL = true;
input int TradeCount = 20;
input int SwingCount = 3;
input int StartTime = 3;
input int EndTime = 14;

MqlRates lastSwingHigh;
uint lastSwingHighIndex;
bool lastSwingHighFound;
MqlRates lastSwingLow;
uint lastSwingLowIndex;
bool lastSwingLowFound;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int totalBars = iBars(_Symbol, PERIOD_CURRENT);
MqlRates lastSwingHighTraded;
MqlRates lastSwingLowTraded;

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   FindLastSwingHighLowV2();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double bid =SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask =SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(totalBars != iBars(_Symbol,PERIOD_CURRENT))
      FindLastSwingHighLowV2();

   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);

   if(t.hour >= StartTime && t.hour <= EndTime)
     {

      Print("Trade time: ", t.hour);
      if(PositionsTotal() <= TradeCount)
        {
         double lastCandleClose = iClose(_Symbol, PERIOD_CURRENT, 1);
         double lastCandleHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
         double lastCandleLow = iLow(_Symbol, PERIOD_CURRENT, 1);
         if(lastCandleClose > lastSwingHigh.high && lastSwingHigh.time != lastSwingHighTraded.time)
           {
            double tp = 0;
            double sl = lastCandleLow - PointsSLD * _Point;
            if(FactorTP > 0)
               tp = NormalizeDouble(ask + (ask - sl) * FactorTP, _Digits);

            double lots = TradeLotsSize;
            if(TradeLotsSize <= 0)
              {
               lots = CalculateLotsSize(RiskPercentage, (ask - sl) / _Point);
              }
            trade.Buy(lots, _Symbol, ask, sl, tp);
            lastSwingHighTraded = lastSwingHigh;
           }
         else
            if(lastCandleClose < lastSwingLow.low && lastSwingLow.time != lastSwingLowTraded.time)
              {
               double tp = 0;
               double sl = lastCandleHigh + PointsSLD * _Point;
               if(FactorTP > 0)
                  tp = NormalizeDouble(bid + (bid - sl) * FactorTP, _Digits);

               double lots = TradeLotsSize;
               if(TradeLotsSize <= 0)
                 {
                  lots = CalculateLotsSize(RiskPercentage, (sl - bid) / _Point);
                 }
               trade.Sell(lots, _Symbol, bid, sl, tp);
               lastSwingLowTraded = lastSwingLow;
              }
        }

      for(int i= PositionsTotal() -1; i >= 0; i--)
        {
         ulong pTicket = PositionGetTicket(i);
         if(PositionSelectByTicket(pTicket))
           {
            double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double posSl = PositionGetDouble(POSITION_SL);
            double posTP = PositionGetDouble(POSITION_TP);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               if(posSl >= posOpenPrice && ActiveTSL)
                 {
                  // Trail
                  double sl = bid - PointsTSL * _Point;
                  if(sl > posSl)
                    {
                     Print("==> Buy position #", pTicket, " set trail stop loss at ", sl);
                     trade.PositionModify(pTicket, sl, posTP);
                    }
                 }

               if(bid > posOpenPrice + PointsBE * _Point && ActiveBSL)
                 {
                  // SL at BE
                  double sl = NormalizeDouble(posOpenPrice + PointsPuffer * _Point, _Digits);
                  if(sl > posSl)
                    {
                     Print("==> Buy position #", pTicket, " set stop loss at ", sl);
                     trade.PositionModify(pTicket, sl, posTP);
                    }
                 }
              }
            else
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                 {

                  if(posSl <=  posOpenPrice && ActiveTSL)
                    {
                     // Trail
                     double sl = ask + PointsTSL * _Point;
                     if(sl < posSl)
                       {
                        Print("==> Sell position #", pTicket, " set trail stop loss at ", sl);
                        trade.PositionModify(pTicket, sl, posTP);
                       }
                    }

                  if(ask  < posOpenPrice - PointsBE * _Point && ActiveBSL)
                    {
                     // SL at BE
                     double sl =NormalizeDouble(posOpenPrice - PointsPuffer * _Point, _Digits);
                     if(sl < posSl)
                       {
                        Print("==> Sell position #", pTicket, " set stop loss at ", sl);
                        trade.PositionModify(pTicket, sl, posTP);
                       }
                    }
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindLastSwingHighLow()
  {
   MqlRates rates[];

   ArraySetAsSeries(rates, true);
   int copied= CopyRates(_Symbol, PERIOD_CURRENT, 0, 100, rates);
   lastSwingHigh = rates[0];
   lastSwingLow = rates[0];
   lastSwingHighIndex = 0;
   lastSwingLowIndex = 0;
   lastSwingHighFound = false;
   lastSwingLowFound = false;
   if(copied > 0)
     {
      for(int i= 1; i < 95; i++)
        {
         if(lastSwingHighFound && lastSwingLowFound)
            break;
         if(rates[i+1].high > rates[i].high && rates[i+2].high < rates[i+1].high && lastSwingHighFound == false)
           {
            lastSwingHighIndex = i+1;
            lastSwingHigh = rates[i+1];
            lastSwingHighFound = true;
           }
         if(rates[i+1].low < rates[i].low && rates[i+2].low > rates[i+1].low && lastSwingLowFound == false)
           {
            lastSwingLowIndex = i+1;
            lastSwingLow = rates[i+1];
            lastSwingLowFound = true;
           }
        }
      DrawLine("lastSwingHigh", lastSwingHigh.time, lastSwingHigh.high, lastSwingHigh.time, lastSwingHigh.high, clrRed);
      DrawLine("lastSwingLow", lastSwingLow.time, lastSwingLow.low, lastSwingLow.time, lastSwingLow.low, clrGreen);
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindLastSwingHighLowV2()
  {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 100, rates);
   if(copied > SwingCount * 2 + 1)
     {
      // Swing high
      for(int i= SwingCount + 1; i < copied; i++)
        {
         bool isSwingHighRight = false;
         bool isSwingHighLeft = false;

         lastSwingHigh = rates[i];

         for(int j = i-1; j >= i - SwingCount; j--)
           {
            // Swing high right calculation
            if(lastSwingHigh.high > rates[j].high)
              {
               isSwingHighRight = true;
              }
            else
              {
               isSwingHighRight = false;
               break;
              }
           }

         for(int j= i+1; j <= i + SwingCount; j++)
           {
            // Swing high left calculation
            if(!isSwingHighRight)
               break;

            if(lastSwingHigh.high > rates[j].high)
              {
               isSwingHighLeft = true;
              }
            else
              {
               isSwingHighLeft = false;
               break;
              }
           }

         if(isSwingHighLeft && isSwingHighRight)
           {
            DrawLine("lastSwingHigh", lastSwingHigh.time, lastSwingHigh.high, lastSwingHigh.time, lastSwingHigh.high, clrRed);
            break;
           }
         else
           {
            ObjectDelete(0,"lastSwingHigh");
           }
        }

      // Swing Low
      for(int i= SwingCount + 1; i < copied; i++)
        {
         bool isSwingLowRight = false;
         bool isSwingLowLeft = false;

         lastSwingLow = rates[i];

         for(int j = i-1; j >= i - SwingCount; j--)
           {
            // Swing low right calculation
            if(lastSwingLow.low < rates[j].low)
              {
               isSwingLowRight = true;
              }
            else
              {
               isSwingLowRight = false;
               break;
              }
           }

         for(int j= i+1; j <= i + SwingCount; j++)
           {
            // Swing low left calculation
            if(!isSwingLowRight)
               break;

            if(lastSwingLow.low < rates[j].low)
              {
               isSwingLowLeft = true;
              }
            else
              {
               isSwingLowLeft = false;
               break;
              }
           }

         if(isSwingLowLeft && isSwingLowRight)
           {
            DrawLine("lastSwingLow", lastSwingLow.time, lastSwingLow.low, lastSwingLow.time, lastSwingLow.low, clrRed);
            break;
           }
         else
           {
            ObjectDelete(0,"lastSwingLow");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateLotsSize(double percentage, double slPoints)
  {
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(tickSize == 0 || tickValue == 0 || volumeStep == 0)
     {
      return 0;
     }
   double moneyLotStep = (slPoints*_Point) / tickSize * tickValue * volumeStep;
   if(moneyLotStep == 0)
      return 0;
   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * percentage / 100;

   double lots =MathFloor(riskMoney / moneyLotStep) * volumeStep;
   Comment(slPoints, "\n", lots);
   return lots;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLine(string name, datetime t1, double p1, datetime t2, double p2, color lineColor)
  {
   ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2 + PeriodSeconds(PERIOD_CURRENT) * 10, p2);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
  }
//+------------------------------------------------------------------+
