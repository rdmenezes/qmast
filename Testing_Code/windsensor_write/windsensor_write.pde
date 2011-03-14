/*
* omg this isn't working for not apparent reason. The data we get back is corrupt...? but running alpha5 is fine and we copied and pasted from there...
*/

#include <SoftwareSerial.h> 
//for pololu non-buffering serial channel
#include <String.h> //for parsing - necessary?
#include <stdio.h> //for parsing - necessary?


#include <Servo.h>  //for arduino generating PWM to run a servo

void setup()
{
  Serial.begin(9600);
	//Serial1.begin(9600);

 Serial2.begin(19200);
 //Serial2.begin(9600);
 Serial3.begin(4800);
    
      
 //test pin
// pinMode(13, OUTPUT);
// digitalWrite(13, HIGH);
        
 delay(10);          
        //initialize all counters/variables
  


//compass setup code
//  delay(1000); //put this back in if you want to change the compass to sample mode
// Serial2.println("@F0.3=0*66"); //this puts the compass into sample mode (return data only when requested)
  delay(1000); //give everything some time to set up, especially the serial buffers
  Serial2.println("$PTNT,HTM*63"); //request a data sample from the compass for heading/tilt/etc, and give it time to get it
  delay(200);
  
//wind sensor setup code
//*hh<CR><LF>
//$PAMTC,EN*hh<CR><LF>
//$PAMTC,OPTION*hh<CR><LF>
//$PAMTX*hh<CR><LF>
//$PAMTC,ATTOFF*hh<CR><LF> // set which way is forward; have to input degrees; theres a nice description of the procedure for doing this in the manual
//$PAMTC,ALT,Q*hh<CR><LF> will return $PAMTR,ALT,a,b,c with a,b,c = altitude,fixed or not, pressure setting
  
  //Serial3.println("$PAMTC,EN,Q*11"); // query the windsensor for its current settings based on the working copy in RAM (RAM as opposed to EPROM)
  delay(200);
  
  delay(5000);

}


void loop(){
  char input =0;
 while (Serial3.available()>0)
   {
     input = Serial3.read();
     Serial.print(input);
   }        
   delay(250);
}
