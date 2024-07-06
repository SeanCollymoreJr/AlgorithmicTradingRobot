//+------------------------------------------------------------------+
//|                                              Forever Free EA.mq4 |
//|                                     Sean Addington Collymore Jr. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Forever Free Inc."
#property link      ""
#property version   ""
#property strict
#include <Trade/Trade.mqh>
#include <Controls/Button.mqh>
#include <Trade/SymbolInfo.mqh>


CTrade tradeOperation;
CButton CloseLongs, CloseShorts, CloseAll, disableLongsButton, disableShortsButton, disableTradingButton;

CSymbolInfo SymInf;

int currentSecond;


//===================================================================================================
input string   SYMBOLTYPE = "---- Symbol Type ----";

enum SymbolTypeEnum
{
   CurrencyPair = 0,
   Index = 1,
};

input SymbolTypeEnum SymbolType = CurrencyPair;

//===================================================================================================

//--- input parameters
input string   MAGIC = "---- Magic Number Engine ----";

input bool     EnableEngineA = true;
input int      MagicNumberA = 1738;
input bool     EnableEngineB = true;
input int      MagicNumberB = 1099;

//===================================================================================================

input string   PANEL = "---- Panel Settings ----";

input bool     EnablePriceOnScreen = true;
input bool     EnableSymbolOnScreen = true;
input bool     EnablePercentChangeOnScreen = true;
input bool     EnableSpreadOnScreen = true;
input bool     EnableMaxDDOnScreen = true;
input bool     EnableMaxProfitOnScreen = true;
input bool     EnableMinimumEquityOnScreen = true;
input bool     EnableRestrictionsOnScreen = true;
input bool     EnableTotalVolumeOnScreen = true;
input bool     EnableDailyRangeOnScreen = true;

//===================================================================================================

input string   LOTCONFIGURATION = "---- Config Lot INIT ----";
// Create Enum List
enum LotModeEnum
{
   FixedLotSize = 0,
   PercentOfAccount = 1,
};
input LotModeEnum LotMode = FixedLotSize;
input double FixedLot = 0.01;
input double AccountPercentageToRisk = 0.01;
double LotSize = FixedLot;

// This will be calculated based on the Symbol's "DIGITT" 
input bool UseTakeProfit = true;
input double TakeProfitInPips = 10.0;

input bool UseStopLoss = false;
input double StopLossInPips = 5.0;

//===================================================================================================

input string   GRIDCONFIGURATION = "---- Config Grid ----";
enum TypeGridLotEnum
{
   MartingaleLot = 0,
   MartingaleFLEX = 1,
   LotFixed = 2,
   
};
input TypeGridLotEnum TypeGridLot = MartingaleLot;

input double GridIncrementFactor = 2.0;
input int MaxNumberOfTrades = 5;
input double StepSizeInPips_ = 3.0;

input double STEPLOT_ = 1.0;

input double MAXLOT = 99.0;

//===================================================================================================

input string   TRENDMODE = "---- Trend Mode Settings ----";

enum TrendModeEnum
{
   Uptrend = 0,
   Downtrend = 1,
   
};

input bool EnableTrendMode = false;
input TrendModeEnum TrendType = Uptrend;

//===================================================================================================

input string   TimeFrame = "---- Timeframe to Use ----";
enum TimeFrameEnum
{
   Current,
   M1 = 1,
   M5 = 5,
   M15 = 15,
   M30 = 30,
   H1 = 60,
   H4 = 240,
   DAILY = 1440,
   WEEKLY = 10080
,};
input TimeFrameEnum TimeFrameOpenOneCandle = Current;

//===================================================================================================

input string   EQUITYGUARDIAN = "---- Equity Guardian ----";
input bool UseTakeEquityStop = false;
input double CloseAllAtThisLossAmount = 50.0;

input bool UseTakeEquityTakeProfit = false;
input double CloseAllAtThisProfitAmount = 100.0;

//===================================================================================================

input string   RANGEGUARDIAN = "---- Range Guardian ----";
input bool UseRangeGaurdian = false;
input double MaxRange = 100.0;

enum RangeGuardianEnum
{
   DisableTradingOnly = 1,
   DisableTradingAndCloseAllTrades = 2,
};

input RangeGuardianEnum RangeGuardianAction = DisableTradingOnly;
//===================================================================================================

input string   HEDGEWIZARD = "---- Hedge Wizard ----";
input bool     EnableHedgeWizard = false;
input double   StartHedgingAtDollarAmount = 250;
input double   HedgePercentage = 0.25;
input int      HedgeDivisor = 2;

//===================================================================================================

// Other essential variables

double balance = 0;

double AlligatorJawsBuffer[1000];

int bias_counter = 0;
string bias = "";

int newCandle = 0;
int sessionLosses = 0;
int sessionWins = 0;

int TotalNumOfLongs = 0;
int TotalNumOfShorts = 0;

bool isLong = false;
bool isShort = false;
int numofOrders = 0;
double currentLongStopLoss = 0;
double currentShortStopLoss = 0;

double breakoutPendingSL = 0;

double currentLongTakeProfit = 0;
double currentShortTakeProfit = 0;

double currentLongAvg = 0;
double currentShortAvg = 0;

double currentLongBase = 0;
double currentShortBase = 0;

double LongTriggerLevels[10000];
double ShortTriggerLevels[10000];

// These are flipped true when the respective level is triggered
bool LongTriggerLevelsBooleans[10000];
bool ShortTriggerLevelsBooleans[10000];

double Long_volume = 0.0;
double Short_volume = 0.0;
double Total_volume = NormalizeDouble(0.0,2);
double Total_Long_Volume = 0.0;
double Total_Short_Volume = 0.0;

double currentEntryPrice = 0;
double currentBELevel = 0;
double newBELevel = 0;

double TakeProfitPrice = 0;
double TrailingStopPrice = 0;
int minuteTF = 60;
//int CurrentHour = Hour();
bool UpdatedHour = false;

// Restrict Trading
bool RestrictTrading = false;
bool RestrictLongs = false;
bool RestrictShorts = false;

// Disable Trading
bool disableTrading = false;
bool disableLongs = false;
bool disableShorts = false;

// Get Screen Size

long height=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
long width=ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
double buttonWidthPadding = floor(width * 0.08);
double buttonHeightPadding = floor(height * 0.125);


double MaxProfit = 0.0;
double MaxDD = 0.0; //*
double MaxLongDD = 0.0;
double MaxShortDD = 0.0;
double symbolProfit = 0.0;
double symbolLongProfit = 0.0;
double symbolShortProfit = 0.0;

// Global declaration of input processor variable
double TP;
double SL;
double STEPLOT;
double StepSizeInPips;

double InitialLongGridBase = 0;
double InitialShortGridBase = 0;

bool LongsActive = false;

bool ShortsActive = false;
                
double dailylow = 0.0;
double dailyhigh = 0.0;

bool HedgeAgainstLongs = false;
bool HedgeAgainstShorts = false;
bool HedgeTrigger = false;

double Old_Long_TP = 0.0;
double Old_Short_TP = 0.0;
double Old_Long_SL = 0.0;
double Old_Short_SL = 0.0;

MqlTick last_tick;
//=========================================================================================================================================================================================================
//=========================================================================================================================================================================================================

// Necessary conversion functions

bool ObjectSetMQL4(string name,
                   int index,
                   double value)
  {
   switch(index)
     {
      case OBJPROP_COLOR:
         ObjectSetInteger(0,name,OBJPROP_COLOR,(int)value);return(true);
      case OBJPROP_STYLE:
         ObjectSetInteger(0,name,OBJPROP_STYLE,(int)value);return(true);
      case OBJPROP_WIDTH:
         ObjectSetInteger(0,name,OBJPROP_WIDTH,(int)value);return(true);
      case OBJPROP_BACK:
         ObjectSetInteger(0,name,OBJPROP_BACK,(int)value);return(true);
      case OBJPROP_RAY:
         ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,(int)value);return(true);
      case OBJPROP_ELLIPSE:
         ObjectSetInteger(0,name,OBJPROP_ELLIPSE,(int)value);return(true);
      case OBJPROP_SCALE:
         ObjectSetDouble(0,name,OBJPROP_SCALE,value);return(true);
      case OBJPROP_ANGLE:
         ObjectSetDouble(0,name,OBJPROP_ANGLE,value);return(true);
      case OBJPROP_ARROWCODE:
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,(int)value);return(true);
      case OBJPROP_TIMEFRAMES:
         ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,(int)value);return(true);
      case OBJPROP_DEVIATION:
         ObjectSetDouble(0,name,OBJPROP_DEVIATION,value);return(true);
      case OBJPROP_FONTSIZE:
         ObjectSetInteger(0,name,OBJPROP_FONTSIZE,(int)value);return(true);
      case OBJPROP_CORNER:
         ObjectSetInteger(0,name,OBJPROP_CORNER,(int)value);return(true);
      case OBJPROP_XDISTANCE:
         ObjectSetInteger(0,name,OBJPROP_XDISTANCE,(int)value);return(true);
      case OBJPROP_YDISTANCE:
         ObjectSetInteger(0,name,OBJPROP_YDISTANCE,(int)value);return(true);
      case OBJPROP_LEVELCOLOR:
         ObjectSetInteger(0,name,OBJPROP_LEVELCOLOR,(int)value);return(true);
      case OBJPROP_LEVELSTYLE:
         ObjectSetInteger(0,name,OBJPROP_LEVELSTYLE,(int)value);return(true);
      case OBJPROP_LEVELWIDTH:
         ObjectSetInteger(0,name,OBJPROP_LEVELWIDTH,(int)value);return(true);

      default: return(false);
     }
   return(false);
  }

bool ObjectSetTextMQL4(string name,
                       string text,
                       int font_size,
                       string font="",
                       color text_color=CLR_NONE)
  {
   int tmpObjType=(int)ObjectGetInteger(0,name,OBJPROP_TYPE);
   if(tmpObjType!=OBJ_LABEL && tmpObjType!=OBJ_TEXT) return(false);
   if(StringLen(text)>0 && font_size>0)
     {
      if(ObjectSetString(0,name,OBJPROP_TEXT,text)==true
         && ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size)==true)
        {
         if((StringLen(font)>0)
            && ObjectSetString(0,name,OBJPROP_FONT,font)==false)
            return(false);
         if(text_color>-1
            && ObjectSetInteger(0,name,OBJPROP_COLOR,text_color)==false)
            return(false);
         return(true);
        }
      return(false);
     }
   return(false);
  }

int SecondsMQL4()
  {
   MqlDateTime tm;
   TimeCurrent(tm);
   return(tm.sec);
  }
  
datetime iTimeMQL4(string symbol,int tf,int index)

{
   if(index < 0) return(-1);
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   datetime Arr[];
   if(CopyTime(symbol, timeframe, index, 1, Arr)>0)
        return(Arr[0]);
   else return(-1);
}  
  
  
ENUM_TIMEFRAMES TFMigrate(int tf)
  {
   switch(tf)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      
      default: return(PERIOD_CURRENT);
     }
  }  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 

   // Process Input Variables
   
   if (SymbolType == CurrencyPair)
   TP = TakeProfitInPips/(MathPow(10,Digits()-1));
   if (SymbolType == Index)
   TP = TakeProfitInPips;
   
   if (SymbolType == CurrencyPair)
   SL = StopLossInPips/(MathPow(10,Digits()-1));
   if (SymbolType == Index)
   SL = StopLossInPips;
   
   if (SymbolType == CurrencyPair)
   StepSizeInPips = StepSizeInPips_/(MathPow(10,Digits()-1));
   if (SymbolType == Index)
   StepSizeInPips = StepSizeInPips_;
   
   if (SymbolType == CurrencyPair)
   STEPLOT = STEPLOT_/(MathPow(10,Digits()-1));
   if (SymbolType == Index)
   STEPLOT = STEPLOT_;
   
   // Set up Grid
   SymbolInfoTick(_Symbol,last_tick);
   
   InitialLongGridBase = last_tick.ask - STEPLOT;
   InitialShortGridBase = last_tick.bid + STEPLOT;
   
   
   // print screen size
   Print("CHART_HEIGHT_IN_PIXELS =",height,"pixels");
   Print("CHART_WIDTH_IN_PIXELS =",width,"pixels");
   
   // Create Label Objects for On-Screen Statistics
   
   int padNext = 24;
   
   if(EnablePriceOnScreen == true){
   ObjectCreate(0,"Average Price",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Average Price", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Average Price", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Average Price", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableSymbolOnScreen == true){
   ObjectCreate(0,"Instrument",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Instrument", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Instrument", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Instrument", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnablePercentChangeOnScreen == true){
   ObjectCreate(0,"Percent Change",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Percent Change", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Percent Change", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Percent Change", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableSpreadOnScreen == true){
   ObjectCreate(0,"Spread",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Spread", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Spread", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Spread", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableMaxDDOnScreen == true){
   ObjectCreate(0,"Max DD",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Max DD", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Max DD", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Max DD", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableMaxProfitOnScreen == true){
   ObjectCreate(0,"Max Profit",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Max Profit", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Max Profit", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Max Profit", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableMinimumEquityOnScreen == true){
   ObjectCreate(0,"Minimum Equity",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Minimum Equity", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Minimum Equity", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Minimum Equity", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableRestrictionsOnScreen == true){
   ObjectCreate(0,"Trade Permission",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Trade Permission", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Trade Permission", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Trade Permission", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableTotalVolumeOnScreen == true){
   ObjectCreate(0,"Total Volume",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Total Volume", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Total Volume", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Total Volume", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableDailyRangeOnScreen == true){
   ObjectCreate(0,"Daily Range",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Daily Range", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Daily Range", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Daily Range", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   if(EnableDailyRangeOnScreen == true){
   ObjectCreate(0,"Hedge Status",OBJ_LABEL,0,0,0);
   ObjectSetMQL4("Hedge Status", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetMQL4("Hedge Status", OBJPROP_XDISTANCE, 220);
   ObjectSetMQL4("Hedge Status", OBJPROP_YDISTANCE, padNext);
   padNext += 24;}
   
   
 
   // Create Buttons
   CreateButtons();
   
   // Initialize On-Screen Stats
   
   SymbolInfoTick(_Symbol,last_tick);
   
   string instrument = Symbol(); //*
   double averagePrice = (last_tick.ask + last_tick.bid)/2; //*
   double DailyOpenPrice = iOpen(NULL,PERIOD_D1,0);
   double percentChange = ((averagePrice - DailyOpenPrice)/DailyOpenPrice)*100; //*
   double currentSpread = iSpread(NULL,PERIOD_CURRENT,0); //*
   
   if(SymbolType == CurrencyPair)
   currentSpread /= 10.0;
   if(SymbolType == Index)
   currentSpread /= 100.0;
   
   double currentProfit = AccountInfoDouble(ACCOUNT_PROFIT); 
   double MinimumEquity = AccountInfoDouble(ACCOUNT_PROFIT); //*
   
   
   ObjectSetTextMQL4("Average Price", DoubleToString(averagePrice,Digits()),12,"Arial",clrRed);
   ObjectSetTextMQL4("Instrument", instrument ,12,"Arial",clrAqua);
   ObjectSetTextMQL4("Percent Change", DoubleToString(percentChange,5) + "%",12,"Arial",clrGreen); 
   ObjectSetTextMQL4("Spread", "Spread: " + DoubleToString(currentSpread,1) + " Pips" ,12,"Arial",clrWhite);
   ObjectSetTextMQL4("Max DD", "Max DD: " + DoubleToString(MaxDD,2),12,"Arial",clrWhite);
   ObjectSetTextMQL4("Max Profit", "Max Profit: " + DoubleToString(MaxProfit,2),12,"Arial",clrWhite);
   ObjectSetTextMQL4("Minimum Equity", "Minimum Equity: $" + DoubleToString(MinimumEquity,2),12,"Arial",clrWhite);
   
   if(disableLongs == false && disableShorts == false)
   ObjectSetTextMQL4("Trade Permission", "Trading Enabled",12,"Arial",clrWhite);
   
   if(disableLongs == true && disableShorts == false)
   ObjectSetTextMQL4("Trade Permission", "Shorts Only! Longs Disabled",12,"Arial",clrWhite);
   
   if(disableLongs == false && disableShorts == true)
   ObjectSetTextMQL4("Trade Permission", "Longs Only! Shorts Disabled",12,"Arial",clrWhite);
   
   if((disableLongs == true && disableShorts == true) || disableTrading == true)
   ObjectSetTextMQL4("Trade Permission", "Trading Disabled",12,"Arial",clrWhite);
   
   ObjectSetTextMQL4("Total Volume", "Total Net Volume: " + DoubleToString(Total_volume,2) ,12,"Arial",clrWhite);
   
   dailylow = iLow(NULL,PERIOD_D1,0);
   dailyhigh = iHigh(NULL,PERIOD_D1,0);
   
   ObjectSetTextMQL4("Daily Range", "Max Daily Range: " + DoubleToString(MathAbs(dailyhigh - dailylow) * (MathPow(10,Digits()-1)),2) + " pips" ,12,"Arial",clrWhite);
   
   ObjectSetTextMQL4("Hedge Status", "Hedging Not Enabled" ,12,"Arial",clrWhite);
   
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   for (int i = 0; i < MaxNumberOfTrades; i++)
   {
      LongTriggerLevelsBooleans[i] = false;
      ShortTriggerLevelsBooleans[i] = false;
   }
   if (LotMode == FixedLotSize)
   LotSize = FixedLot;

   if (LotMode == PercentOfAccount)
   { // Calculate lots based on percentage of account

   double AccountRiskAmount = AccountInfoDouble(ACCOUNT_BALANCE)*AccountPercentageToRisk;
   double RiskPerPip = AccountRiskAmount/SL;
   
   if(SymbolType == Index)
   LotSize = RiskPerPip/ SymInf.ContractSize();
   
   if(SymbolType == CurrencyPair)
   LotSize = RiskPerPip/10;
   }     
   
//---
   return(INIT_SUCCEEDED);
  }  
 
 void CreateButtons()
 {
   double widthPadding = width - buttonWidthPadding;
   widthPadding = (int)widthPadding;
   
   double heightPadding = height - buttonHeightPadding;
   heightPadding = (int)heightPadding;
   
   // Close Buttons
   
   CloseLongs.Create(0,"CloseLongs",0,0,0,60,35);
   CloseLongs.Text("CloseAllLongs");
   CloseLongs.FontSize(6);
   CloseLongs.ColorBackground(clrLightSlateGray);
   CloseLongs.ColorBorder(clrBlack);
   // CloseLongs.Move(widthPadding,heightPadding - 110);
   ObjectSetMQL4("CloseLongs", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
   ObjectSetMQL4("CloseLongs", OBJPROP_XDISTANCE, 65);
   ObjectSetMQL4("CloseLongs", OBJPROP_YDISTANCE, 110);
   
   CloseShorts.Create(0,"CloseShorts",0,0,0,60,35);
   CloseShorts.Text("CloseAllShorts");
   CloseShorts.FontSize(6);
   CloseShorts.ColorBackground(clrLightSlateGray);
   CloseShorts.ColorBorder(clrBlack);
   // CloseShorts.Move(widthPadding,heightPadding - 55);
   ObjectSetMQL4("CloseShorts", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
   ObjectSetMQL4("CloseShorts", OBJPROP_XDISTANCE, 65);
   ObjectSetMQL4("CloseShorts", OBJPROP_YDISTANCE, 75);
   
   CloseAll.Create(0,"CloseAll",0,0,0,60,35);
   CloseAll.Text("CloseAllTrades");
   CloseAll.FontSize(6);
   CloseAll.ColorBackground(clrLightSlateGray);
   CloseAll.ColorBorder(clrBlack);
   // CloseAll.Move(widthPadding,heightPadding);
   ObjectSetMQL4("CloseAll", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
   ObjectSetMQL4("CloseAll", OBJPROP_XDISTANCE, 65);
   ObjectSetMQL4("CloseAll", OBJPROP_YDISTANCE, 40);
   
   // Restriction Buttons
   
   disableLongsButton.Create(0,"DisableLongs",0,0,0,60,35);
   disableLongsButton.Text("DisableLongs");
   disableLongsButton.FontSize(6);
   disableLongsButton.ColorBackground(clrLightSlateGray);
   disableLongsButton.ColorBorder(clrBlack);
   // CloseLongs.Move(widthPadding,heightPadding - 110);
   ObjectSetMQL4("DisableLongs", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
   ObjectSetMQL4("DisableLongs", OBJPROP_XDISTANCE, 130);
   ObjectSetMQL4("DisableLongs", OBJPROP_YDISTANCE, 110);
   
   disableShortsButton.Create(0,"DisableShorts",0,0,0,60,35);
   disableShortsButton.Text("DisableShorts");
   disableShortsButton.FontSize(6);
   disableShortsButton.ColorBackground(clrLightSlateGray);
   disableShortsButton.ColorBorder(clrBlack);
   // CloseShorts.Move(widthPadding,heightPadding - 55);
   ObjectSetMQL4("DisableShorts", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
   ObjectSetMQL4("DisableShorts", OBJPROP_XDISTANCE, 130);
   ObjectSetMQL4("DisableShorts", OBJPROP_YDISTANCE, 75);
   
   disableTradingButton.Create(0,"DisableTrading",0,0,0,60,35);
   disableTradingButton.Text("DisableTrading");
   disableTradingButton.FontSize(6);
   disableTradingButton.ColorBackground(clrLightSlateGray);
   disableTradingButton.ColorBorder(clrBlack);
   // CloseAll.Move(widthPadding,heightPadding);
   ObjectSetMQL4("DisableTrading", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
   ObjectSetMQL4("DisableTrading", OBJPROP_XDISTANCE, 130);
   ObjectSetMQL4("DisableTrading", OBJPROP_YDISTANCE, 40);
 
 }
   
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
  ObjectDelete(0,"Average Price");
  ObjectDelete(0,"Instrument");
  ObjectDelete(0,"Percent Change");
  ObjectDelete(0,"Spread");
  ObjectDelete(0,"Max DD");
  ObjectDelete(0,"Max Profit");
  ObjectDelete(0,"Minimum Equity");
  ObjectDelete(0,"Trade Permission");
  ObjectDelete(0,"Total Volume");
  ObjectDelete(0,"Daily Range");
  ObjectDelete(0,"Hedge Status");
//--- destroy timer
  EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

bool IsNewCandle()
{
   datetime NewCandleTime = TimeCurrent();
   // If the time of the candle when the function ran last
   // is the same as the time this candle started,
   // return false, because it is not a new candle.
   if (NewCandleTime == iTimeMQL4(Symbol(), TimeFrameOpenOneCandle, 0)) return false;
   
   // Otherwise, it is a new candle and we need to return true.
   else
   {
      // If it is a new candle, then we store the new value.
      NewCandleTime = iTimeMQL4(Symbol(), TimeFrameOpenOneCandle, 0);
      return true;
   }
}

void OnTick()
  {
//---
   // Update On-Screen Stats
   SymbolInfoTick(_Symbol,last_tick);

   string instrument = Symbol(); //*
   double averagePrice = (last_tick.ask + last_tick.bid)/2; //*
   double DailyOpenPrice = iOpen(NULL,PERIOD_D1,0);
   double percentChange = ((averagePrice - DailyOpenPrice)/DailyOpenPrice)*100; //*
   double currentSpread = iSpread(NULL,PERIOD_CURRENT,0); //*
   
   if(SymbolType == CurrencyPair)
   currentSpread /= 10.0;
   if(SymbolType == Index)
   currentSpread /= 100.0;
   
   double currentProfit = AccountInfoDouble(ACCOUNT_PROFIT); 
   double MinimumEquity = AccountInfoDouble(ACCOUNT_BALANCE); //*
   
   
   ObjectSetTextMQL4("Average Price", DoubleToString(averagePrice,Digits()),12,"Arial",clrRed);
   ObjectSetTextMQL4("Instrument", instrument ,12,"Arial",clrAqua);
   ObjectSetTextMQL4("Percent Change", DoubleToString(percentChange,5) + "%",12,"Arial",clrGreen); 
   ObjectSetTextMQL4("Spread", "Spread: " + DoubleToString(currentSpread,1) + " Pips" ,12,"Arial",clrWhite);
   ObjectSetTextMQL4("Max DD", "Max DD: " + DoubleToString(MaxDD,2),12,"Arial",clrWhite);
   ObjectSetTextMQL4("Max Profit", "Max Profit: " + DoubleToString(MaxProfit,2),12,"Arial",clrWhite);
   ObjectSetTextMQL4("Minimum Equity", "Minimum Equity: $" + DoubleToString(MinimumEquity,2),12,"Arial",clrWhite);
   
   if(disableLongs == false && disableShorts == false)
   ObjectSetTextMQL4("Trade Permission", "Trading Enabled",12,"Arial",clrWhite);
   
   if(disableLongs == true && disableShorts == false)
   ObjectSetTextMQL4("Trade Permission", "Shorts Only! Longs Disabled",12,"Arial",clrWhite);
   
   if(disableLongs == false && disableShorts == true)
   ObjectSetTextMQL4("Trade Permission", "Longs Only! Shorts Disabled",12,"Arial",clrWhite);
   
   if((disableLongs == true && disableShorts == true) || disableTrading == true)
   ObjectSetTextMQL4("Trade Permission", "Trading Disabled",12,"Arial",clrWhite);
   
   ObjectSetTextMQL4("Total Volume", "Total Net Volume: " + DoubleToString(Total_volume,2) ,12,"Arial",clrWhite);
   
   dailylow = iLow(NULL,PERIOD_D1,0);
   dailyhigh = iHigh(NULL,PERIOD_D1,0);
   
   ObjectSetTextMQL4("Daily Range", "Max Daily Range: " + DoubleToString(MathAbs(dailyhigh - dailylow) * (MathPow(10,Digits()-1)), 2) + " pips" ,12,"Arial",clrWhite);
   
   if(HedgeAgainstLongs == false && HedgeAgainstShorts == false)
   ObjectSetTextMQL4("Hedge Status", "Hedging Not Enabled" ,12,"Arial",clrWhite);
   
   if(HedgeAgainstLongs == true && HedgeAgainstShorts == false)
   ObjectSetTextMQL4("Hedge Status", "Hedging Against Longs" ,12,"Arial",clrWhite);
   
   if(HedgeAgainstLongs == false && HedgeAgainstShorts == true)
   ObjectSetTextMQL4("Hedge Status", "Hedging Against Shorts" ,12,"Arial",clrWhite);
 
   // Get the current number of open trades
         numofOrders = PositionsTotal();
                  
         // Count the number of long and short trades
         CountLongShortTrades();
                  
         if(TotalNumOfLongs == 0 && TotalNumOfShorts == 0)
         {
         MinimumEquity = AccountInfoDouble(ACCOUNT_BALANCE);
         balance = AccountInfoDouble(ACCOUNT_BALANCE);
         RestrictTrading = false;
         MaxDD = 0;
         MaxProfit = 0;
         HedgeAgainstLongs = false;
         HedgeAgainstShorts = false;
         HedgeTrigger = false;
         ResetLongLevelsData();
         ResetShortLevelsData();
         
         }

         // reset data in total number of long and short trades are zero
         if(TotalNumOfLongs == 0)
         {
         
         if(EnableTrendMode == false)
         ResetLongLevelsData();
         
         RestrictLongs = false;
         Long_volume = LotSize;
         MaxLongDD = 0;
         
         if (LongsActive == true){
         InitialLongGridBase = last_tick.ask - STEPLOT;
         LongsActive = false;
         if(HedgeAgainstLongs == true)
         HedgeAgainstLongs = false;
         HedgeTrigger = false;        
         }
         
         
         }
         
         if(TotalNumOfShorts == 0)
         {
         
         if(EnableTrendMode == false)
         ResetShortLevelsData();
         
         RestrictShorts = false;
         Short_volume = LotSize;
         MaxShortDD = 0;
         
         if(ShortsActive == true){
         InitialShortGridBase = last_tick.bid + STEPLOT;
         ShortsActive = false;
         if(HedgeAgainstShorts == true)
         HedgeAgainstShorts = false;
         HedgeTrigger = false;
         }
         
         
         }
   
   // Check if new candle
      if(IsNewCandle())
      {
         
         // Check if price reached the longs grid
         if (last_tick.ask < InitialLongGridBase)
         {
            if(HedgeAgainstShorts == true)
            {
               LotSize = Total_Short_Volume * HedgePercentage;
            }
            else 
            LotSize = FixedLot;
            
            if(TotalNumOfLongs == 0 && RestrictTrading == false && RestrictLongs == false)
            {
               if(EnableTrendMode == false)
               currentLongBase = OpenLongPosition(LotSize);
               
               if(EnableTrendMode == true && TrendType == Uptrend)
               currentLongBase = OpenLongPosition(LotSize);
               
               if(EnableTrendMode == true && TrendType == Downtrend && TotalNumOfShorts == 0)
               currentLongBase = OpenShortPosition(LotSize);
            }
         }
         
         // Check if price reached the shorts grid
         if (last_tick.bid > InitialShortGridBase)
         {
            if(HedgeAgainstLongs == true)
            {
               LotSize = Total_Long_Volume * HedgePercentage;
            }
            else 
            LotSize = FixedLot;
            
            if(TotalNumOfShorts == 0 && RestrictTrading == false && RestrictShorts == false)
            {
               if(EnableTrendMode == false)
               currentShortBase = OpenShortPosition(LotSize);
               
               if(EnableTrendMode == true && TrendType == Uptrend && TotalNumOfLongs == 0)
               currentShortBase = OpenLongPosition(LotSize);
               
               if(EnableTrendMode == true && TrendType == Downtrend)
               currentShortBase = OpenShortPosition(LotSize);
            }
         }                        
         
         
         if (TotalNumOfLongs == 0 && TotalNumOfShorts != 0)
         InitialLongGridBase = last_tick.ask - STEPLOT;
                           
         
         if(TotalNumOfShorts == 0 && TotalNumOfLongs != 0)
         InitialShortGridBase = last_tick.bid + STEPLOT;
         
      }
      
         // Check if triggers have been reached
         for(int i = 0; i < MaxNumberOfTrades; i++)
         {
            // First check if long triggers have been activated
            if( LongTriggerLevelsBooleans[i] == false && RestrictTrading == false && LongTriggerLevels[i]!= 0.0)
            {
               
               if(last_tick.ask < LongTriggerLevels[i] && HedgeAgainstShorts == true && EnableTrendMode == false)
               {
                  if(TypeGridLot == MartingaleLot)
                  {
                     Long_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Long_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Long_volume = LotSize;
                  }
                  if(HedgeAgainstShorts == true)
                  {
                     Long_volume = Total_Short_Volume * HedgePercentage;
                  }
                  OpenLongPosition(Long_volume);
                  LongTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", LongTriggerLevels[i], " (HEDGE LONG) Has Been Reached!");
               }
               
               if(last_tick.ask < LongTriggerLevels[i] && HedgeAgainstLongs == true && EnableTrendMode == false)
               {
                  if(TypeGridLot == MartingaleLot)
                  {
                     Long_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Long_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Long_volume = LotSize;
                  }
                  if(HedgeAgainstLongs == true)
                  {
                     Long_volume = Total_Long_Volume * HedgePercentage;
                  }
                  OpenShortPosition(Long_volume);
                  LongTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", LongTriggerLevels[i], " (HEDGE LONG) Has Been Reached!");
               }
               if(last_tick.ask < LongTriggerLevels[i] && HedgeAgainstShorts == false && HedgeAgainstLongs == false && EnableTrendMode == false)
               { 
                  if(TypeGridLot == MartingaleLot)
                  {
                     Long_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Long_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Long_volume = LotSize;
                  }
                  OpenLongPosition(Long_volume);
                  LongTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", LongTriggerLevels[i], " (LONG) Has Been Reached!");
               
               }
               if(last_tick.ask < LongTriggerLevels[i] && EnableTrendMode == true)
               { 
                  if(TypeGridLot == MartingaleLot)
                  {
                     Long_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Long_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Long_volume = LotSize;
                  }
                  if (TrendType == Uptrend)
                  {
                     OpenLongPosition(Long_volume);
                  }
                  if(TrendType == Downtrend)
                  {
                     OpenShortPosition(Long_volume);
                  }
                  LongTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", LongTriggerLevels[i], " (LONG) Has Been Reached!");
               
               }
            }
         
            // Now check if short triggers have been activated
            if(ShortTriggerLevelsBooleans[i] == false && RestrictTrading == false && ShortTriggerLevels[i]!= 0.0)
            {
               if (last_tick.bid > ShortTriggerLevels[i] && HedgeAgainstLongs == true && EnableTrendMode == false)
               { 
                  if(TypeGridLot == MartingaleLot)
                  {
                     Short_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Short_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Short_volume = LotSize;
                  }
                  if(HedgeAgainstLongs == true)
                  {
                     Short_volume = Total_Long_Volume * HedgePercentage;
                  }
                  OpenShortPosition(Short_volume);
                  ShortTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", ShortTriggerLevels[i], " (HEDGE SHORT) Has Been Reached!");
               
               }
               
               if (last_tick.bid > ShortTriggerLevels[i] && HedgeAgainstShorts == true && EnableTrendMode == false)
               { 
                  if(TypeGridLot == MartingaleLot)
                  {
                     Short_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Short_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Short_volume = LotSize;
                  }
                  if(HedgeAgainstShorts == true)
                  {
                     Short_volume = Total_Short_Volume * HedgePercentage;
                  }
                  OpenLongPosition(Short_volume);
                  ShortTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", ShortTriggerLevels[i], " (HEDGE SHORT) Has Been Reached!");
               
               }
               if(last_tick.bid > ShortTriggerLevels[i] && HedgeAgainstLongs == false && HedgeAgainstShorts == false && EnableTrendMode == false)
               { 
                  if(TypeGridLot == MartingaleLot)
                  {
                     Short_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Short_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Short_volume = LotSize;
                  }

                  OpenShortPosition(Short_volume);
                  ShortTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", ShortTriggerLevels[i], " (SHORT) Has Been Reached!");
               }
               if(last_tick.bid > ShortTriggerLevels[i] && EnableTrendMode == true)
               { 
                  if(TypeGridLot == MartingaleLot)
                  {
                     Short_volume *= GridIncrementFactor;
                  }
                  if(TypeGridLot == MartingaleFLEX)
                  {
                     Short_volume *= (GridIncrementFactor * (i+1));
                  }
                  if(TypeGridLot == LotFixed)
                  {
                     Short_volume = LotSize;
                  }
                  
                  if(TrendType == Downtrend)
                  {
                     OpenShortPosition(Short_volume);
                  }
                  
                  if(TrendType == Uptrend)
                  {
                     OpenLongPosition(Short_volume);
                  }
                  
                  ShortTriggerLevelsBooleans[i] = true;
                  Print("Level ",i,": ", ShortTriggerLevels[i], " (SHORT) Has Been Reached!");
               }
            }
             
         }
         
         
         // Check Equity Guardian Conditions
         
         // if equity has dropped below tolerable threshold close all trades
         if (MaxDD < (CloseAllAtThisLossAmount * (-1)) && UseTakeEquityStop == true)
         {
         Print("Equity Stop Reached! Closing all trades and Disabling Trading!");
         disableTrading = true;
         CloseAllTrades();
         }
         
         // if equity has risen above desired threshold close all trades
         if (MaxProfit > CloseAllAtThisProfitAmount && UseTakeEquityTakeProfit == true)
         {
         Print("Equity Take Profit Reached! Closing all trades and Disabling Trading!");
         disableTrading = true;
         CloseAllTrades();
         }
         
         // Range Guardian Conditions
         
         if(UseRangeGaurdian == true)
         {
            // Check Daily Range
            dailylow = iLow(NULL,PERIOD_D1,0);
            dailyhigh = iHigh(NULL,PERIOD_D1,0);
            
            // if daily range is larger than maximum allowed trading range
            
            if(  MathAbs(dailyhigh - dailylow) * (MathPow(10,Digits()-1)) > MaxRange )
            {
               Print("Maximum Range Reached! Performing Range Guardian Action!");
               
               if (RangeGuardianAction == DisableTradingOnly)
               disableTrading = true;
               
               if (RangeGuardianAction == DisableTradingAndCloseAllTrades)
               {
                  disableTrading = true;
                  CloseAllTrades();
               }
            }
         
         }
         
         
         if(HedgeAgainstLongs == true || HedgeAgainstShorts == true)
         {
            if(symbolProfit >= 0)
            CloseAllTrades();
         }

  }
  
 void CountLongShortTrades()
 {
   TotalNumOfLongs = 0;
   TotalNumOfShorts = 0;
   Total_volume = 0.0;
   Total_Long_Volume = 0.0;
   Total_Short_Volume = 0.0;
   symbolProfit = 0;
   symbolLongProfit = 0;
   symbolShortProfit = 0;
   double LongPositionLevel = 0;
   double ShortPositionLevel = 0;
   
   
   
   numofOrders = PositionsTotal();
      if (numofOrders != 0)
      {
      
         for (int pos = 0; pos < numofOrders; pos++)
         {
            if (PositionSelectByTicket(PositionGetTicket(pos)) == true)
            {
               // if longs are open
               if ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == Symbol())
               {
                  TotalNumOfLongs += 1;
                  symbolProfit += PositionGetDouble(POSITION_PROFIT);
                  symbolLongProfit += PositionGetDouble(POSITION_PROFIT);
                  
                  if(PositionGetDouble(POSITION_SL) != currentLongStopLoss || PositionGetDouble(POSITION_TP) != currentLongTakeProfit){
                  bool modifier = tradeOperation.PositionModify(PositionGetInteger(POSITION_TICKET), NormalizeDouble(currentLongStopLoss,Digits()) ,NormalizeDouble(currentLongTakeProfit,Digits()));

                  }
                  
                  LongPositionLevel += PositionGetDouble(POSITION_PRICE_OPEN);
                  Total_volume += PositionGetDouble(POSITION_VOLUME);
                  Total_Long_Volume += PositionGetDouble(POSITION_VOLUME);
               }
               // if shorts are open
               if ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == Symbol())
               {
                  TotalNumOfShorts +=1 ;
                  symbolProfit += PositionGetDouble(POSITION_PROFIT);
                  symbolShortProfit += PositionGetDouble(POSITION_PROFIT); 
                  
                  if(PositionGetDouble(POSITION_SL) != currentShortStopLoss || PositionGetDouble(POSITION_TP) != currentLongTakeProfit){            
                  bool modifier = tradeOperation.PositionModify(PositionGetInteger(POSITION_TICKET), NormalizeDouble(currentShortStopLoss,Digits()), NormalizeDouble(currentShortTakeProfit,Digits()));
                  
                  }
                                   
                  ShortPositionLevel += PositionGetDouble(POSITION_PRICE_OPEN);
                  Total_volume -= PositionGetDouble(POSITION_VOLUME);
                  Total_Short_Volume += PositionGetDouble(POSITION_VOLUME);
               }
            }
         }
                                              
      }
      if(TotalNumOfLongs >= 2)
      currentLongAvg = LongPositionLevel/TotalNumOfLongs;
      else
      currentLongAvg = 0;
      
      if(TotalNumOfShorts >= 2)
      currentShortAvg = ShortPositionLevel/TotalNumOfShorts;
      else
      currentShortAvg = 0;
      
      if (symbolProfit < MaxDD)
      MaxDD = symbolProfit;
      
      if(symbolLongProfit < MaxLongDD)
      MaxLongDD = symbolLongProfit;
      
      if(symbolShortProfit < MaxShortDD)
      MaxShortDD = symbolShortProfit;
      
      if(symbolProfit > MaxProfit)
      MaxProfit = symbolProfit;
            
      // Hedge Wizard Conditions
      if (MathAbs(MaxDD) > StartHedgingAtDollarAmount && EnableHedgeWizard == true)
      {
         if(Total_Long_Volume > Total_Short_Volume && HedgeTrigger == false)
         {
         HedgeTrigger = true;
         HedgeAgainstLongs = true;
         CloseAllTrades("SHORT");
         RestrictLongs = true;
         }
         
         if(Total_Long_Volume < Total_Short_Volume && HedgeTrigger == false)
         {
         HedgeTrigger = true;
         HedgeAgainstShorts = true;
         CloseAllTrades("LONG");
         RestrictShorts = true;
         }
      }
 }
 
 void CloseAllTrades()
 {
   RestrictTrading = true;
   numofOrders = PositionsTotal();
      if (numofOrders != 0)
      {
      for (int i = 0; i < numofOrders; i++)
      {
         for (int pos = 0; pos < numofOrders; pos++)
         {
            if (PositionSelectByTicket(PositionGetTicket(pos)) == true)
            {
               // if longs are open
               if ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == Symbol())
               {
                  // Close long market order
                  long currentTicket = PositionGetInteger(POSITION_TICKET);
                  if(tradeOperation.PositionClose(currentTicket,0)== true)
                  printf("Market long order closed");
                  
               }
               // if shorts are open
               if ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == Symbol())
               {
                  // Close short market order
                  long currentTicket = PositionGetInteger(POSITION_TICKET);
                  if(tradeOperation.PositionClose(currentTicket,0)== true)
                  printf("Market short order closed");
               }
            }
         }
        }                                      
      }
 }
 
  void CloseAllTrades(string direction)
 {
 
   if(direction == "LONG")
   RestrictLongs = true;
   if(direction == "SHORT")
   RestrictShorts = true;
   
   numofOrders = PositionsTotal();
      if (numofOrders != 0)
      {
      for (int i = 0; i < numofOrders; i++)
      {
         for (int pos = 0; pos < numofOrders; pos++)
         {
            if (PositionSelectByTicket(PositionGetTicket(pos)) == true)
            {
               // if longs are open
               if ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && direction == "LONG" && PositionGetString(POSITION_SYMBOL) == Symbol())
               {
                  // Close long market order
                  long currentTicket = PositionGetInteger(POSITION_TICKET);
                  if(tradeOperation.PositionClose(currentTicket,0)== true)
                  printf("Market long order closed");
                  
               }
               // if shorts are open
               if ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && direction == "SHORT" && PositionGetString(POSITION_SYMBOL) == Symbol())
               {
                  // Close short market order
                  long currentTicket = PositionGetInteger(POSITION_TICKET);
                  if(tradeOperation.PositionClose(currentTicket,0)== true)
                  printf("Market short order closed");
               }
            }
          }
        }                                      
      }
 }
 
 double OpenLongPosition(double volume)
 {
   volume = NormalizeDouble(volume,2);
   SymbolInfoTick(_Symbol,last_tick);
   if(volume > MAXLOT){
   volume = MAXLOT;
   }
   Print("Open Trade With Volume: " + DoubleToString(volume));
   
   if(disableLongs == false && disableTrading == false && RestrictLongs == false)
   {
   numofOrders = PositionsTotal();
   
   if(UseStopLoss == true)
   currentLongStopLoss = last_tick.ask - SL;
   else
   currentLongStopLoss = 0;
   
   if(UseTakeProfit == true && TotalNumOfLongs < 2)
   currentLongTakeProfit = last_tick.ask + TP;
   
   if(UseTakeProfit == true && TotalNumOfLongs >= 2)
   currentLongTakeProfit = currentLongAvg + TP;
   
   if (HedgeAgainstShorts == true)
   currentLongTakeProfit = 0;
   
   //Initialize Long Trigger Levels if no longs are open
   if (TotalNumOfLongs == 0)
   {
      for(int i = 0; i < MaxNumberOfTrades; i++)
      {
         if(i == 0 && HedgeAgainstShorts == false)
         {
         LongTriggerLevels[i] = last_tick.ask - StepSizeInPips;
         Print("Level ", i, ": ", LongTriggerLevels[i], "(Buy Level) Created!");
         
         // Create Short trigger level if Trend mode is enabled with uptrend
         if(EnableTrendMode == true && TrendType == Uptrend)
         ShortTriggerLevels[i] = last_tick.bid + StepSizeInPips;
         
         bool send = tradeOperation.Buy(volume,Symbol(),last_tick.ask,currentLongStopLoss,currentLongTakeProfit,NULL);
         LongsActive = true;
         }
         
         else if(i != 0 && HedgeAgainstShorts == false)
         {
         LongTriggerLevels[i] = LongTriggerLevels[i-1] - StepSizeInPips;
         Print("Level ", i, ": ", LongTriggerLevels[i], "(Buy Level) Created!");
         
         // Create Short trigger level if Trend mode is enabled with uptrend
         if(EnableTrendMode == true && TrendType == Uptrend)
         ShortTriggerLevels[i] = ShortTriggerLevels[i-1] + StepSizeInPips;
         }
         
         if(i == 0 && HedgeAgainstShorts == true)
         {
         LongTriggerLevels[i] = last_tick.ask - StepSizeInPips/HedgeDivisor;
         Print("Hedge Level ", i, ": ", LongTriggerLevels[i], "(Buy Level) Created!");
         bool send = tradeOperation.Buy(volume,Symbol(),last_tick.ask,currentLongStopLoss,currentLongTakeProfit,NULL);
         LongsActive = true;
         }
         
         else if(i != 0 && HedgeAgainstShorts == true)
         {
         LongTriggerLevels[i] = LongTriggerLevels[i-1] - (StepSizeInPips/HedgeDivisor);
         Print("Hedge Level ", i, ": ", LongTriggerLevels[i], "(Buy Level) Created!");       
         }
         
      }
   }
   if (TotalNumOfLongs != 0)
   bool send = tradeOperation.Buy(volume,Symbol(),last_tick.ask,currentLongStopLoss,currentLongTakeProfit,NULL);
   
   
   }
   return last_tick.ask;
   //Sleep(65000);
 
 }
 
 double OpenShortPosition(double volume)
 {
   volume = NormalizeDouble(volume,2);
   SymbolInfoTick(_Symbol,last_tick);
   if(volume > MAXLOT){
   volume = MAXLOT;
   }
   
   Print("Open Trade With Volume: " + DoubleToString(volume));
   
   if(disableShorts == false && disableTrading == false && RestrictShorts == false)
   {
   numofOrders = PositionsTotal();
   
   if(UseStopLoss == true)
   currentShortStopLoss = last_tick.bid + SL;
   else
   currentShortStopLoss = 0;
   
   if(UseTakeProfit == true && TotalNumOfShorts < 2)
   currentShortTakeProfit = last_tick.bid - TP;
   
   if(UseTakeProfit == true && TotalNumOfShorts >= 2)
   currentShortTakeProfit = currentShortAvg - TP;
    
   if(HedgeAgainstLongs == true)
   currentShortTakeProfit = 0;
   
   //Initialize Short Trigger Levels if no shorts are open
   if (TotalNumOfShorts == 0)
   {
      Print("Number of shorts: ", TotalNumOfShorts);
      for(int i = 0; i < MaxNumberOfTrades; i++)
      {
         if(i == 0 && HedgeAgainstLongs == false)
         {
         ShortTriggerLevels[i] = last_tick.bid + StepSizeInPips;
         Print("Level ", i, ": ", ShortTriggerLevels[i], "(Sell Level) Created!");
         
         // Create Long trigger level if Trend mode is enabled with downtrend
         if(EnableTrendMode == true && TrendType == Downtrend)
         LongTriggerLevels[i] = last_tick.ask - StepSizeInPips; 
         
         bool send = tradeOperation.Sell(volume,Symbol(),last_tick.bid,currentShortStopLoss,currentShortTakeProfit,NULL);
         ShortsActive = true;
         }
         
         else if(i != 0 && HedgeAgainstLongs == false)
         {
         ShortTriggerLevels[i] = ShortTriggerLevels[i-1] + StepSizeInPips;
         Print("Level ", i, ": ", ShortTriggerLevels[i], "(Sell Level) Created!");
         
          // Create Long trigger level if Trend mode is enabled with downtrend
         if(EnableTrendMode == true && TrendType == Downtrend)
         LongTriggerLevels[i] = LongTriggerLevels[i-1] - StepSizeInPips;
         }
         
         if(i == 0 && HedgeAgainstLongs == true)
         {
         ShortTriggerLevels[i] = last_tick.bid + StepSizeInPips;
         Print("Hedge Level ", i, ": ", ShortTriggerLevels[i], "(Sell Level) Created!");
         bool send = tradeOperation.Sell(volume,Symbol(),last_tick.bid,currentShortStopLoss,currentShortTakeProfit,NULL);
         ShortsActive = true;
         }
         
         else if(i != 0 && HedgeAgainstLongs == true)
         {
         ShortTriggerLevels[i] = ShortTriggerLevels[i-1] + (StepSizeInPips/HedgeDivisor);
         Print("Hedge Level ", i, ": ", ShortTriggerLevels[i], "(Sell Level) Created!");
         }
      }      
   }
   if (TotalNumOfShorts != 0)
   bool send = tradeOperation.Sell(volume,Symbol(),last_tick.bid,currentShortStopLoss,currentShortTakeProfit,NULL);
   
   }
   return last_tick.bid;
   //Sleep(65000);
   
 
 }
 
 void ResetLongLevelsData()
 {
   for(int i = 0; i < 100; i++)
   {
      LongTriggerLevelsBooleans[i] = false;
      LongTriggerLevels[i] = 0;
   
   }
 
 }
 
 void ResetShortLevelsData()
 {
   for(int i = 0; i < 100; i++)
   {
      ShortTriggerLevelsBooleans[i] = false;
      ShortTriggerLevels[i] = 0;
   
   }
 
 }
 
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == "CloseAll")
      CloseAllTrades();
      
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == "CloseLongs")
      CloseAllTrades("LONG");
      
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == "CloseShorts")
      CloseAllTrades("SHORT");
      
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == "DisableLongs")
      {
         
         if(disableLongs == false && currentSecond != SecondsMQL4()){
         currentSecond = SecondsMQL4();
         Print("Longs Disabled");
         disableLongs = true;}
         
         if(disableLongs == true && currentSecond != SecondsMQL4()){
         currentSecond = SecondsMQL4();
         Print("Longs Enabled");
         disableLongs = false;}
      
      }
      
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == "DisableShorts")
      {
         
         if(disableShorts == false && currentSecond != SecondsMQL4()){
         currentSecond = SecondsMQL4();
         Print("Shorts Disabled");
         disableShorts = true;}
         
         if(disableShorts == true && currentSecond != SecondsMQL4()){
         currentSecond = SecondsMQL4();
         Print("Shorts Disabled");
         disableShorts = false;}
      
      }
      
      if(id == CHARTEVENT_OBJECT_CLICK && sparam == "DisableTrading")
      {
         
         if(disableTrading == false && currentSecond != SecondsMQL4()){
         currentSecond = SecondsMQL4();
         Print("Trading Disabled");
         disableTrading = true;}
         
         if(disableTrading == true && currentSecond != SecondsMQL4()){
         currentSecond = SecondsMQL4();
         Print("Trading Disabled");
         disableTrading = false;}
      
      }
   
  }
//+------------------------------------------------------------------+
