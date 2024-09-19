//+------------------------------------------------------------------+
//|                                                       DonDok.mq5 |
//|                                    Copyright 2023, Peyman Bayat. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Peyman Bayat."
#property link      "https://www.sex.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double LotsSize = 0.1; // Trade Lots Size (0 will use Risk Percentage)
input double RiskPercentage = 2; // Risk Percentage per Trade
input ushort PointsMaxSpread =  250; // Maximum Spread For Trade (Points)
input uint OrderDst = 500; // Order Distance (Points)
input uint StopLossDst = 500; // Stop Loss Distance (Points)
input bool ActiveMoveStop = true; // Move Stop Loss with Candles
input group "Trading Time Settings";
input ushort StartTradeHour = 4; // Start Trade Hour
input ushort StartTradeMin = 0; // Start Trade Minute
input ushort EndTradeHour = 23; // End Trade Hour
input ushort EndTradeMin = 0; // End Trade Minute
input group "System Settings";
input ulong MagicNumber = 2436; // Expert Magic Number

CTrade trade;

bool didFirstTrade = false;
int barsTotal = iBars(_Symbol, PERIOD_CURRENT);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTrade(void)
  {
   uint totalPositions = PositionsTotal();
   uint totalOrders = OrdersTotal();

   if(!didFirstTrade)
      didFirstTrade = true;

   if(totalPositions >= 1)
      CancelPendingOrders();

   if(totalPositions <= 0 && totalOrders <= 0)
     {
      HistorySelect(0, TimeCurrent());
      ulong ticket = HistoryDealGetTicket(HistoryDealsTotal() - 1);

      if(ticket > 0)
        {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY)
           {
            Comment("Buy: ", profit);
            double sl = NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - (OrderDst * _Point),_Digits);
            double tp = 0;
            if(!ActiveMoveStop)
               tp = NormalizeDouble(ask + (ask - sl), _Digits);

            Print("ASK: ", ask,"\nSL: ", sl, "\nTP: ", tp);
            trade.Buy(LotsSize, _Symbol, ask, sl, tp);
           }
         else
            if(HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_SELL)
              {
               Comment("Sell: ", profit);
               double sl = NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + (OrderDst * _Point),_Digits);
               double tp = 0;
               if(!ActiveMoveStop)
                  tp = NormalizeDouble(bid - (bid - sl), _Digits);
               Print("BID: ", bid,"\nSL: ", sl, "\nTP: ", tp);
               trade.Sell(LotsSize, _Symbol, bid, sl, tp);
              }
        }
     }
   Print("OnTrade");
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);

   if(!IsTradeTime(StartTradeHour, StartTradeMin, EndTradeHour, EndTradeMin))
      return;

   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > PointsMaxSpread)
      return;

   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if(barsTotal == bars)
      return;
   barsTotal = bars;

   if(OrdersTotal() >= 1)
     {
      ModifyOrder();
      return;
     }


   if(PositionsTotal() >= 1)
     {
      MoveStopLoss();
      return;
     }


   if(!didFirstTrade)
     {
      switch(FirstTradeType())
        {
         case  1:
           {
            double price = NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + OrderDst * _Point, _Digits);
            double sl = NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - StopLossDst * _Point, _Digits);
            double tp = 0;
            if(!ActiveMoveStop)
               tp = NormalizeDouble(price + (price - sl), _Digits);
            double lotsSize = LotsSize;
            if(LotsSize <= 0)
              {
               lotsSize = CalculateLotsSize(RiskPercentage, (price - sl) / _Point);
              }
            trade.BuyStop(lotsSize, price, _Symbol, sl, tp, ORDER_TIME_DAY, 0, "DonDok");
            Print("Buy stop @ ", price);
            break;
           }
         case  2:
           {
            double price = NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - OrderDst * _Point, _Digits);
            double sl = NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + StopLossDst * _Point, _Digits);
            double tp = 0;
            if(!ActiveMoveStop)
               tp = NormalizeDouble(price - (sl - price),_Digits);
            double lotsSize = LotsSize;
            if(LotsSize <= 0)
              {
               lotsSize = CalculateLotsSize(RiskPercentage, (sl - price) / _Point);
              }
            trade.SellStop(lotsSize, price, _Symbol, sl, tp, ORDER_TIME_DAY, 0, "DonDok");
            Print("Sell stop @ ", price);
            break;
           }
         case  3:
           {
            double buyPrice = NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + OrderDst * _Point, _Digits);
            double buySl = NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - StopLossDst * _Point, _Digits);
            double buyTp = 0;

            double sellPrice = NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - OrderDst * _Point, _Digits);
            double sellSl = NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + StopLossDst * _Point, _Digits);
            double sellTp = 0;
            if(!ActiveMoveStop)
              {
               buyTp = NormalizeDouble(buyPrice + (buyPrice - buySl), _Digits);
               sellTp = NormalizeDouble(sellPrice - (sellSl - sellPrice),_Digits);
              }
            trade.BuyStop(LotsSize, buyPrice, _Symbol, buySl, buyTp, ORDER_TIME_DAY, 0, "DonDok");
            trade.SellStop(LotsSize, sellPrice, _Symbol, sellSl, sellTp, ORDER_TIME_DAY, 0, "DonDok");
            Print("Buy stop @ ", buyPrice, " & Sell stop @ ", sellPrice);
            break;
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsTradeTime(ushort startTradeHour, ushort startTradeMin, ushort endTradeHour, ushort endTradeMin)
  {
   MqlDateTime time;
   TimeCurrent(time);

   time.hour = startTradeHour;
   time.min = startTradeMin;
   time.sec = 0;
   datetime startTime = StructToTime(time);

   time.hour = endTradeHour;
   time.min = endTradeMin;
   datetime endTime = StructToTime(time);

   return TimeCurrent() >= startTime && TimeCurrent() <= endTime;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint FirstTradeType()
  {
   bool buyStop = iHigh(_Symbol,PERIOD_CURRENT, 2) > iHigh(_Symbol,PERIOD_CURRENT, 1);
   bool sellStop = iLow(_Symbol,PERIOD_CURRENT, 2) < iLow(_Symbol,PERIOD_CURRENT, 1);
   if(buyStop && sellStop)
     {
      // Buy stop on high of the candle 1
      // SL => Low of the candle 1
      // and
      // Sell stop on low of candle 1
      // SL => High of the candle 1
      return 3;
     }
   if(buyStop)
     {
      // Buy stop on high of the candle 1
      // SL => Low of the candle 1
      return 1;
     }
   if(sellStop)
     {
      // Sell stop on low of candle 1
      // SL => High of the candle 1
      return 2;
     }
// Nothing
   return 0;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveStopLoss()
  {
   for(int i= PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);

      if(magicNumber == MagicNumber)
        {
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && sl < iLow(_Symbol, PERIOD_CURRENT, 1))
           {
            trade.PositionModify(ticket, NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - StopLossDst * _Point, _Digits), tp);
            Print("Modify Buy Position Stop Loss");
           }
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && sl > iHigh(_Symbol, PERIOD_CURRENT, 1))
           {
            trade.PositionModify(ticket, NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1)  + StopLossDst * _Point, _Digits), tp);
            Print("Modify Sell Position Stop Loss");
           }
        }
     }

   /*for(int i= OrdersTotal() - 1; i >= 0; i--)
     {
     Comment("************* Order *************");
      ulong ticket = OrderGetTicket(i);
      ulong magicNumber = OrderGetInteger(ORDER_MAGIC);

      if(magicNumber == MagicNumber)
        {
         double price = OrderGetDouble(ORDER_PRICE_OPEN);
         double sl = OrderGetDouble(ORDER_SL);
         double tp = OrderGetDouble(ORDER_TP);

         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY && sl < iLow(_Symbol, PERIOD_CURRENT, 1))
           {
            trade.OrderModify(ticket, price, NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1)  - StopLossDst * _Point, _Digits), tp, ORDER_TIME_DAY, 0);
            Print("Modify Buy Order Stop Loss");
           }
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL && sl > iHigh(_Symbol, PERIOD_CURRENT, 1))
           {
            trade.OrderModify(ticket, price, NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + StopLossDst * _Point, _Digits), tp, ORDER_TIME_DAY, 0);
            Print("Modify Sell Order Stop Loss");
           }
        }
     }*/
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyOrder()
  {
   for(int i= OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      ulong magicNumber = OrderGetInteger(ORDER_MAGIC);

      if(magicNumber == MagicNumber)
        {
         double price = OrderGetDouble(ORDER_PRICE_OPEN);
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP && price > iLow(_Symbol, PERIOD_CURRENT, 1))
           {
            trade.OrderModify(ticket, NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + (OrderDst * _Point),_Digits), NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - (OrderDst * _Point),_Digits), 0, ORDER_TIME_DAY, 0);
            Print("Modify Buy Stop");
            return;
           }
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP && price < iHigh(_Symbol, PERIOD_CURRENT, 1))
           {
            trade.OrderModify(ticket, NormalizeDouble(iLow(_Symbol, PERIOD_CURRENT, 1) - (OrderDst * _Point),_Digits), NormalizeDouble(iHigh(_Symbol, PERIOD_CURRENT, 1) + (OrderDst * _Point),_Digits), 0, ORDER_TIME_DAY, 0);
            Print("Modify Sell Stop");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelPendingOrders()
  {
   for(int i= OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      ulong magicNumber = OrderGetInteger(ORDER_MAGIC);

      if(magicNumber == MagicNumber)
        {
         trade.OrderDelete(ticket);
         Print("Cancel order #", ticket);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckOrderStatus()
  {
   for(int i= OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      ulong magicNumber = OrderGetInteger(ORDER_MAGIC);

      if(magicNumber == MagicNumber)
        {
         double price = OrderGetDouble(ORDER_PRICE_OPEN);

         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP)
           {
            Print("Buy Stop");
           }
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP)
           {
            Print("Sell Stop");
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

   return MathFloor(riskMoney / moneyLotStep) * volumeStep;
  }
//+------------------------------------------------------------------+
