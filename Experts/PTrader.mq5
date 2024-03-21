//+------------------------------------------------------------------+
//|                                                      PTrader.mq5 |
//|                                        Copyright 2024, Peyman B. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Peyman B."
#property link      "https://www.instagram.com/p2436b"
#property version   "1.00"

/*#import "user32.dll"
// GetKeyState() checks if the key was pressed at the same time as the WM_KEYDOWN message came, GetAsyncKeyState() checks if it is still down.
int GetKeyState(int nVirtKey);
short GetAsyncKeyState(int nVirtKey);
#import

 // https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
int VK_CONTROL = 0x11;
int VK_SHIFT = 0x10;
*/
int T_Key = 0x54;
int H_Key = 0x48;

#include <Trade/Trade.mqh>

input uint MagicNumber = 2436; // Magic Number
input double RiskPercentage = 1; // Risk Percentage
input double RiskRewardRatio = 1; // Risk Reward Ratio

double _stopLossPoints = 2500;
double _stopLossPrice = 0;
double _takeProfitPrice = 0;
string _stopLossName = "StopLoss";
string _takeProfitName = "TakeProfit";
string _currentPriceName = "CurrentPrice";
string _baseCurrency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
string _tradeType = "None";
bool _hideLines = false;
CTrade _trade;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   _trade.SetExpertMagicNumber(MagicNumber);
   Calculate();
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   CleanChart();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   Calculate();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   if(id == CHARTEVENT_KEYDOWN)
     {
      int keyCode = (int)lparam;
      int shiftKeyState = TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT);
      if((shiftKeyState & 0x8000) != 0)
        {
         if(keyCode == T_Key)
           {
            if(_hideLines)
               return;

            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK); // Buy
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Sell
            double spread = ask - bid;

            if(_tradeType == "Buy")
              {
               double lots = OptimumLotsSize(_Symbol, ask, _stopLossPrice, RiskPercentage);
               _takeProfitPrice = bid + (_stopLossPoints + spread) * RiskRewardRatio * _Point;
               _trade.Buy(lots, NULL, 0, _stopLossPrice, _takeProfitPrice, "PTrader");
              }
            else
               if(_tradeType == "Sell")
                 {
                  double lots = OptimumLotsSize(_Symbol, bid, _stopLossPrice, RiskPercentage);
                  _takeProfitPrice = ask - (_stopLossPoints - spread) * RiskRewardRatio * _Point;
                  _trade.Sell(lots, NULL, 0, _stopLossPrice, _takeProfitPrice, "PTrader");
                 }
           }

         if(keyCode == H_Key)
           {
            _hideLines = !_hideLines;
            if(_hideLines)
              {
               HideDrawings(true);
              }
            else
              {
               HideDrawings(false);
              }
           }
        }
     }

   if(id == CHARTEVENT_OBJECT_DRAG)
     {
      Calculate();
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CleanChart()
  {
   ObjectDelete(0, _takeProfitName);
   ObjectDelete(0, _takeProfitName + "Info");
   ObjectDelete(0, _stopLossName);
   ObjectDelete(0, _stopLossName + "Info");
   ObjectDelete(0, _currentPriceName);
   ObjectDelete(0, _currentPriceName + "Info");
   ChartRedraw();
   _stopLossPrice = 0;
   _takeProfitPrice = 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HideDrawings(bool value)
  {
   ObjectSetInteger(0, _takeProfitName, OBJPROP_HIDDEN, value);
   ObjectSetInteger(0, _takeProfitName + "Info", OBJPROP_HIDDEN, value);
   ObjectSetInteger(0, _stopLossName, OBJPROP_HIDDEN, value);
   ObjectSetInteger(0, _stopLossName + "Info", OBJPROP_HIDDEN, value);
   ObjectSetInteger(0, _currentPriceName, OBJPROP_HIDDEN, 1);
   ObjectSetInteger(0, _currentPriceName + "Info", OBJPROP_HIDDEN, value);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLine(string name, double price, color _color, long isSelectable)
  {
   int x,y;
   string infoName = name + "Info";
   ChartTimePriceToXY(0,0,TimeCurrent(), price, x,y);
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, infoName, OBJ_LABEL, 0, NULL, NULL);
      ObjectSetInteger(0, infoName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, infoName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, infoName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, infoName, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
      ObjectSetInteger(0, infoName, OBJPROP_COLOR, _color);
      ObjectSetString(0, infoName, OBJPROP_FONT, "Courier New");

      ObjectCreate(0, name, OBJ_HLINE, 0, NULL, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, _color);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, isSelectable);
     }
   else
     {
      ObjectSetInteger(0, infoName, OBJPROP_YDISTANCE, y);
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
     }
   ObjectSetInteger(0, name, OBJPROP_SELECTED, isSelectable);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetInfo(string name, string info)
  {
   ObjectSetString(0, name + "Info", OBJPROP_TEXT, info);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Calculate()
  {
   if(_hideLines)
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK); // Buy
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Sell
   double spread = (ask - bid) * _Digits;

   _stopLossPrice = _stopLossPrice == 0 ? _stopLossPrice = ask - _stopLossPoints * _Point : _stopLossPrice = ObjectGetDouble(0, _stopLossName, OBJPROP_PRICE);
   double lots = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(_stopLossPrice < bid)
     {
      _tradeType = "Buy";
      _stopLossPoints = CalculatePointsBetweenPrices(ask, _stopLossPrice);
      _takeProfitPrice = bid + _stopLossPoints * RiskRewardRatio;
      DrawLine(_currentPriceName, ask, clrDeepSkyBlue, 0);
      lots = OptimumLotsSize(_Symbol, ask, _stopLossPrice, RiskPercentage);
      SetInfo(_currentPriceName, _tradeType + " - Lots: " + DoubleToString(lots, GetLotDigits(_Symbol)));
     }
   else
      if(_stopLossPrice > ask)
        {
         _tradeType = "Sell";
         _stopLossPoints = CalculatePointsBetweenPrices(bid, _stopLossPrice);
         _takeProfitPrice = ask - _stopLossPoints * RiskRewardRatio;
         DrawLine(_currentPriceName, bid, clrDeepSkyBlue, 0);
         lots = OptimumLotsSize(_Symbol, bid, _stopLossPrice, RiskPercentage);
         SetInfo(_currentPriceName, _tradeType + " - Lots: " + DoubleToString(lots, GetLotDigits(_Symbol)));
        }
      else
        {
         _tradeType = "None";
         SetInfo(_currentPriceName, _tradeType + " - Lots: 0.00");
        }
   DrawLine(_stopLossName, _stopLossPrice, clrRed, 1);
   double a = CalculateRiskMoney(ask, _stopLossPrice, lots);//_stopLossPoints * CalculatePipPriceValue(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE), _Point, lots) * bid;

   double stopLossMoney = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercentage / 100;
   SetInfo(_stopLossName, StringFormat("%.2f%% (%.3f %s)", RiskPercentage, a, _baseCurrency));

   DrawLine(_takeProfitName, _takeProfitPrice, clrGreen, 0);
   double takeprofitMoney = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercentage * RiskRewardRatio / 100;
   SetInfo(_takeProfitName, StringFormat("%.2f%% (%.3f %s)", RiskPercentage * RiskRewardRatio, takeprofitMoney, _baseCurrency));
   ChartRedraw();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateRiskMoney(double entryPrice, double stopLossPrice, double lotSize)
  {
   double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT); // Point value per 1 lot
   double pointDifference = MathAbs(stopLossPrice - entryPrice);
   double riskMoney = pointDifference * pointValue * lotSize;
   return riskMoney;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculatePipPriceValue(double contractSize, double pointValue, double lotSize)
  {

   double value = contractSize * pointValue * lotSize;
   Print(contractSize, " - ", pointValue, " - ", lotSize, " - ", value);
   return value;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculatePointsBetweenPrices(double price1, double price2)
  {
   double points = MathAbs(price2 - price1);
   return points;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
short GetLotDigits(string symbol)
  {
   double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   short digits = 1;

   if(volumeStep == 0.01)
      digits = 2;

   if(volumeStep == 0.001)
      digits = 3;

   return digits;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double OptimumLotsSize(string symbol,double entryPoint, double stopLoss, double riskPercent)
  {
   double contractSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   string baseCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
   string profitCurency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   string accountCurency = AccountInfoString(ACCOUNT_CURRENCY);
   double allowedLoss = riskPercent / 100 * AccountInfoDouble(ACCOUNT_EQUITY);
   double lossPoint = MathAbs(entryPoint - stopLoss);
   double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double maxVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   short lotDigits = GetLotDigits(symbol);
   double lotsSize;


   if(profitCurency == accountCurency)
     {
      lotsSize = allowedLoss / lossPoint;
      lotsSize = NormalizeDouble(lotsSize / contractSize, 2);
      return NormalizeDouble(MathMin(maxVolume, lotsSize), lotDigits);
     }
   else
      if(baseCurrency == accountCurency)
        {
         allowedLoss = ask * allowedLoss;
         lotsSize = allowedLoss / lossPoint;
         lotsSize = NormalizeDouble(lotsSize / contractSize, 2);
         return NormalizeDouble(MathMin(maxVolume, lotsSize), lotDigits);
        }
      else
        {
         string transferCurrency = accountCurency + profitCurency;
         ask = SymbolInfoDouble(transferCurrency, SYMBOL_ASK);

         if(ask != 0)
           {
            // Allowed loss in Profit currency Example: USDCHF -----> Return allowed loss in CHF
            allowedLoss = ask * allowedLoss;
            lotsSize = allowedLoss / lossPoint;
            lotsSize = NormalizeDouble(lotsSize / contractSize, 2);
            return NormalizeDouble(MathMin(maxVolume, lotsSize), lotDigits);
           }
         else
           {
            transferCurrency = profitCurency + accountCurency;
            ask = SymbolInfoDouble(transferCurrency, SYMBOL_ASK);
            ask = 1 / ask;
            // Allowed loss in Profit currency Example: USDCHF -----> Return allowed loss in CHF
            allowedLoss = ask * allowedLoss;
            lotsSize = allowedLoss / lossPoint;
            lotsSize = NormalizeDouble(lotsSize / contractSize, 2);
            return NormalizeDouble(MathMin(maxVolume, lotsSize), lotDigits);
           }

         if(profitCurency == "JPY")
           {
            lotsSize = allowedLoss * 1.5 / lossPoint;
            lotsSize = NormalizeDouble(lotsSize / contractSize, 2);
            return NormalizeDouble(MathMin(maxVolume, lotsSize), lotDigits);
           }
         return NormalizeDouble(MathMin(maxVolume, lotsSize), lotDigits);
        }
  }
//+------------------------------------------------------------------+
