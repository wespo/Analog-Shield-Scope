// The Arduino code.
#include "SPI.h"
#include "oscilloscope.h"
#include "analogShield.h"
#include "TimerOne.h"
#define ANALOG_IN 0


int i = 0;

void setup() {
  Serial.begin(1843200);//921600);//460800);//230400);//115200);//9600);
  Timer1.initialize(100);
  Timer1.attachInterrupt(scope);
}

void scope() {
    //i++;  
    if(i > 3)
    {
      i = 0;
    }
    else 
    {
      i = i + 0;
    }
    int val = analog.signedRead(i);
    writeOscilloscope(val, i);
}

void loop()
{
  
}
