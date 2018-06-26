//+------------------------------------------------------------------+
//|                                              AveragePosition.mq5 |
//|                                     Copyright 2018, Hikaru Horie |
//|             https://github.com/hikaruhorie/mql5-average-position |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Hikaru Horie"
#property link      "https://github.com/hikaruhorie/mql5-average-position"
#property version   "1.00"
#property indicator_chart_window
//--- indicator properties
#property indicator_plots 2

#property indicator_label1 "Buy Line Color"
#property indicator_type1  DRAW_SECTION
#property indicator_color1 clrFuchsia
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2

#property indicator_label2 "Sell Line Color"
#property indicator_type2  DRAW_SECTION
#property indicator_color2 clrAqua
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2

//---
#define DEBUG 0
#define PREFIX_AVERAGE_PRICE_LINE   "Average_Price_Line_"
#define PREFIX_AVERAGE_PRICE_LABEL   "Average_Price_Label_"

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   EventSetTimer(1);
//---
   return(INIT_SUCCEEDED);
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
//---
   refresh_average_line(ChartID());
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }


void refresh_average_line(const long chart_id=0)
  {
   double buy_price = 0.0;
   double sell_price = 0.0;
   double net_price = 0.0;
   double buy_lots = 0.00;
   double sell_lots = 0.0;
   double net_lots = 0.0;
   double buy_profit = 0.0;
   double sell_profit = 0.0;
   double net_profit = 0.0;
   int buy_count = 0;
   int sell_count = 0;
   int net_count = 0;
   double average_price = 0.0;
   int pos_total = PositionsTotal();
   string line_name = PREFIX_AVERAGE_PRICE_LINE + _Symbol;
   string label_name = PREFIX_AVERAGE_PRICE_LABEL + _Symbol;
   int label_x, label_y;

   for (int i = 0; i < pos_total; i++)
     {
      if (PositionGetSymbol(i) == _Symbol)
        {
         ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if (pos_type == POSITION_TYPE_BUY)
           {
            buy_price += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
            buy_lots += PositionGetDouble(POSITION_VOLUME);
            buy_profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            buy_count++;
           }
         else if (pos_type == POSITION_TYPE_SELL)
           {
            sell_price += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME);
            sell_lots += PositionGetDouble(POSITION_VOLUME);
            sell_profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            sell_count++;
           }
        }   
     }
   if (buy_price > 0) buy_price /= buy_lots;
   if (sell_price > 0) sell_price /= sell_lots;

   net_price = buy_price * buy_lots - sell_price * sell_lots;
   net_lots = buy_lots - sell_lots;
   net_profit = buy_profit + sell_profit;
   net_count = buy_count + sell_count;
   
   ObjectDelete(chart_id, line_name); 
   ObjectDelete(chart_id   , label_name); 

   if (net_count > 0)
     {
      average_price = net_price / net_lots;
      if (DEBUG)
        {
         Print("pos_total: " + IntegerToString(pos_total)
            + "\nbuy_price: " + DoubleToString(buy_price)
            + "\nbuy_lots: " + DoubleToString(buy_lots)
            + "\nsell_price: " + DoubleToString(sell_price)
            + "\nsell_lots: " + DoubleToString(sell_lots)
            + "\nnet_price: " + DoubleToString(net_price)
            + "\nnet_lots: " + DoubleToString(net_lots)
            + "\naverage_price: " + DoubleToString(average_price)
         );
        }
     }
   else
     {
      return;
     }

   // draw average price line
   if(!ObjectCreate(chart_id, line_name, OBJ_HLINE ,0 , 0, average_price))
     {
      Print(__FUNCTION__, 
         ": failed to create a horizontal line! Error code = ", GetLastError()); 
      return; 
     }
   ObjectSetInteger(chart_id, line_name, OBJPROP_COLOR, net_lots > 0 ? indicator_color1 : indicator_color2); 
   ObjectSetInteger(chart_id, line_name, OBJPROP_STYLE, indicator_style1); 
   ObjectSetInteger(chart_id, line_name, OBJPROP_WIDTH, indicator_width1); 
   ObjectSetInteger(chart_id, line_name, OBJPROP_BACK, true); 
   ObjectSetInteger(chart_id, line_name, OBJPROP_SELECTABLE, false); 
   ObjectSetInteger(chart_id, line_name, OBJPROP_SELECTED, false); 
   ObjectSetInteger(chart_id, line_name, OBJPROP_HIDDEN, false); 
   ObjectSetInteger(chart_id, line_name, OBJPROP_ZORDER, 0); 

   // draw average price info
   if(!ObjectCreate(chart_id, label_name, OBJ_LABEL ,0, 0, 0, 0, 0))
     {
      Print(__FUNCTION__, 
         ": failed to create a label! Error code = ", GetLastError()); 
      return; 
     }
   ObjectSetString(chart_id, label_name, OBJPROP_TEXT,
      (net_lots > 0 ? "Buy: " : "Sell: ")
      + DoubleToString(average_price, 5)
      + " (" + DoubleToString(MathAbs(net_lots), 2) + " lots)");
   ObjectSetString(chart_id, label_name, OBJPROP_FONT, "Times New Roman");
   ObjectSetInteger(chart_id, label_name, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(chart_id, label_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(chart_id, label_name, OBJPROP_CORNER, 0);
   ChartTimePriceToXY(chart_id, 0, TimeCurrent(), average_price, label_x, label_y);
   ObjectSetInteger(chart_id, label_name, OBJPROP_XDISTANCE, label_x);
   ObjectSetInteger(chart_id, label_name, OBJPROP_YDISTANCE, label_y);
   
   return;
}
//+------------------------------------------------------------------+
