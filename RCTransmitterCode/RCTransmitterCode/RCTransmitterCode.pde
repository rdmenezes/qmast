/*
code to take input from pots stolen from an old RC transmitter, and will send angle values through xbee to the boat.
June 2011

Valerie and Laszlo  


Rudder sends values from 125 to 175 (centered at 150), sails sends value from 225 to 275 (centered at 250). This is so that all values sent are 3 characters, and not negative.
This is taken into account in super xbee RC mode in the actual menu code.

*/

#define POT1 A0 //the one without the spring is to be used for sails since the exact middle value is much less relevant
#define POT2 A1 //the one with the spring, to be used for rudder

void setup()
{
  pinMode(POT1, INPUT);
  Serial.begin(9600);
  
}

void loop()
{
  int pot1val;
  int pot2val;
  int normalized1;
  int normalized2;
  pot1val = analogRead(POT1);
  normalized1 = analogToSails(pot1val);
  
  pot2val = analogRead(POT2);
  normalized2 = analogToRudder(pot2val);
  
  //Serial.print("pot 1 val: ");
 // Serial.println(pot1val);
  //Serial.print("normalized Sails angle: ");
  //Serial.println(normalized1);
  
//  Serial.print("pot 2 val: ");
//  Serial.println(pot2val);
//  Serial.print("normalized rudder value: ");
//  Serial.println(normalized2);
//  Serial.println();
  
  Serial.println(normalized1);
  Serial.print(normalized2);
  
  delay(500);
}


//translates analog to digital scale from 0-1023 to a -25 to 25 degree angle that should be fed to the rudder
//analog values vary from min 310 to max 720, with 0 at 512, so subtraction 512 should give us a value from -100 to 100 (but will not ever likely reach 100)
int analogToRudder(int analog)
{
  float temp;
  temp = analog - 512; //see comment
  temp = temp/133.0 * 25; //normalize to -25 to 25 to get a 50 degree range that will be changed to 0-100 at the other end
  
  temp += 150; //scale for transmission
  
  return temp;  
}

//at the moment same as analogToRudder
int analogToSails(int analog)
{
  float temp;
  temp = analog - 512; //see comment
  temp = temp/133.0 * 25; //see rudder
  
  temp += 250;//scale for transmission
  
  return temp;  
  
}
