/*
 *  Revised by Laszlo 2011-05-13
 *  Ported to Arudino November 2010 by Christine and the supercool software team  
 *  Created on: 2010-05-11
 *      Author: Nader for MAST Software
 */
/* ////////////////////////////////////////////////
// Changelog
////////////////////////////////////////////////
//So this is the new alpha 6 sailcode, it is a cleaned up version of alph 5 with
//added functionality and a more advanced data structures, restructured basic sailcode
*/

//All bearing calculations in this code assume that the compass returns True North readings. ie it is adjusted for declination.
//If this is not true: adjust for declination in the Parse() function, as compass data is decoded add or subtract the declination


//#include <math.h> doesnt work
#include "LocationStruct.h"
#include <SoftwareSerial.h> 
//for pololu non-buffering serial channel
#include <String.h> //for parsing - necessary?
#include <stdio.h> //for parsing - necessary?
#include <avr/interrupt.h>  //for future awesome interrupt routines
#include <avr/io.h>
//#include <Servo.h>  //for arduino generating PWM to run a servo
 
// Global variables and constants
////////////////////////////////////////////////


//Constants
#define MAIN_SERVO_RATE 0.6666   //constants for porting to new boat
#define JIB_SERVO_RATE 0.6666
#define RUDDER_SERVO_RATE -1
//Boat parameter constants
#define TACKING_ANGLE 40 //the highest angle we can point
//Course Navigation constants
#define MARK_DISTANCE 4 //the distance we have to be to a mark before moving to the next one, in meters //do we have this kind of accuracy??

//Station keeping navigation constants
#define STATION_KEEPING_RADIUS 15 //the radius we want to stay around the centre-point of the station-keeping course; full width is 40 meters
#define WIND_CHANGE_THRESHOLD 10 // the angle in degrees that the wind is allowed to shift by before we recalculate the waypoint locations (to avoid tacking)

//serial data constants
#define BUFF_MAX 511 // serial buffer length, set in HardwareSerial.cpp in arduino0022/hardware/arduino/cores/arduino
//Calculation constantes
//#define PI 3.14159265358979323846
#define d2r (PI / 180.0)
#define EARTHRAD 6367515 // for long trips only
#define DEGREE_TO_MINUTE 60 //there are 60 minutes in one degree
#define LATITUDE_TO_METER 1855 // there are (approximately) 1855 meters in a minute of latitude everywhere; this isn't true for longitude, as it depends on the latitude
//there are approximately 1314 m in a minute of longitude at 45 degrees north (Kingston); this difference will mean that if we just use deltax over deltay in minutes to find an angle it will be wrong
#define LONGITUDE_TO_METER 1314 //for kingston; change for Annapolis 1314 was kingston value
//motor control constants (deprecated, these need updating)
#define MAXRUDDER 210  //Maximum rudder angle
#define MINRUDDER 210   //Minimum rudder angle
#define NRUDDER 210  //Neutral position
#define MAXSAIL 180 //Neutral position

#define ALL_IN 0
#define ALL_OUT 100

//Pins
//pololu pins

#define resetPin 6 //Pololu reset (digital pin on arduino)
#define txPin 7 //Pololu serial pin (with SoftwareSerial library)

//#define servoPin 5 //arduino Servo library setup

//led pins
#define noDataLED  48 // no data, error indicator LED
#define oldDataLED 49 //there is data, but buffer is full, error indicator light
#define checksumBadLED 50 // indicates checksum fail on data
#define twoCommasLED 51 // indicates that there were two commas in the data, and it has been discarded and not parsed
#define rolloverDataLED 52 //indicates data rolled over, not fast enough
#define goodCompassDataLED 53 // indicates that strtok returned PTNTHTM, so we probably got good data

//for serial data aquisition
//This code hasn't been tested on the arduino yet; it should be compared to sailcode_alpha2 and 3, and to scanln
#define SHORTEST_NMEA 5
#define LONGEST_NMEA 120

//!when testing by sending strings through the serial monitor, you need to select "newline" ending from the dropdown beside the baud rate

// what's the shortest possible serial data string?
// for reliable serial data
int		extraWindData = 0; //'clear' the extra global data buffer, because any data wrapping around will be destroyed by clearing the buffer
int             extraCompassData = 0;
int		savedWindChecksum=0;//clear the global saved XOR value
int		savedWindXorState=0;//clear the global saved XORstate value
int		savedCompassChecksum=0;
int		savedCompassXorState=0;
int		lostData = 1;//set a global flag to indicate that the loop isnt running fast enough to keep ahead of the data
int 		noData =1; // global flag to indicate serial buffer was empty
char 		extraWindDataArray[LONGEST_NMEA]; // a buffer to store roll-over data in case this data is fetched mid-line
char            extraCompassDataArray[LONGEST_NMEA];
//------------------------

//for arduino Servo library control
//Servo myservo;  // create servo object to control a servo 
                // a maximum of eight servo objects can be created 
//Sensor data
//Heading angle using wind sensor
float heading;//heading relative to true north
float deviation;//deviation relative to true north; do we use this in our calculations?
float variance;//variance relative to true north; do we use this in our calculations?
//Boat's speed
float bspeed; //Boat's speed in km/h
float bspeedk; //Boat's speed in knots
//Wind data
float wind_angl;//wind angle, (relative to boat I believe, could be north, check this)
float wind_velocity;//wind velocity in knots
//Compass data
float headingc;//sum of all past headings relative to true north
float pitch;//pitch relative to ??
float roll;//roll relative to ??

int rudderVal;      //variables for transmiting data
int jibVal;
int mainVal;
int headingVal;

//Testing data (one-shots, no averaging, present conditions)
float heading_newest;//heading relative to true north
float wind_angl_newest;//wind angle, (relative to boat)

//Pololu
SoftwareSerial servo_ser = SoftwareSerial(7, txPin); // for connecting via a nonbuffered serial port to pololu -output only

int rudderDir = 1; //global for reversing rudder if we are parking lot testing
int points;        //max waypoints selected for travel
int point;          //point for sail to waypoint in menu 
int currentPoint = 0;    //current waypoint on course of travel

//Menu hack globals
int StraightSailDirection;
int CurrentSelection;
//stationkeepig globals
long startTime;
int stationCounter;
boolean timesUp;
int StationKeepingTimeInBox = 270000;//The amount of time the boat should stay in the box before leaving (in millis), to be adjusted based on intuition day of..
//early tacking code, simpler than the unimplemented version for testing 
//Jib has to be let out at the beginning of turning, this exert a moment on the boat allowing for faster turning, 
//after truned halfway, pull jib in and let main out, again faster turning, speed should not be an issue, not much required in order to turn
//should still check if in iron, if so let main out, turn rudder to one side, when angle is no longer closehauled
//try sailing again, 

boolean tacking;       //tacking globals
int tackingSide;    //1 for left -1 for right
int ironTime;


void relayData(){//sends data to shore

 //send data to zigbee
 Serial.println();
 Serial.print(boatLocation.latDeg);
 Serial.print(","); 
 Serial.print(boatLocation.latMin);
 Serial.print(",");
 Serial.print(boatLocation.lonDeg); //latitude and longitude of boat's location, split into more precise degrees and minutes, to fit into a float
 Serial.print(",");
 Serial.print(boatLocation.lonMin);
 Serial.print(",");
 Serial.print(bspeed); //boat speed 
 Serial.print(",");
 Serial.print(heading);  //boat direction
 Serial.print(",");
 Serial.print(wind_angl);  //wind angle, (relative to boat or north?)
 Serial.print(",");
 Serial.print(wind_velocity);//wind velocity in knots
 Serial.print(",");
 Serial.println(headingc);//compass heading

}

//**Alternate sailcourse code by laz, works the same but does not use long loops for waypoint selection, less responsive but allows for menu usage while sailing
//Instead of looping globals keep track of current waypoint, code updates that waypoint when reached and sets boat in the direction of the next one, this will be slightly less responsive as
//the time between each adjustment will include checking the menu but it should still be fast enough. Needs to be tested and compared to existing sailcourse function. Original in sailcode5
void sailCourse(){
  //sail the race course   
  //**declare things static so that they persist after each call, eliminate globals
  static int error; 
  static int distanceToWaypoint;//the boat's distance to the present waypoint
      
  error = sensorData(BUFF_MAX,'c');  
  error = sensorData(BUFF_MAX,'w');     
          
    distanceToWaypoint = GPSdistance(boatLocation, coursePoints[currentPoint]);//returns in meters
      relayData();
      Serial.println(distanceToWaypoint);
      
      //set rudder and sails    
      error = sailToWaypoint(coursePoints[currentPoint]); //sets the rudder, stays in corridor if sailing upwind       
      delay(100);//give rudder time to adjust? this might not be necessary
 //     error = sailControl(); //sets the sails proprtional to wind direction only; should also check latest heel angle from compass; this isnt turning a motor    
      delay(100); //pololu crashes without this delay; maybe one command gets garbled with the next one?
      
      distanceToWaypoint = GPSdistance(boatLocation, coursePoints[currentPoint]);//returns in meters
       
       if (distanceToWaypoint < MARK_DISTANCE){
      //sail testing code; this makes the pololu yellow light come on with flashing red
      currentPoint++;
       }
       if (currentPoint > points){
        currentPoint = points;
        return;
       }     
  } //end loop through waypoints

int sail(int waypointDirn){
  //sails towards the waypointDirn passed in, unless this is upwind, in which case it sails closehauled.
  //sailToWaypoint will take care of when tacking is necessary 
  
  //This function replaces straightsail which originally only controlled rudder
  
  int i;
  /* old description of Straightsail (deprecated)
         //this should be the generic straight sailing function; getWaypointDirn should return a desired compass direction, 
         //taking into account wind direction (not necc just the wayoint dirn); (or make another function to do this)
          //needs to set rudder to not try and head directly into the wind
   */
  static int error = 0; //error flag
  int directionError = 0;
  int angle = 0; 
  static int windDirn;
//  int j;
//  static int i;
//  static int[5] previousError;    //for averaging errors to give smoother rudder control
  //int waypointDirection;
//  if(i == 4){
//     i = 0;
//  }
//  else{
//  i++;
//  } 
  windDirn = getWindDirn(); 
  error = sensorData(BUFF_MAX, 'c'); //updates heading_newest
    if (error){
      //digitalWrite(CompassErrorLED,1); //set the compass LED indicator high
      digitalWrite(oldDataLED,HIGH);//error indicator
      return (error);
    }    
    digitalWrite(oldDataLED,LOW); //error indicator
    
   // error  = sensorData(BUFF_MAX, 'w'); //update wind direction
   // if (error)
     // return (error);
    //not used yet, but update whether closehauled or not from wind direction
    if(between(waypointDirn, windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)){ //check if the waypoint's direction is between the wind and closehauled on either side (ie are we downwind?)
        directionError = getCloseHauledDirn() - heading;      //*should* prevent boat from ever trying to sail upwind FIXME
    }
    else{
    directionError = waypointDirn - heading;//the roller-skate-boat turns opposite to it's angle FIXME
    }

    if (directionError < 0)
      directionError += 360;
      //    previousError[i] = directionError;    //code for averaging errors, 
//    directionError = 0;
//    for(j = 0; j < 5; j++){
//     directionError += prevousError[i];
//    }
//    directionError /= 5;
    if  (directionError > 10 && directionError < 350) { //rudder deadzone to avoid constant adjustments and oscillating, only change the rudder if there's a big error
        if (directionError > 180) //turn left, so send a negative to setrudder function
          setrudder((directionError-360)/4);  //adjust rudder proportional; setrudder accepts -45 to +45
        else
          setrudder(directionError/4); //turn rudder right; adjust rudder proportional; setrudder accepts -45 to +45     
    }   
    else
       setrudder(0);//set to neutral position      
       
    delay(10);     //wait to allow rudder signal to be sent to pololu
  directionError = sailControl();
  Serial.println("setting sails");
  return 0;
}

//new version of sailToWaypoint, this version checks if boat should tack or 'sail', thats it
int sailToWaypoint(struct points waypoint){
    static int waypointDirn;
    static int error = 0;
    waypointDirn = getWaypointDirn(waypoint); //get the next waypoint's compass bearing; must be positive 0-360 heading;
    Serial.println(waypointDirn);
    if(tacking == true){
      tack();
    }
    else if(checkTack(10, waypoint) == true){          //checks if outside corridor and sailing into the wind 
     tack(); 
    }
    else{                        //not facing upwind or inside corridor
       sail(waypointDirn); //get the next waypoint's compass bearing; must be positive 0-360 heading;); 
    }
    delay(300);
    return error;
}

//Checks if tacking is neccessary,returns true if it is false if not.
//looks to see if boat is in the downwind corridor and if its angle to the wind is closehauled.
//if the boat is pout the corridor and sailing closehauled then it will tack. This results in better turning and 
//will allow for the safety of the getOutOfIrons being called during any turn into the wind
boolean checkTack(int corridorHalfWidth, struct points waypoint){
   int currentHeading;
   int windDirn; 
    int waypointDirn; 
   int theta;
   float distance, hypotenuse;
   int difference;
   
   windDirn = getWindDirn();
   currentHeading = heading;
   //difference = currentHeading - windDirn;          //call between fix later
   if(currentHeading > windDirn){ 
   difference = currentHeading - windDirn;
    if(currentHeading > 360 - TACKING_ANGLE){
     difference -= 360;
    } 
   }
   else{
     difference = windDirn- currentHeading - windDirn;
     if(currentHeading >360 - TACKING_ANGLE){
      difference-=360; 
     }
   }
  if(abs(difference) < TACKING_ANGLE +5){            //checks if closehauled first, +5 for good measure
  //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for); 
  // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
  waypointDirn = getWaypointDirn(waypoint);
  theta = waypointDirn - windDirn;  
  
  // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
  hypotenuse = GPSdistance(boatLocation, waypoint);//latitude is Y, longitude X for waypoints
  
   //opp = hyp * sin(theta)
  distance = hypotenuse * sin(degreesToRadians(theta));
  Serial.println("The distance from the corridor is:  ");
  Serial.println(distance);
   if ( (distance  < 0 && wind_angl> 180) || (distance > 0 && wind_angl < 180) ) // check the direction of the wind so we only try to tack towards the mark
   {
     if (abs(distance) > corridorHalfWidth){ //we're outside corridor
           Serial.println("I want to tack because I'm outside the 10m corridor");
          return true; 
     }  else if(!between(waypointDirn, windDirn + TACKING_ANGLE, windDirn - TACKING_ANGLE)) { //if we're past the layline
         Serial.println("I want to tack because I'm past the layline");
         return true;
    }      
   }     
  }
  return false;
}

//this functin controls the sails, proportional to the wind direction with no consideration for wind strength (yet)
int sailControl(){
  int error =0;
  int windAngle;
  
  if (abs(roll) > 40){ //if heeled over a lot (experimentally found that 40 was appropriate according to cory)
   setMain(ALL_OUT); //set sails all the way out, keep jibaX 
   return (1); //return 1 to indicate heel
  }
   
  error = sensorData(BUFF_MAX, 'w'); //updates wind_angl_newest
  
  if (wind_angl > 180) //wind is from port side, but we dont care
    windAngle = 360 - wind_angl; //set to 180 scale, dont care if it's on port or starboard right now, though we will for steering and will in future set a flag here
  else
    windAngle = wind_angl;
    
  if (windAngle > TACKING_ANGLE) //not in irons
    setSails( (windAngle-TACKING_ANGLE)*100/(180 - TACKING_ANGLE) );//scale the range of winds from 30->180 (150 degree range) onto 0 to 100 controls (60 degree range); 0 means all the way in
  else
    setSails(ALL_IN);// set sails all the way in, in irons
    //call get out of irons routine?           
  return error;
}

void setup()
{
        
	Serial.begin(9600);

//for pololu
        pinMode(txPin, OUTPUT);
        pinMode(resetPin, OUTPUT);
                            
        servo_ser.begin(2400);
        delay(2000);
        //next NEED to explicitly reset the Pololu board using a separate pin
        //else it times out and reports baud rate is too slow (red LED)
        digitalWrite(resetPin, 0);
        delay(10);
        digitalWrite(resetPin, 1);  
        
//for arduino Servo library
//myservo.attach(servoPin);  // attaches the servo on pin 9 to the servo object 
 
 Serial2.begin(19200);
Serial3.begin(4800);
// 
 //setup indicator LEDs       
// pinMode(oldDataLED, OUTPUT); //there is data, but buffer is full, error indicator light
// pinMode(noDataLED, OUTPUT);  // no data, error indicator LED
// pinMode(twoCommasLED, OUTPUT); // indicates that there were two commas in the data, and it has been discarded and not parsed
// pinMode(checksumBadLED, OUTPUT);// indicates checksum fail on data
// pinMode(goodCompassDataLED, OUTPUT); // indicates that strtok returned PTNTHTM, so we probably got good data
// pinMode(rolloverDataLED, OUTPUT); //indicates data rolled over, not fast enough
//            
// digitalWrite(oldDataLED, LOW); //there is data, but buffer is full, error indicator light
// digitalWrite(noDataLED, LOW);  // no data, error indicator LED
// digitalWrite(twoCommasLED, LOW); // indicates that there were two commas in the data, and it has been discarded and not parsed
// digitalWrite(checksumBadLED, LOW);// indicates checksum fail on data
// digitalWrite(goodCompassDataLED, LOW); // indicates that strtok returned PTNTHTM, so we probably got good data
// digitalWrite(rolloverDataLED, LOW); //indicates data rolled over, not fast enough

 delay(10);          
  
  //initialize all counters/variables
    //current position from sensors
  boatLocation = clearPoints;    //sets initial location of the boat to 0;
  //Heading angle using wind sensor
  heading=0;//heading relative to true north
  deviation=0;//deviation relative to true north; do we use this in our calculations?
  variance=0;//variance relative to true north; do we use this in our calculations?
  //Boat's speed
  bspeed=0; //Boat's speed in km/h
  bspeedk=0; //Boat's speed in knots
  //Wind data
  wind_angl=0;//wind angle, (relative to boat or north?)
  wind_velocity=0;//wind velocity in knots
  //Compass data
  headingc=0;//heading relative to true north
  pitch=0;//pitch relative to ??
  roll=0;//roll relative to ??
  
  //Testing variables; present conditions, used for testing
  heading_newest=0;//heading relative to true north, newest
  wind_angl_newest=0;//wind angle relative to boat

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
  
//Commands to talk to wind sensor: none of this is working
//I switched the NMEA Combiner box's connections to the PC-OPTO-1-A cable to all be connected to the display terminals 
//(the input to the wind sensor was previously connected to the AUX IN connections on the end of the combiner board);
//no difference, still not working, data being sent from wind sensor
//Perhaps the PC-OPTO cable is broken? Or it's not properly getting power from the way it's setup with only 3 wires connected?
//  Serial3.println("$PAMTC,EN,Q*11"); // query the windsensor for its current settings based on the working copy in RAM (RAM as opposed to EPROM); this doesnt seem to be responding with anything, or it's being overwritten
//Serial3.println("$PAMTC,EN,ALL,0*1D"); //disable all commands; this doesnt seem to have worked
//Serial3.println("$PAMTX*50");//temporarily disable commands until power cycles; not working
//***above commands now working! opto-isolator is now gone!!

//$PAMTC,EN,S // save to EEPROM (changing wind sensor settings only affects RAM; unless this command is used, settings will return to previous state when power is cycled)

  delay(10);  
  setrudder(0);   
  delay(5000);  //setup delay
}

void loop()
{
  int error;
  int i;
  //int point;
  char input;
  int numWaypoints = 1;
  int waypoint;
  int distanceToWaypoint;
  int menuReturn;
  int GPSerrors = 0;
  int compassErrors = 0;

  //delay(1000);//setup delay, avoid spamming the serial port
  transmit();
  if(Serial.available())
  {
      menuReturn = displayMenu();
         if(menuReturn != 0) //if menu returned 0, any updating happened in the menu function itself and we want the code to just keep doing what it was doing before (e.g. setting RC mode)
      {
        CurrentSelection = menuReturn;
      }  
  }
  switch (CurrentSelection) {
  case 3://Straight Sail towards N,S,E,W as 0, 180, 90, 270. No sail control.
  Serial.print("Sailing towards: ");
  Serial.print(StraightSailDirection, DEC);
  Serial.println(" degrees.");
  sail(StraightSailDirection); //FIXME!!! Straightsail can no longer be called in isolation, needs sailtoWaypoint which keeps track of when tacking is necessary)
  break;
  case 1:        //this will be station keeping
  Serial.println("StationKeeping");
  stationKeep();
  break;    
  case 2:
  Serial.println("sailing course");
  sailCourse();
  break;
  case 4:
//  Serial.println("sail to Waypoint");
  sailToWaypoint(waypoints[point]);
  break;
  case 5:
  stationKeepSinglePoint();
  break;
  default:
  Serial.println("Invalid menu return. Press any key and enter to open the menu."); 
  delay(100);

 }
}
