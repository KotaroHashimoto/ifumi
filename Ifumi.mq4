//+------------------------------------------------------------------+
//|                                                        Ifumi.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

input int Magic_Number = 1;
input int Start_Time_H = 10;
input int End_Time_H = 18;
input double Entry_Lot = 0.1;
input int TakeProfit = 0;
input int StopLoss = 10;
input double MA21_Entry_TH = 1;
input bool Pivot_Exit = True;

enum Size {
  M1 = PERIOD_M1,
  M5 = PERIOD_M5,
  M15 = PERIOD_M15,
  M30 = PERIOD_M30,
  H1 = PERIOD_H1,
  H4 = PERIOD_H4,
  D1 = PERIOD_D1,
  W1 = PERIOD_W1,
  MN1 = PERIOD_MN1
};

input Size Candle_Stick_Size = M5;

double ma125_2;
double ma125_1;
double ma21_2;
double ma21_1;
double ma7_2;
double ma7_1;

double sl;
double tp;
double th;

bool belowPivot;

string symbol;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //---
  ma125_2 = 0;
  ma125_1 = 0;
  ma21_2 = 0;
  ma21_1 = 0;
  ma7_2 = 0;
  ma7_1 = 0;
  
  sl = 10.0 * Point * StopLoss;
  tp = 10.0 * Point * TakeProfit;
  th = 10.0 * Point * MA21_Entry_TH;
  
  belowPivot = (Bid + Ask) / 2.0 < (iOpen(Symbol(), PERIOD_D1, 1) + iClose(Symbol(), PERIOD_D1, 1)) / 2.0;
  
  symbol = Symbol();

  //---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //---   
}

bool pivotCrossed() {

  if(!Pivot_Exit) {
    return True;
  }

  bool isBelow = (Bid + Ask) / 2.0 < (iOpen(Symbol(), PERIOD_D1, 1) + iClose(Symbol(), PERIOD_D1, 1)) / 2.0;

  if(belowPivot == isBelow) {
    return False;
  }
  else {
    belowPivot = isBelow;
    return True;
  }
}

int shortTrend() {

  if(ma7_1 < iClose(Symbol(), Candle_Stick_Size, 1)) {
    return OP_BUY;
  }
  else if(ma7_1 > iClose(Symbol(), Candle_Stick_Size, 1)) {
    return OP_SELL;
  }
  
  return -1;
}

int midTrend() {

  if(ma21_2 + th < ma21_1) {
    return OP_BUY;
  }
  else if(ma21_2 - th > ma21_1){
    return OP_SELL;
  }
  
  return -1;
}

int majorTrend() {

  if(ma125_1 + ma125_2 < ma7_1 + ma7_2 && ma125_1 + ma125_2 < ma21_1 + ma21_2)
    return OP_BUY;
  else if(ma125_1 + ma125_2 > ma7_1 + ma7_2 && ma125_1 + ma125_2 > ma21_1 + ma21_2)
    return OP_SELL;
  else
    return -1;
}


int crossCondition() {

  if(ma7_2 < ma21_2 && ma21_1 < ma7_1)
    return OP_BUY;
  else if(ma7_2 > ma21_2 && ma21_1 > ma7_1)
    return OP_SELL;
  else
    return -1;
}


double sltp(double price, double delta) {

  if(delta == 0.0) {
    return 0;
  }
  else {
    return NormalizeDouble(price + delta, Digits);
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

  ma125_1 = iMA(NULL, Candle_Stick_Size, 125, 0, MODE_SMA, PRICE_WEIGHTED, 1);
  ma125_2 = iMA(NULL, Candle_Stick_Size, 125, 0, MODE_SMA, PRICE_WEIGHTED, 2);
  ma21_1 = iMA(NULL, Candle_Stick_Size, 21, 0, MODE_SMA, PRICE_WEIGHTED, 1);
  ma7_1 = iMA(NULL, Candle_Stick_Size, 7, 0, MODE_SMA, PRICE_WEIGHTED, 1);
  ma21_2 = iMA(NULL, Candle_Stick_Size, 21, 0, MODE_SMA, PRICE_WEIGHTED, 2);
  ma7_2 = iMA(NULL, Candle_Stick_Size, 7, 0, MODE_SMA, PRICE_WEIGHTED, 2);

  if(1000.0 < MathAbs(ma125_2 - Bid) / Point || 1000.0 < MathAbs(ma21_2 - Bid) / Point || 1000.0 < MathAbs(ma7_2 - Bid) / Point)
    return;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderMagicNumber() == Magic_Number) {
        if(OrderType() == OP_BUY ) {
          if(crossCondition() == OP_SELL || pivotCrossed()) {
            if(OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Bid, Digits), 0)) {
              return;
            }
          }          
          else if(OrderStopLoss() < Ask - sl && sl != 0.0) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Ask - sl, Digits), OrderTakeProfit(), 0);
          }
        }
        if(OrderType() == OP_SELL) {
          if(crossCondition() == OP_BUY || pivotCrossed()) {
            if(OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Ask, Digits), 0)) {
              return;
            }
          }
          else if(OrderStopLoss() > Bid + sl && sl != 0.0) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Bid + sl, Digits), OrderTakeProfit(), 0);
          }
        }
      }
    }
  }
  
  if(Hour() < Start_Time_H || End_Time_H <= Hour()) {
    return;
  }

  if(OrdersTotal() == 0) {
    if(crossCondition() == OP_BUY && majorTrend() == OP_BUY && shortTrend() == OP_BUY && (midTrend() == OP_BUY || th == 0)) {
      int ticket = OrderSend(symbol, OP_BUY, Entry_Lot, NormalizeDouble(Ask, Digits), 0, sltp(Ask, -1.0 * sl), sltp(Ask, tp), NULL, Magic_Number);
    }
    else if(crossCondition() == OP_SELL && majorTrend() == OP_SELL && shortTrend() == OP_SELL && (midTrend() == OP_SELL || th == 0)) {
      int ticket = OrderSend(symbol, OP_SELL, Entry_Lot, NormalizeDouble(Bid, Digits), 0, sltp(Bid, sl), sltp(Bid, -1.0 * tp), NULL, Magic_Number);
    }
  }
}
