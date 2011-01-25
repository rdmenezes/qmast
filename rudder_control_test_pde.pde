//#include <math.h> doesnt work

#include <SoftwareSerial.h> 
//for pololu non-buffering serial channel
#include <String.h> //for parsing - necesary?
//#include <stdio.h> //for parsing - necessary?

//Constants
//#define PI 3.14159265358979323846
#define d2r (PI / 180.0)
#define EARTHRAD 6367515 // for long trips only
#define MAXRUDDER 210  //Maximum rudder angle
#define MINRUDDER 210   //Minimum rudder angle
#define NRUDDER 210  //Neutral position
#define MAXSAIL 180 //Neutral position
#define resetPin 8 //Pololu reset (digital pin on arduino)
#define txPin 9 //Pololu s  pin (with SoftwareSerial library)

//Pololu
SoftwareSerial servo_ser = SoftwareSerial(7, txPin); // for connecting via a nonbuffered serial port to pololu -output only

void servo_command(int whichservo, int position)
{
 servo_ser.print(0xFF, BYTE); //servo control board sync
 //Plolou documentation is wrong on servo numbers in MiniSSCII
 servo_ser.print(whichservo+8, BYTE); //servo number, 180 mode
 servo_ser.print(position, BYTE); //servo position
}

void setrudder(float ang)
{
//fill this in with the code to interface with pololu 
 
  int servo_num =0;
  int position;
 // Serial.println("Controlling motors");
  
  position = ang * 254.0 / 360.0;//convert from angle to a 256 maximum position
  
  servo_command(servo_num,position);
  //delay(10);
}

void setwinch(float ang)
{
//fill this in with the code to interface with pololu 
 
  int servo_num =1;
  int position;
 // Serial.println("Controlling motors");
  
  position = ang * 254.0 / 360.0;//convert from angle to a 256 maximum position
  
  servo_command(servo_num,position);
  //delay(10);
}


void setup(){
  	Serial.begin(9600);
	//Serial1.begin(9600);

 Serial.begin(9600);
 Serial2.begin(19200);
 Serial3.begin(4800);
 
  pinMode(txPin, OUTPUT); //txPin is 9
  pinMode(resetPin, OUTPUT); //reset pin is 8
  
  servo_ser.begin(2400);
  
  //next NEED to explicitly reset the Pololu board using a separate pin
  //else it times out and reports baud rate is too slow (red LED)
  digitalWrite(resetPin, 0);
  delay(10);
  digitalWrite(resetPin, 1);  
}

void loop(){
  setrudder(0);
  delay(100);
  setwinch(0);
  delay(1000);
  setrudder(90);
  delay(100);
  setwinch(90);
  delay(1000);
}
