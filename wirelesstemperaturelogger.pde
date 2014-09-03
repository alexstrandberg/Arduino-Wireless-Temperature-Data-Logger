// Libraries used
#include <VirtualWire.h>
#include <LiquidCrystal.h>
#include <math.h>
#include <stdlib.h>
#include <SD.h>
#include <Time.h>
#include <TimerThree.h>

// Used to write symbols to the LCD more easily
#define NO_SYMBOL -1
#define DEGREE_SYMBOL 0
#define RIGHT_ARROW_SYMBOL 1
#define UP_ARROW_SYMBOL 2
#define DOWN_ARROW_SYMBOL 3

// Custom symbols for the LCD
byte degree[8] = {B110,B1001,B1001,B110,B0,B0,B0,};
byte rightArrow[8] = {B0,B1000,B1100,B1110,B1100,B1000,B0};
byte upArrow[8] = {B0,B0,B100,B1110,B11111,B0,B0,};
byte downArrow[8] = {B0,B0,B11111,B1110,B100,B0,B0,};

#define HELPTEXTSIZE 29

// Text for instructions menu
String helpText[HELPTEXTSIZE] = {
  "UP and DOWN: to",
  "scroll, RT:Exit",
  "ON MAIN SCREEN:",
  "LFT:Disp. temp",
  "RT:Logging*SD",
  "UP:Logging*PC",
  "DWN:Log*Both",
  "WHEN DISP. TEMP",
  "HOLD + RELEASE:",
  "SEL:Change Unit",
  "LFT:ToggleLight",
  "RST:Change Mode",
  "WHEN LOGGING:",
  "HOLD + RELEASE:",
  "SEL:Change Unit",
  "LFT:ToggleLight",
  "UP:*LOG RATE",
  "DWN:*LOG RATE",
  "RT:Log ON/OFF",
  "RST:Change Mode",
  "Use transmitter",
  "w/ sensor or",
  "connect sensor",
  "to receiver",
  "Use arrow keys",
  "to enter data,",
  "press RIGHT",
  "when done",
};

// Whether or not symbols are used line by line for the help section
int helpTextSpecialChars[HELPTEXTSIZE] = {
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  RIGHT_ARROW_SYMBOL,
  RIGHT_ARROW_SYMBOL,
  RIGHT_ARROW_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  UP_ARROW_SYMBOL,
  DOWN_ARROW_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
  NO_SYMBOL,
};
int helpPos = 0;


// Which mode is the logger in?
#define NOTSET 0
#define DISPTEMP 1
#define LOGSD 2
#define LOGPC 3
#define LOGBOTH 4

int mode = NOTSET;
boolean setupDone = false;

String temp = "";
String fTemp = "";
boolean checkingCelsius = true;

LiquidCrystal lcd(8, 9, 4, 5, 6, 7);
int backLight = 10;

const int chipSelect = 53;


#define FAHRENHEIT 0
#define CELSIUS 1
#define BOTHUNITS 2
#define BOTHUNITS2 3
int unit = FAHRENHEIT;

unsigned long receiveFail = 0;

unsigned long analogReadDelay = 0;

// Log interval
#define LOG1SEC 0
#define LOG5SEC 1
#define LOG10SEC 2
#define LOG30SEC 3
#define LOG1MIN 4
#define LOG10MIN 5
#define LOG30MIN 6
#define LOG1HOUR 7
int logInterval = -1;

// Log time in millisecond form
#define TIME1SEC 1000
#define TIME5SEC 5000
#define TIME10SEC 10000
#define TIME30SEC 30000
#define TIME1MIN 60000
#define TIME10MIN 600000
#define TIME30MIN 1800000
#define TIME1HOUR 3600000
unsigned long logWait = TIME1SEC;
unsigned long lastLogged = 0;

boolean logOn = false;

boolean sdInserted = false;

boolean timeIsSet = false;

int backLightLevel = 255;

// define some values used by the panel and buttons
int lcd_key     = 0;
int adc_key_in  = 0;
#define btnRIGHT  0
#define btnUP     1
#define btnDOWN   2
#define btnLEFT   3
#define btnSELECT 4
#define btnNONE   5

// read the buttons
int read_LCD_buttons()
{
 adc_key_in = analogRead(0);      // read the value from the sensor 
 // my buttons when read are centered at these valies: 0, 144, 329, 504, 741
 // we add approx 50 to those values and check to see if we are close
 if (adc_key_in > 1000) return btnNONE; // We make this the 1st option for speed reasons since it will be the most likely result
 if (adc_key_in < 50)   return btnRIGHT;  
 if (adc_key_in < 195)  return btnUP; 
 if (adc_key_in < 380)  return btnDOWN; 
 if (adc_key_in < 555)  return btnLEFT; 
 if (adc_key_in < 790)  return btnSELECT;   
 return btnNONE;  // when all others fail, return this...
}

void waitUntilNoButtonPressed() {
  while (read_LCD_buttons()!=btnNONE);
}

//Rounds down (via intermediary integer conversion truncation)
String doubleToString(double input,int decimalPlaces){
  if(decimalPlaces!=0){
    String string = String((int)(input*pow(10,decimalPlaces)));
    if(abs(input)<1){
      if(input>0)
        string = "0"+string;
      else if(input<0)
        string = string.substring(0,1)+"0"+string.substring(1);
    }
    return string.substring(0,string.length()-decimalPlaces)+"."+string.substring(string.length()-decimalPlaces);
  }
  else {
    return String((int)input);
  }
}

double Thermistor(int RawADC) {
  double Temp;
  // See http://en.wikipedia.org/wiki/Thermistor for explanation of formula
  Temp = log(((10240000/RawADC) - 10000));
  Temp = 1 / (0.001129148 + (0.000234125 * Temp) + (0.0000000876741 * Temp * Temp * Temp));
  Temp = Temp - 273.15;           // Convert Kelvin to Celcius
  return Temp;
}

void printTemp(void) {
  double fT;
  double t = Thermistor(analogRead(15));  // Read sensor
  fT = (t * 1.8) + 32.0;    // Convert to USA
  lcd.setCursor(0,1);
  if(unit==CELSIUS) {
    lcd.print(t);
    lcd.write(DEGREE_SYMBOL);
    lcd.print("C         ");
  }
  else if (unit==FAHRENHEIT) {
    lcd.print(fT);
    lcd.write(DEGREE_SYMBOL);
    lcd.print("F         ");
  }
  else if (unit==BOTHUNITS) {
    lcd.print(fT);  
    lcd.write(DEGREE_SYMBOL);
    lcd.print("F ");
    lcd.print(t);
    lcd.write(DEGREE_SYMBOL);
    lcd.print("C ");
  }
  else if (unit==BOTHUNITS2) {
    lcd.print(t);  
    lcd.write(DEGREE_SYMBOL);
    lcd.print("C ");
    lcd.print(fT);
    lcd.write(DEGREE_SYMBOL);
    lcd.print("F ");
  }
  temp = doubleToString(t,2);
  fTemp = doubleToString(fT,2);
}

// Checks if any buttons are pressed and acts accordingly
void backgroundButtonPressCheck() {
  int button = btnNONE;
  if (read_LCD_buttons()!=btnNONE) button=read_LCD_buttons();
  if (button!=btnNONE) {
    if (button==btnSELECT&&millis()<(receiveFail+10000)&&mode!=NOTSET&&setupDone) {
      // Change units
      unit++;
      if(unit>BOTHUNITS2) unit = FAHRENHEIT;
      lcd.clear();
      waitUntilNoButtonPressed();
      if (sdInserted) {
        File dataFile = SD.open("settings.txt",FILE_WRITE);
        dataFile.seek(0);
        dataFile.print(unit);
        dataFile.close();
      }
      lcd.setCursor(0,0);
      if (mode==DISPTEMP) lcd.print("Temperature is:");
      else {
        lcd.print("Log");
        lcd.write(RIGHT_ARROW_SYMBOL);
        if (mode==LOGPC) lcd.print("PC: ");
        else if (mode==LOGSD) lcd.print("SD: ");
        else if (mode==LOGBOTH) lcd.print("Both: ");
        if (logOn) {
          if (logInterval==LOG1SEC) lcd.print("1 sec");
          else if (logInterval==LOG5SEC) lcd.print("5 sec");
          else if (logInterval==LOG10SEC) lcd.print("10 sec");
          else if (logInterval==LOG30SEC) lcd.print("30 sec");
          else if (logInterval==LOG1MIN) lcd.print("1 min");
          else if (logInterval==LOG10MIN) lcd.print("10 min");
          else if (logInterval==LOG30MIN) lcd.print("30 min");
          else if (logInterval==LOG1HOUR) lcd.print("1 hr");
        }
        else {
          if (mode==LOGBOTH) lcd.setCursor(9,0);
          lcd.print("STOPPED");
        }
      }
    }
    else if (button==btnRIGHT&&mode!=NOTSET&&mode!=DISPTEMP&&millis()<(receiveFail+10000)&&setupDone) {
      // Stop/Start logging
      lcd.clear();
      waitUntilNoButtonPressed();
      lcd.print("Log");
      lcd.write(RIGHT_ARROW_SYMBOL);
      if (mode==LOGPC) lcd.print("PC: ");
      else if (mode==LOGSD) lcd.print("SD: ");
      else if (mode==LOGBOTH) lcd.print("Both: ");
      if (logOn==false) {
        if (logInterval==LOG1SEC) lcd.print("1 sec");
        else if (logInterval==LOG5SEC) lcd.print("5 sec");
        else if (logInterval==LOG10SEC) lcd.print("10 sec");
        else if (logInterval==LOG30SEC) lcd.print("30 sec");
        else if (logInterval==LOG1MIN) lcd.print("1 min");
        else if (logInterval==LOG10MIN) lcd.print("10 min");
        else if (logInterval==LOG30MIN) lcd.print("30 min");
        else if (logInterval==LOG1HOUR) lcd.print("1 hr");
        logOn=true;
        lastLogged = millis();
      }
      else {
        if (mode==LOGBOTH) lcd.setCursor(9,0);
        lcd.print("STOPPED");
        logOn=false;
      }
    }
    else if (button!=btnSELECT&&button!=btnLEFT&&button!=btnRIGHT&&mode!=NOTSET&&mode!=DISPTEMP&&millis()<(receiveFail+10000)&&logOn) {
      // Increase/Decrease Log Rate
      int button = read_LCD_buttons();
      if (button==btnUP) if (logInterval!=LOG1HOUR) logInterval++;
      if (button==btnDOWN) if (logInterval!=LOG1SEC) logInterval--;
      if (logInterval==LOG1SEC) logWait = TIME1SEC;
      else if (logInterval==LOG5SEC) logWait = TIME5SEC;
      else if (logInterval==LOG10SEC) logWait = TIME10SEC;
      else if (logInterval==LOG30SEC) logWait = TIME30SEC;
      else if (logInterval==LOG1MIN) logWait = TIME1MIN;
      else if (logInterval==LOG10MIN) logWait = TIME10MIN;
      else if (logInterval==LOG30MIN) logWait = TIME30MIN;
      else if (logInterval==LOG1HOUR) logWait = TIME1HOUR;
      if (sdInserted) {
         File settingsFile = SD.open("settings.txt",FILE_WRITE);
         // if the file is available, read it:
         if (settingsFile) { 
           settingsFile.seek(1);
           settingsFile.print(logInterval);
           settingsFile.close();
         }
      }
      lcd.clear();
      waitUntilNoButtonPressed();
      lcd.print("Log");
      lcd.write(RIGHT_ARROW_SYMBOL);
      if (mode==LOGPC) lcd.print("PC: ");
      else if (mode==LOGSD) lcd.print("SD: ");
      else if (mode==LOGBOTH) lcd.print("Both: ");
      if (logInterval==LOG1SEC) lcd.print("1 sec");
      else if (logInterval==LOG5SEC) lcd.print("5 sec");
      else if (logInterval==LOG10SEC) lcd.print("10 sec");
      else if (logInterval==LOG30SEC) lcd.print("30 sec");
      else if (logInterval==LOG1MIN) lcd.print("1 min");
      else if (logInterval==LOG10MIN) lcd.print("10 min");
      else if (logInterval==LOG30MIN) lcd.print("30 min");
      else if (logInterval==LOG1HOUR) lcd.print("1 hr");
      lastLogged=millis();
    }
    else if (button==btnLEFT&&mode!=NOTSET&&setupDone) {
      // Backlight control
      backLightLevel-=51;
      if (backLightLevel<0) backLightLevel=255;
      analogWrite(backLight,backLightLevel);
      waitUntilNoButtonPressed();
    }
  }
}

void setup()
{
  Serial.begin(9600);
  pinMode(13,OUTPUT);
  pinMode(backLight, OUTPUT);
  analogWrite(backLight, backLightLevel); // turn backlight on. Replace 'HIGH' with 'LOW' to turn it off.
  
  lcd.begin(16, 2);              // rows, columns.  use 16,2 for a 16x2 LCD, etc.
  lcd.clear();                   // start with a blank screen
  lcd.setCursor(0,0);            // set cursor to column 0, row 0
  
  lcd.createChar(DEGREE_SYMBOL, degree);
  lcd.createChar(RIGHT_ARROW_SYMBOL, rightArrow);
  lcd.createChar(UP_ARROW_SYMBOL, upArrow);
  lcd.createChar(DOWN_ARROW_SYMBOL, downArrow);
  
  lcd.setCursor(0,0);
  lcd.print("Wireless Temp.");
  lcd.setCursor(0,1);
  lcd.print("Logger");

  // Initialise the IO and ISR
  vw_set_ptt_inverted(true);  // Required for RX Link Module
  vw_setup(1200);             // Bits per sec
  vw_set_rx_pin(30);          // We will be receiving on pin 3 () ie the RX pin from the module connects to this pin.
  vw_set_tx_pin(31);
  vw_rx_start();              // Start the receiver
  
  Timer3.initialize(200000);
  Timer3.attachInterrupt(backgroundButtonPressCheck);
  
  delay(1000);
}

void loop()
{
  if(mode==NOTSET) {
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("SEL:Instructions");
    lcd.setCursor(0,1);
    lcd.print("or choose mode");
    int button = btnNONE;
    while (button==btnNONE) {
      button=read_LCD_buttons();
    }
    if (button==btnSELECT) {
      // Prints help text according to position in array of text
      waitUntilNoButtonPressed();
      while (helpPos!=-1) {
        lcd.clear();
        lcd.setCursor(0,0);
        if(helpTextSpecialChars[helpPos]==-1) {
          lcd.print(helpText[helpPos]);
        } else {
          lcd.print(helpText[helpPos].substring(0,helpText[helpPos].indexOf("*")));
          lcd.write(helpTextSpecialChars[helpPos]);
          lcd.print(helpText[helpPos].substring(helpText[helpPos].indexOf("*")+1));
        }
        lcd.setCursor(15,0);
        lcd.write(UP_ARROW_SYMBOL);
        lcd.setCursor(0,1);
        if(helpTextSpecialChars[helpPos+1]==-1) {
          lcd.print(helpText[helpPos+1]);    
        } else {
          lcd.print(helpText[helpPos+1].substring(0,helpText[helpPos+1].indexOf("*")));
          lcd.write(helpTextSpecialChars[helpPos+1]);
          lcd.print(helpText[helpPos+1].substring(helpText[helpPos+1].indexOf("*")+1));
        }
        lcd.setCursor(15,1);
        lcd.write(DOWN_ARROW_SYMBOL);
        
        button=btnNONE;
        while(button!=btnUP&&button!=btnDOWN&&button!=btnRIGHT) {
          button=read_LCD_buttons();
        }
        if(button==btnUP&&helpPos!=0) {
          helpPos-=2;
          lcd.setCursor(15,0);
          lcd.print(" ");
        }
        else if (button==btnDOWN&&helpPos<HELPTEXTSIZE-3) {
          helpPos+=2;
          lcd.setCursor(15,1);
          lcd.print(" ");
        }
        else if (button==btnRIGHT) helpPos=-1;
        waitUntilNoButtonPressed();
      }
      helpPos=0;
    }
    else if (button==btnLEFT||button==btnUP||button==btnDOWN||button==btnRIGHT) {
      // Reads settings on SD card
      waitUntilNoButtonPressed();
      if (button==btnLEFT) mode=DISPTEMP;
      else if (button==btnUP) mode=LOGPC;
      else if (button==btnDOWN) mode=LOGBOTH;
      else if (button==btnRIGHT) mode=LOGSD;
      
      if (mode==DISPTEMP||mode==LOGPC) {
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("Reading settings");
        if (mode==LOGPC) delay(500);
      }
      
      if (mode==LOGBOTH||mode==LOGSD) {
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("Insert SD card");
        while (!SD.begin(chipSelect)) {
          delay(5000);
        }
        sdInserted = true;
      } else {
        if (SD.begin(chipSelect)) sdInserted = true;
      }
      
      if (mode!=DISPTEMP&&mode!=LOGPC) {
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("Reading settings");
        delay(500);
      }
      
      if (sdInserted) {
        File settingsFile = SD.open("settings.txt");
        // if the file is available, read it:
        if (settingsFile) {
          unit = settingsFile.read()- '0';
          logInterval = settingsFile.read()-'0';
          if (mode!=DISPTEMP) {
            lcd.setCursor(0,1);    
            lcd.print("Every ");
            if (logInterval==LOG1SEC) lcd.print("1 second ");
            else if (logInterval==LOG5SEC) lcd.print("5 seconds ");
            else if (logInterval==LOG10SEC) lcd.print("10 seconds ");
            else if (logInterval==LOG30SEC) lcd.print("30 seconds ");
            else if (logInterval==LOG1MIN) lcd.print("1 minute ");
            else if (logInterval==LOG10MIN) lcd.print("10 minutes ");
            else if (logInterval==LOG30MIN) lcd.print("30 minutes ");
            else if (logInterval==LOG1HOUR) lcd.print("1 hour ");
            if (logInterval==LOG1SEC) logWait = TIME1SEC;
            else if (logInterval==LOG5SEC) logWait = TIME5SEC;
            else if (logInterval==LOG10SEC) logWait = TIME10SEC;
            else if (logInterval==LOG30SEC) logWait = TIME30SEC;
            else if (logInterval==LOG1MIN) logWait = TIME1MIN;
            else if (logInterval==LOG10MIN) logWait = TIME10MIN;
            else if (logInterval==LOG30MIN) logWait = TIME30MIN;
            else if (logInterval==LOG1HOUR) logWait = TIME1HOUR;
            delay(2000);
          }
          settingsFile.close();
        }  
        else {
          settingsFile.close();
          File newSettingsFile = SD.open("settings.txt",FILE_WRITE);
          newSettingsFile.print(FAHRENHEIT);
          newSettingsFile.print(LOG1SEC);
          newSettingsFile.close();
          delay(500);
          lcd.setCursor(0,1);
          lcd.print("None on card");
          delay(2000);
        }
        
      } else {
        delay(500);
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("Failed, using");
        lcd.setCursor(0,1);
        lcd.print("default settings");
        delay(3000);
      }
      
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Turn on Transm./");
      lcd.setCursor(0,1);
      lcd.print("Insert sensor");
      
      uint8_t buf[VW_MAX_MESSAGE_LEN];
      uint8_t buflen = VW_MAX_MESSAGE_LEN;
      while (analogRead(15)<20&&!vw_get_message(buf, &buflen)) {
        delay(1000);
      }
      lcd.clear();
      lcd.setCursor(0,0);
      if (mode==DISPTEMP) {
        lcd.print("Temperature is:");
        setupDone = true;
      } else {
        if (sdInserted) {
          File logFile = SD.open("log.csv");
          if (!logFile) {
            File newLogFile = SD.open("log.csv",FILE_WRITE);
            newLogFile.println("Date/Time,Fahrenheit,Celsius");
            newLogFile.close();
          }
        }
        lcd.print("Set log interval");
        lcd.setCursor(0,1);
        
        int tempChoice = LOG1SEC;
        lcd.print("1 second ");
        lcd.write(UP_ARROW_SYMBOL);
        lcd.print("/");
        lcd.write(DOWN_ARROW_SYMBOL);
        
        while (logInterval==-1) {
          int button = read_LCD_buttons();
          if (button!=btnNONE) {
            if (button==btnUP) if (tempChoice!=LOG1HOUR) tempChoice++;
            if (button==btnDOWN) if (tempChoice!=LOG1SEC) tempChoice--;
            if (button==btnSELECT) {
              logInterval=tempChoice;
              if (logInterval==LOG1SEC) logWait = TIME1SEC;
              else if (logInterval==LOG5SEC) logWait = TIME5SEC;
              else if (logInterval==LOG10SEC) logWait = TIME10SEC;
              else if (logInterval==LOG30SEC) logWait = TIME30SEC;
              else if (logInterval==LOG1MIN) logWait = TIME1MIN;
              else if (logInterval==LOG10MIN) logWait = TIME10MIN;
              else if (logInterval==LOG30MIN) logWait = TIME30MIN;
              else if (logInterval==LOG1HOUR) logWait = TIME1HOUR;
              if (sdInserted) {
                File settingsFile = SD.open("settings.txt",FILE_WRITE);
                // if the file is available, read it:
                if (settingsFile) { 
                  settingsFile.seek(1);
                  settingsFile.print(logInterval);
                  settingsFile.close();
                }
              }
            }
            lcd.clear();
            lcd.setCursor(0,0);
            lcd.print("Set log interval");
            lcd.setCursor(0,1);
            if (tempChoice==LOG1SEC) lcd.print("1 second ");
            else if (tempChoice==LOG5SEC) lcd.print("5 seconds ");
            else if (tempChoice==LOG10SEC) lcd.print("10 seconds ");
            else if (tempChoice==LOG30SEC) lcd.print("30 seconds ");
            else if (tempChoice==LOG1MIN) lcd.print("1 minute ");
            else if (tempChoice==LOG10MIN) lcd.print("10 minutes ");
            else if (tempChoice==LOG30MIN) lcd.print("30 minutes ");
            else if (tempChoice==LOG1HOUR) lcd.print("1 hour ");
            lcd.write(UP_ARROW_SYMBOL);
            lcd.print("/");
            lcd.write(DOWN_ARROW_SYMBOL);
            
            waitUntilNoButtonPressed();
          }
        }
        if (mode==LOGBOTH||mode==LOGSD) {
          // Asks user to set date/time
          lcd.clear();
          lcd.setCursor(0,0);
          lcd.print("Set");
          lcd.setCursor(0,1);
          lcd.print("Date:");
          lcd.setCursor(7,0);
          lcd.print("1/1/00");
          lcd.setCursor(7,1);
          lcd.write(UP_ARROW_SYMBOL);
          
          int setPos = 0;
          int data[7] = {1,1,2000,12,00,0};
          while (!timeIsSet) {
            int button = read_LCD_buttons();
            if (button!=btnNONE) {
              if (button==btnUP) {
                if (setPos==0&&data[0]!=12) data[0]++;
                else if (setPos==1&&data[1]!=31) data[1]++;
                else if (setPos==2) data[2]++;
                else if (setPos==3) {
                  if (data[3]<11) {
                    data[3]++;
                  } else if (data[3]==12) data[3]=1;
                  else if (data[3]==11) {
                    data[5]++;
                    if (data[5]==2) data[5]=0;
                    data[3]=12;
                  }
                }
                else if (setPos==4) {
                  if (data[4]<59) data[4]++;
                  else data[4]=0;
                }
              }
              else if (button==btnDOWN) {
                
                if (setPos==0&&data[0]!=1) data[0]--;
                else if (setPos==1&&data[1]!=1) data[1]--;
                else if (setPos==2&&data[2]!=2000) data[2]--;
                else if (setPos==3) {
                  if (data[3]>1&&data[3]!=12) {
                    data[3]--;
                  } else if (data[3]==1) data[3]=12;
                  else if (data[3]==12) {
                    data[5]--;
                    if (data[5]==-1) data[5]=1;
                    data[3]=11;
                  }
                }
                else if (setPos==4) {
                  if (data[4]>0) data[4]--;
                  else data[4]=59;
                }
              }
              else if (button==btnRIGHT&&setPos!=4) setPos++;
              else if (button==btnRIGHT&&setPos==4) {
                timeIsSet=true;
                if (data[5]==1) data[3]+=12;
                setTime(data[3],data[4],0,data[1],data[0],data[2]);
              }
              else if (button==btnLEFT&&setPos!=0) setPos--;
            }
              delay(300);
              
              if (setPos<3) {
                lcd.clear();
                lcd.setCursor(0,0);
                lcd.print("Set");
                lcd.setCursor(0,1);
                lcd.print("Date:");
                lcd.setCursor(7,0);
                lcd.print(data[0]);
                lcd.print("/");
                lcd.print(data[1]);
                lcd.print("/");
                lcd.print(String(data[2]).substring(2,4));
              } else {
                lcd.clear();
                lcd.setCursor(0,0);
                lcd.print("Set");
                lcd.setCursor(0,1);
                lcd.print("Time:");
                lcd.setCursor(7,0);
                lcd.print(data[3]);
                lcd.print(":");
                if (data[4]<10) lcd.print("0");
                lcd.print(data[4]);
                if (data[5]==0) lcd.print(" AM");
                else lcd.print(" PM");
              }
              
              if (setPos==0) {
                lcd.setCursor(7,1);
                lcd.write(UP_ARROW_SYMBOL);
                if (data[0]>9) lcd.write(UP_ARROW_SYMBOL);
              } else if (setPos==1) {
                lcd.setCursor(9,1);
                if (data[0]>9) lcd.print(" ");
                lcd.write(UP_ARROW_SYMBOL);
                if (data[1]>9) lcd.write(UP_ARROW_SYMBOL);
              } else if (setPos==2) {
                lcd.setCursor(11,1);
                if (data[0]>9) lcd.print(" ");
                if (data[1]>9) lcd.print(" ");
                lcd.write(UP_ARROW_SYMBOL);
                lcd.write(UP_ARROW_SYMBOL);
              } else if (setPos==3) {
                lcd.setCursor(7,1);
                lcd.write(UP_ARROW_SYMBOL);
                if (data[3]>9) lcd.write(UP_ARROW_SYMBOL);
                lcd.print("    --");
              } else if (setPos==4) {
                lcd.setCursor(9,1);
                if (data[3]>9) lcd.print(" ");
                lcd.write(UP_ARROW_SYMBOL);
                lcd.write(UP_ARROW_SYMBOL);
              } 
          }
        }
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("Log");
        lcd.write(RIGHT_ARROW_SYMBOL);
        if (mode==LOGPC) lcd.print("PC: ");
        else if (mode==LOGBOTH) lcd.print("Both:");
        else if (mode==LOGSD) lcd.print("SD: ");
        lcd.print("STOPPED");
        setupDone=true;
      }
    }
  } else {  
    uint8_t buf[VW_MAX_MESSAGE_LEN];
    uint8_t buflen = VW_MAX_MESSAGE_LEN;   
    if (vw_get_message(buf, &buflen)) // check to see if anything has been received
    {
      if (backLightLevel>0) digitalWrite(13,HIGH);
      if (millis()>(receiveFail+10000)) { 
        lcd.clear();
        lcd.setCursor(0,0);
        if (mode==DISPTEMP) lcd.print("Temperature is:");
        else {
          lcd.print("Log");
          lcd.write(RIGHT_ARROW_SYMBOL);
          if (mode==LOGPC)lcd.print("PC: ");
          else if (mode==LOGBOTH) lcd.print("Both: ");
          else if (mode==LOGSD) lcd.print("SD: ");
          if (logOn) {
            if (logInterval==LOG1SEC) lcd.print("1 sec");
            else if (logInterval==LOG5SEC) lcd.print("5 sec");
            else if (logInterval==LOG10SEC) lcd.print("10 sec");
            else if (logInterval==LOG30SEC) lcd.print("30 sec");
            else if (logInterval==LOG1MIN) lcd.print("1 min");
            else if (logInterval==LOG10MIN) lcd.print("10 min");
            else if (logInterval==LOG30MIN) lcd.print("30 min");
            else if (logInterval==LOG1HOUR) lcd.print("1 hr");
          }
          else {
            if (mode==LOGBOTH) lcd.setCursor(9,0);
            lcd.print("STOPPED");
          }
        }
      }
      receiveFail=0;
      int i;
       // Message with a good checksum received.
      temp="";  
      fTemp="";
      for (i = 0; i < buflen; i++)
      {  
        if (checkingCelsius) {
          if (buf[i]!='C') temp+=buf[i];  // the received data is stored in buffer
          else checkingCelsius=false;
        }
        else {
          if (buf[i]!='F') fTemp+=buf[i];
          else checkingCelsius=true;
        } 
      }
      
      lcd.setCursor(0,1);
      if(unit==CELSIUS) {
        lcd.print(temp);
        lcd.write(DEGREE_SYMBOL);
        lcd.print("C         ");
      }
      else if (unit==FAHRENHEIT) {
        lcd.print(fTemp);
        lcd.write(DEGREE_SYMBOL);
        lcd.print("F         ");
      }
      else if (unit==BOTHUNITS) {
        lcd.print(fTemp);  
        lcd.write(DEGREE_SYMBOL);
        lcd.print("F ");
        lcd.print(temp);
        lcd.write(DEGREE_SYMBOL);
        lcd.print("C ");
      }
      else if (unit==BOTHUNITS2) {
        lcd.print(temp);
        lcd.write(DEGREE_SYMBOL);
        lcd.print("C ");
        lcd.print(fTemp);
        lcd.write(DEGREE_SYMBOL);
        lcd.print("F ");
      }
      digitalWrite(13,LOW);
    }
    else if (analogRead(15)>20) {
      delay(100);
      if (analogRead(15)>20&&millis()>(analogReadDelay+500)) {
        if (backLightLevel>0) digitalWrite(13,HIGH); 
        if (millis()>(receiveFail+10000)) {
          lcd.clear();
          lcd.setCursor(0,0);
          if (mode==DISPTEMP) lcd.print("Temperature is:");
          else {
            lcd.print("Log");
            lcd.write(RIGHT_ARROW_SYMBOL);
            if (mode==LOGPC)lcd.print("PC: ");
            else if (mode==LOGBOTH) lcd.print("Both: ");
            else if (mode==LOGSD) lcd.print("SD: ");
            if (logOn) {
              if (logInterval==LOG1SEC) lcd.print("1 sec");
              else if (logInterval==LOG5SEC) lcd.print("5 sec");
              else if (logInterval==LOG10SEC) lcd.print("10 sec");
              else if (logInterval==LOG30SEC) lcd.print("30 sec");
              else if (logInterval==LOG1MIN) lcd.print("1 min");
              else if (logInterval==LOG10MIN) lcd.print("10 min");
              else if (logInterval==LOG30MIN) lcd.print("30 min");
              else if (logInterval==LOG1HOUR) lcd.print("1 hr");
            }
            else {
              if (mode==LOGBOTH) lcd.setCursor(9,0);
              lcd.print("STOPPED");
            }
          }
        }
        receiveFail=millis();;
        analogReadDelay = millis();
        printTemp();
        digitalWrite(13,LOW);
      }
    }
    else {
      if (receiveFail==0) receiveFail=millis();
      if (millis()>(receiveFail+10000)) {
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("Turn on Transm./");
        lcd.setCursor(0,1);
        lcd.print("Insert sensor");
        delay(2000);
      }
    }
    
    unsigned long current = millis();
    if (current>(receiveFail+10000)&&((current-lastLogged)>=logWait)) {
      lastLogged=current;
    } else if ((current-lastLogged)>=logWait) {
      if (logOn) delay(100);
      if (logOn) {
        if (mode==LOGPC||mode==LOGBOTH) {
          // Logs to serial
          Serial.print(fTemp);
          Serial.print("F_");
          Serial.print(temp);
          Serial.println("C|");          
        }
        if (mode==LOGSD||mode==LOGBOTH) {
          // Logs to SD card
          File logFile = SD.open("log.csv",FILE_WRITE);
          if (logFile) {
            logFile.print(month());
            logFile.print("/");
            logFile.print(day());
            logFile.print("/");
            logFile.print(String(year()).substring(2,4));
            logFile.print(" ");
            logFile.print(hourFormat12());
            logFile.print(":");
            if (minute()<10) logFile.print("0");
            logFile.print(minute());
            logFile.print(":");
            if (second()<10) logFile.print("0");
            logFile.print(second()); 
            if (isAM()&&hourFormat12()!=12) logFile.print("AM");
            else if (isAM()&&hourFormat12()==12) logFile.print("PM");
            else if (isPM()&&hourFormat12()==12) logFile.print("AM");
            else logFile.print("PM");
            logFile.print(",");
            logFile.print(fTemp);
            logFile.print(",");
            logFile.println(temp);
          }
          logFile.close();
        }
        lastLogged=current;
        delay(100);
      }
    }
  } 
}
