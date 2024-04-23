//+------------------------------------------------------------------+
//|                                                      PTrader.mq5 |
//|                                        Copyright 2024, Peyman B. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Peyman B."
#property link      "https://www.instagram.com/p2436b"
#property version   "1.00"

/*
#import "user32.dll"
// GetKeyState() checks if the key was pressed at the same time as the WM_KEYDOWN message came, GetAsyncKeyState() checks if it is still down.
int GetKeyState(int nVirtKey);
short GetAsyncKeyState(int nVirtKey);
#import

// https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
int VK_CONTROL = 0x11;
int VK_SHIFT = 0x10;
*/

#include <Trade/Trade.mqh>

#define T_Key 0x54
#define H_Key 0x48
#define SL_LINE_NAME "StopLoss"
#define TP_LINE_NAME "TakeProfit"
#define ExpertComment "PTrader"

input uint MagicNumber = 2436; // Magic Number
input double RiskPercentage = 1; // Risk Percentage
input double RiskRewardRatio = 1; // Risk Reward Ratio
input int SlDefaultPoints = 200; // Default Stop Loss Points

bool _isActive = true;
CTrade _trade;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
  _trade.SetExpertMagicNumber(MagicNumber);
  Calculate();
  ChartRedraw();
  return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  DeleteDrawings();
  ChartRedraw();
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
  Calculate();
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam) {
  if(id == CHARTEVENT_KEYDOWN) {
    int keyCode = (int)lparam;
    int shiftKeyState = TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT);

    if((shiftKeyState & 0x8000) != 0 && keyCode == T_Key && _isActive) {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double tpPrice = ObjectGetDouble(0, TP_LINE_NAME, OBJPROP_PRICE);
      double slPrice = ObjectGetDouble(0, SL_LINE_NAME, OBJPROP_PRICE);
      if(slPrice < MathMin(ask, bid)) {
        double volume = OptimumVolumeSize(_Symbol, ask, slPrice, RiskPercentage);
        _trade.Buy(volume, NULL, 0, slPrice, tpPrice, ExpertComment);
        return;
      }

      if(slPrice > MathMax(ask, bid)) {
        double volume = OptimumVolumeSize(_Symbol, bid, slPrice, RiskPercentage);
        _trade.Sell(volume, NULL, 0, slPrice, tpPrice, ExpertComment);
        return;
      }
    }

    if(keyCode == H_Key) {
      _isActive = !_isActive;
      if(_isActive == true) {
        Calculate();
      } else {
        DeleteDrawings();
        Comment(" PTrader is deactivated");
      }
      ChartRedraw();
      return;
    }
  }

  if(id == CHARTEVENT_OBJECT_DRAG && _isActive == true) {
    Calculate();
    ChartRedraw();
  }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteDrawings() {
  Comment("");
  ObjectDelete(0, TP_LINE_NAME);
  ObjectDelete(0, SL_LINE_NAME);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLine(string name, double price, color _color = clrGreen, long isSelectable = 0, int width = 4) {
  if(ObjectFind(0, name) < 0) {
    ObjectCreate(0, name, OBJ_HLINE, 0, NULL, price);
    ObjectSetInteger(0, name, OBJPROP_COLOR, _color);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, isSelectable);
  } else {
    ObjectSetDouble(0, name, OBJPROP_PRICE, price);
  }
  ObjectSetInteger(0, name, OBJPROP_SELECTED, isSelectable);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Calculate() {

  if(_isActive == false)
    return;

  double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

  if(ObjectFind(0, SL_LINE_NAME) == -1) {
    DrawLine(SL_LINE_NAME, bid - SlDefaultPoints * _Point, clrRed, 1);
  }

  double slPrice = ObjectGetDouble(0, SL_LINE_NAME, OBJPROP_PRICE);
  //double slAsk = slPrice - ask;
  //double slBid = slPrice - bid;

  string comments = StringFormat(
                      " Account Currency: %s\n Risk Percentage: %g\n Reward Ratio: %g",
                      AccountInfoString(ACCOUNT_CURRENCY),
                      RiskPercentage,
                      RiskRewardRatio);

  if(slPrice < MathMin(ask, bid)) {
    double volume = OptimumVolumeSize(_Symbol, ask, slPrice, RiskPercentage);
    Comment(comments, "\n Trade Type: Long\n Volume: ", volume);
    double slAsk = (slPrice - ask) * RiskRewardRatio;
    DrawLine(TP_LINE_NAME, ask - slAsk);
  } else if(slPrice > MathMax(ask, bid)) {
    double volume = OptimumVolumeSize(_Symbol, bid, slPrice, RiskPercentage);
    Comment(comments, "\n Trade Type: Short\n Volume: ", volume);
    double slBid = (slPrice - bid) * RiskRewardRatio;
    DrawLine(TP_LINE_NAME, bid - slBid);
  } else {
    Comment("Trade Type: None");
    ObjectDelete(0, TP_LINE_NAME);
  }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
short GetVoumeDigits(string symbol) {
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
double OptimumVolumeSize(string symbol,double entryPoint, double stopLoss, double riskPercent) {
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
  short volumeDigits = GetVoumeDigits(symbol);
  double volume;
  if(profitCurency == accountCurency) {
    volume = allowedLoss / lossPoint;
    volume = NormalizeDouble(volume / contractSize, 2);
    return NormalizeDouble(MathMin(maxVolume, volume), volumeDigits);
  } else if(baseCurrency == accountCurency) {
    allowedLoss = ask * allowedLoss;
    volume = allowedLoss / lossPoint;
    volume = NormalizeDouble(volume / contractSize, 2);
    return NormalizeDouble(MathMin(maxVolume, volume), volumeDigits);
  } else {
    string transferCurrency = accountCurency + profitCurency;
    ask = SymbolInfoDouble(transferCurrency, SYMBOL_ASK);
    if(ask != 0) {
      // Allowed loss in Profit currency Example: USDCHF -----> Return allowed loss in CHF
      allowedLoss = ask * allowedLoss;
      volume = allowedLoss / lossPoint;
      volume = NormalizeDouble(volume / contractSize, 2);
      return NormalizeDouble(MathMin(maxVolume, volume), volumeDigits);
    } else {
      transferCurrency = profitCurency + accountCurency;
      ask = SymbolInfoDouble(transferCurrency, SYMBOL_ASK);
      ask = 1 / ask;
      // Allowed loss in Profit currency Example: USDCHF -----> Return allowed loss in CHF
      allowedLoss = ask * allowedLoss;
      volume = allowedLoss / lossPoint;
      volume = NormalizeDouble(volume / contractSize, 2);
      return NormalizeDouble(MathMin(maxVolume, volume), volumeDigits);
    }
    if(profitCurency == "JPY") {
      volume = allowedLoss * 1.5 / lossPoint;
      volume = NormalizeDouble(volume / contractSize, 2);
      return NormalizeDouble(MathMin(maxVolume, volume), volumeDigits);
    }
    return NormalizeDouble(MathMin(maxVolume, volume), volumeDigits);
  }
}
//+------------------------------------------------------------------+
