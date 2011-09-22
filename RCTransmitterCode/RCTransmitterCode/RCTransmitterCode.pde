/*
code to take input from pots stolen from an old RC transmitter, and will send angle values through xbee to the boat.
 June 2011
 
 Valerie and Laszlo  
 
 Rudder sends values from 120 to 180 (centered at 150), sails sends value from 225 to 275 (centered at 250). 
 This is so that all values sent are 3 characters, and not negative.
 This is taken into account in super xbee RC mode in the actual menu code.
 
 */

#define SAILSPIN A0 //the one without the spring is to be used for sails since the exact middle value is much less relevant
#define RUDDERPIN A1 //the one with the spring, to be used for rudder
#define PANICPIN  7
#define LEDPIN    13

void setup()
{
  pinMode(SAILSPIN, INPUT);
  pinMode(RUDDERPIN, INPUT);
  pinMode(PANICPIN, INPUT);
  pinMode(LEDPIN, OUTPUT);
  pinMode(6,OUTPUT); // use as a 5 volt to power panic button
  digitalWrite(6,HIGH); // set power high
  Serial.begin(19200);

}

void loop()
{  
  int rudderval;
  int sailsval;
  int normalizedrudder;
  int normalizedsails;
  char signalchar;      //char to signal data spam
  static boolean RCTime = false;


  digitalWrite(LEDPIN, !digitalRead(PANICPIN)); // have led represent whether panic button is being pressed
  if(digitalRead(PANICPIN) == LOW) //if panic button is being pressed
  {
    delay(30);//eliminate debouncing
      Serial.println("rrrr"); 
    
  }


  signalchar = Serial.read();
  if(signalchar == '~'){
    RCTime = true;
    Serial.println("Entering RC mode");
  }
  if(signalchar == '|'){
    RCTime = false;
    Serial.println("Exiting RC mode");
  }

  if (RCTime == true){

    sailsval = analogRead(SAILSPIN);
    normalizedsails = analogToSails(sailsval);  
    rudderval = analogRead(RUDDERPIN);
    normalizedrudder = analogToRudder(rudderval);  
    Serial.println(normalizedsails);
    Serial.print(normalizedrudder);  
    delay(100);

  }
}
//translates analog to digital scale from 0-1023 to a -25 to 25 degree angle that should be fed to the rudder
//analog values vary from min 310 to max 720, with 0 at 512, so subtraction 512 should give us a value from 
//-100 to 100 (but will not ever likely reach 100)
int analogToRudder(int analog)
{
  float temp;
  temp = analog - 512; //see comment
  temp = temp/133.0 * 30; //normalize to -25 to 25 to get a 50 degree range that will be changed to 0-100 at the other end  
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


