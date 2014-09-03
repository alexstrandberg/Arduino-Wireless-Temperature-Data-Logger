#include <VirtualWire.h>  // you must download and install the VirtualWire.h to your hardware/libraries folder
#include <math.h>

#undef int
#undef abs
#undef double
#undef float
#undef round

String textToSend = "";

void setup() {
  pinMode(13,OUTPUT);
  // Initialise the IO and ISR
  vw_set_ptt_inverted(true);        // Required for RF Link module
  vw_setup(1200);                   // Bits per sec
  vw_set_tx_pin(3);                // pin 3 is used as the transmit data out into the TX Link module, change this to suit your needs.
  pinMode(10,INPUT);
  pinMode(9,OUTPUT);
  pinMode(11,OUTPUT);
  digitalWrite(9,LOW);
  digitalWrite(11,HIGH);
}

double Thermistor(int RawADC) {
  double Temp;
  // See http://en.wikipedia.org/wiki/Thermistor for explanation of formula
  Temp = log(((10240000/RawADC) - 10000));
  Temp = 1 / (0.001129148 + (0.000234125 * Temp) + (0.0000000876741 * Temp * Temp * Temp));
  Temp = Temp - 273.15;           // Convert Kelvin to Celcius
  return Temp;
}

void printTemp() {
  double fTemp;
  double temp = Thermistor(analogRead(0));  // Read sensor
  textToSend=doubleToString(temp,2);
  textToSend+="C";
  fTemp = (temp * 1.8) + 32.0;    // Convert to USA
  textToSend+=doubleToString(fTemp,2);
  textToSend+="F";
}

//Rounds down (via intermediary integer conversion truncation)
String doubleToString(double input,int decimalPlaces){
  if(decimalPlaces!=0) {
    String string = String((int)(input*pow(10,decimalPlaces)));
    if(abs(input)<1) {
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

void loop() {
  while (analogRead(0)!=0) {
    if (digitalRead(10)==HIGH) digitalWrite(13,HIGH);
    printTemp();
    char temp[50];
    textToSend.toCharArray(temp,50);
    const char *msg = temp;       // this is your message to send
    vw_send((uint8_t *)msg, strlen(msg));
    vw_wait_tx();                                     // Wait for message to finish
    digitalWrite(13,LOW);
    delay(500);
  }
}
