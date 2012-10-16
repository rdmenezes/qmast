//Pololu servo board test in Mini SSC II mode
//(mode jumper innplace on Pololu board)
#include <SoftwareSerial.h>
int servo_num;
int resetPin = 8; //note pin change to make room for arduino! reset is the pin next to the jummper
int txPin = 9;
// set up a new serial port
SoftwareSerial servo_ser = SoftwareSerial(7, txPin);
void setup() 
{
 digitalWrite(txPin, 1);
 pinMode(txPin, OUTPUT);
 pinMode(resetPin, OUTPUT);
 
 Serial.begin(9600);
 Serial.println("Input servo number (0,1,2), and position (0-254)\n");
 servo_ser.begin(2400);
 //next NEED to explicitly reset the Pololu board using a separate pin
 //else it times out and reports baud rate is too slow (red LED)
 digitalWrite(resetPin, 0);
 delay(10);
 digitalWrite(resetPin, 1);
 delay(10);
 
  
}
void loop() 
{
 int c, pos;
 char ch;  
 if ((c = Serial.read()) != -1) 
 {
    ch = char(c);
    if(ch=='0' || ch=='1' || ch=='2')
    {
      servo_num = ch-0x30;
      Serial.println(servo_num);
      Serial.print("Servo #"); 
      Serial.print(ch, BYTE); 
      Serial.print("  Position= ");  
      while((c = Serial.read()) == -1); //loop waiting
      ch = char(c);
      pos = (ch-0x30)*20;
      if(pos < 0) pos = 0; 
      if(pos > 254) pos = 254; 
      Serial.println(pos,DEC); //print position and move to next line
      servo_command(servo_num,pos);
      delay(1000);
    } 
 }
}
void servo_command(int whichservo, int pos)
{ 
 servo_ser.print(0xFF, BYTE); //servo control board sync
 //Plolou documentation is wrong on servo numbers in MiniSSCII
 servo_ser.print(whichservo+8, BYTE); //servo number, 180 mode
 servo_ser.print(pos, BYTE); //servo position
}
