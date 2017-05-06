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
input int TakeProfit = 20;
input int StopLoss = 20;

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
        if(OrderType() == OP_BUY && crossCondition() == OP_SELL) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
        }
        if(OrderType() == OP_SELL && crossCondition() == OP_BUY) {
          bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
        }
      }
    }
  }
  
  if(Hour() < Start_Time_H || End_Time_H <= Hour()) {
    return;
  }

  if(OrdersTotal() == 0) {
    if(crossCondition() == OP_BUY && majorTrend() == OP_BUY) {
      int ticket = OrderSend(symbol, OP_BUY, Entry_Lot, Ask, 0, Ask - sl, Ask + tp, NULL, Magic_Number);
    }
    else if(crossCondition() == OP_SELL && majorTrend() == OP_SELL) {
      int ticket = OrderSend(symbol, OP_SELL, Entry_Lot, Bid, 0, Bid + sl, Bid - tp, NULL, Magic_Number);
    }
  }
}
