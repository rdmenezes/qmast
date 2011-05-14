/*
 * Test.c: Sailing algorithm diagnostics program
 *
 *  Ported to Arudino November 2010 by Christine and the supercool software team
    Revised by Laszlo 2011-05-13
 *  Created on: 2010-05-11
 *      Author: Nader for MAST Software
 */
//test
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


#include <Servo.h>  //for arduino generating PWM to run a servo
 

// Global variables and constants
////////////////////////////////////////////////



//Constants
#define INIT_TIMER_COUNT 0          //setup for timer interrupt
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT
#define MAIN_SERVO_RATE 1   //constants for porting to new boat
#define JIB_SERVO_RATE 1
#define RUDDER_SERVO_RATE 1
//Boat parameter constants
#define TACKING_ANGLE 30 //the highest angle we can point
//Course Navigation constants
#define MARK_DISTANCE 1 //the distance we have to be to a mark before moving to the next one, in meters //do we have this kind of accuracy??

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
#define LONGITUDE_TO_METER 1314 //for kingston; change for Annapolis
//motor control constants (deprecated, these need updating)
#define MAXRUDDER 210  //Maximum rudder angle
#define MINRUDDER 210   //Minimum rudder angle
#define NRUDDER 210  //Neutral position
#define MAXSAIL 180 //Neutral position

//Pins
//pololu pins
#define resetPin 8 //Pololu reset (digital pin on arduino)
#define txPin 9 //Pololu serial pin (with SoftwareSerial library)

#define servoPin 10 //arduino Servo library setup

//led pins
#define noDataLED  48 // no data, error indicator LED
#define oldDataLED 49 //there is data, but buffer is full, error indicator light
#define checksumBadLED 50 // indicates checksum fail on data
#define twoCommasLED 51 // indicates that there were two commas in the data, and it has been discarded and not parsed
#define rolloverDataLED 52 //indicates data rolled over, not fast enough
#define goodCompassDataLED 53 // indicates that strtok returned PTNTHTM, so we probably got good data

//MUX pins
#define RCsteeringSelect 12 //control pin for RC vs autonomous steering
#define RCsailsSelect 13 //control pin for RC vs autonomous sails

//for serial data aquisition
//This code hasn't been tested on the arduino yet; it should be compared to sailcode_alpha2 and 3, and to scanln
#define SHORTEST_NMEA 5
#define LONGEST_NMEA 120

//!!!!when testing by sending strings through the serial monitor, you need to select "newline" ending from the dropdown beside the baud rate

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
Servo myservo;  // create servo object to control a servo 
                // a maximum of eight servo objects can be created 

//Counters (Used for averaging input data, obsolete)
int PTNTHTM;
int GPGLL;
int HCHDG;
int WIMWV;
int GPVTG;

 //GPGLL,4413.6803,N,07629.5175,W,232409,A,A*58 south lamp post
 //GPGLL,4413.6927,N,07629.5351,W,230533,A,A*51 middle tree by door
 //GPGLL,4413.7067,N,07629.4847,W,232037,A,A*53 NW corner of the dirt pit by white house
 //GPGLL,4413.7139,N,07629.5007,W,231721,A,A*57 middle lamp post
 //GPGLL,4413.7207,N,07629.5247,W,231234,A,A*5E at the top of the parking lot/bay ramp, where the edging and sidewalk end

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

//Testing data (one-shots, no averaging, present conditions)
float heading_newest;//heading relative to true north
float wind_angl_newest;//wind angle, (relative to boat)

//Pololu
SoftwareSerial servo_ser = SoftwareSerial(7, txPin); // for connecting via a nonbuffered serial port to pololu -output only

//set the reach target flag up
int finish; //something similar is needed for the actual program
int rc = 0; 
int rudderDir = 1; //global for reversing rudder if we are parking lot testing
int intCounter =0;  //counter for ISR
int points;        //max waypoints selected for travel
int currentPoint = 0;    //current waypoint on course of travel
double test1;
double test2;

//**ISR** 
//ISR(TIMER2_OVF_vect) {
//
//  intCounter ++;
//  if (intCounter == 5000) {
//    Serial.println("interrupt!!!");
//    intCounter = 0;
//  }
//};

//Menu hack globals
int StraightSailDirection;
int CurrentSelection;

//early tacking code, simpler than the unimplemented version for testing 
//Jib has to be let out at the beginning of turning, this exert a moment on the boat allowing for faster turning, 
//after truned halfway, pull jib in and let main out, again faster turning, speed should not be an issue, not much required in order to turn
//should still check if in iron, if so let main out, turn rudder to one side, when angle is no longer closehauled
//try sailing again, 
void tack(){    
boolean tackComplete = false;      
float startingWind_angl = wind_angl;
int newData = 0;
int dirn = 0;
int ironTime =0;
while(tackComplete == false){      //tacks depending on the side the wind is aproaching from
  if(wind_angl < 180){
    setMain(-30);
    setJib(30);                    //sets main and jib to allows better turning
    setrudder(-30);                //rudder angle cannot be to steep, this would stall the boat, rather than turn it
    while(wind_angl < 180){
      delay(100);
      newData = sensorData(BUFF_MAX, 'w');  
      ironTime++;                  //checks to see if turned far enough
      if(ironTime > 100){            //waits about 10 seconds to before assuming in irons
        getOutofIrons();
        }
      }
      setJib(-30);
      setMain(30);
    delay(1000);                        //delay to complete turning \
    newData = sensorData(BUFF_MAX, 'w');
    dirn = getCloseHauledDirn();
   straightSail(dirn);                //straighten out, sail closehauled
   setSails(-30);
    if(wind_angl >180){            //exits when turned far enough
      tackComplete = 1;
      }  
    }
      if(wind_angl > 180){        //mirror for other side
    setMain(-30);
    setJib(30);
    setrudder(30);
    while(wind_angl > 180){
      delay(100);
      newData = sensorData(BUFF_MAX, 'w');
      if(ironTime > 100){            //waits about 10 seconds to before assuming in irons
        getOutofIrons();
        }
      }
      setJib(-30);
      setMain(30);
    delay(1000);
    dirn = getCloseHauledDirn();
    straightSail(dirn);
    setSails(-30);
    newData = sensorData(BUFF_MAX, 'w');
    if(wind_angl < 180){
      tackComplete = 1;
      }  
    }
  }
}        //boat should continue closed hauled until it hits the other side of the corridor

//code to get out of irons if boat is stuck
void getOutofIrons(){
  int dirn;
  setMain(30);
  setrudder(30);        //arbitrary might want to base on direction of travel
  while(wind_angl < TACKING_ANGLE && wind_angl > 360 -TACKING_ANGLE){
  dirn = sensorData(BUFF_MAX, 'w');
  delay(100);
  }
  setSails(-30);
  setrudder(0);
}
double GPSdistance(struct points location1, struct points location2){
  //finds the distance between two latitude, longitude gps coordinates, in meters
    double deltaLat, deltaLong; //distance in x and y directions
    double distance;
    
    deltaLong = (location2.lonDeg - location1.lonDeg)*DEGREE_TO_MINUTE + (location2.lonMin - location2.lonMin); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
    deltaLat = (location2.latDeg - location1.latDeg)*DEGREE_TO_MINUTE + (location2.latMin - location2.latMin); //y is the east/west coordinate, + in the east direction
    
    //convert to meters, based on the number of meters in a minute, looked up for the given latitude
    deltaLat = deltaLat*LATITUDE_TO_METER; 
    deltaLong = deltaLong*LONGITUDE_TO_METER;
    
    distance = sqrt (deltaLat*deltaLat + deltaLong*deltaLong);     
    
    return distance;
}

int getWaypointDirn(struct points waypoint){
// computes the compass heading to the waypoint based on the latest known position of the boat and the present waypoint, both in global variables
// first converting minutes to meters
  int waypointHeading;//the heading to the waypoint from where we are
  float deltaX, deltaY; //the difference between the boats location and the waypoint in x and y
  
  // there are (approximately) 1855 meters in a minute of latitude; this isn't true for longitude, as it depends on the latitude
  //there are approximately 1314 m in a minute of longitude at 45 degrees north; this difference will mean that if we just use deltax over deltay in minutes to find an angle it will be wrong

  deltaX = (waypoint.latDeg - boatLocation.latDeg)*DEGREE_TO_MINUTE + (waypoint.latMin - boatLocation.latMin); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
  deltaY = (waypoint.lonDeg - boatLocation.lonMin)*DEGREE_TO_MINUTE + (waypoint.lonMin - boatLocation.lonMin); //y is the east/west coordinate, + in the east direction
   
  waypointHeading = radiansToDegrees(atan2(deltaY*LONGITUDE_TO_METER, deltaX*LATITUDE_TO_METER)); // atan2 returns -pi to pi, taking account of which variables are positive to put in proper quadrant 
        
  //normalize direction
  if (waypointHeading < 0)
    waypointHeading += 360;
  else if (waypointHeading > 360)
    waypointHeading -= 360;
    
  return waypointHeading;
}

int getCloseHauledDirn(){
  //find the compass heading that is close-hauled on the present tack
  
  int desiredDirection=0; //closehauled direction
  int windHeading = 0; //compass bearing that the wind is coming from
  
  windHeading = getWindDirn(); //compass bearing for the wind

  //determine which tack we're on 
  if (wind_angl_newest > 180) //wind from left side of boat first
    desiredDirection = windHeading + TACKING_ANGLE; //bear off to the right
  else 
    desiredDirection = windHeading - TACKING_ANGLE; //bear off to the left
  
  return desiredDirection;
}

int getWindDirn(){
  //ensure that BOTH sensorData(w) AND sensorData(c) are called before calling this, or the bearing will be off since the data was collected at different times
  
  //find the compass bearing the wind is coming from (ie if we were pointing this way, we'd be in irons)
  //be careful that we dont update the wind direction bearing based on new compass data and old wind data
  int windHeading = 0; //compass bearing that the wind is coming from
  
  windHeading = wind_angl_newest + headingc; // calculate the compass heading that the wind is coming from; wind_angle_newest is relative to the boat's bow  

  if (windHeading < 0) //normalize to 360
    windHeading += 360;
  else if (windHeading > 360)
    windHeading -= 360;   

  return windHeading;
}

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
int stayInDownwindCorridor(int corridorHalfWidth, struct points waypoint){
//calculate whether we're still inside the downwind corridor of the mark; if not, tacks if necessary
// corridorHalfWidth is in meters
  
  int theta;
  float distance, hypotenuse;
  
  //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for);
 
  // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
  theta = getWaypointDirn(waypoint) - getWindDirn();  
  
  // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
  hypotenuse = GPSdistance(boatLocation, waypoint);//latitude is Y, longitude X for waypoints
  
   //opp = hyp * sin(theta)
  distance = hypotenuse * sin(degreesToRadians(theta));
  
  if (abs(distance) > corridorHalfWidth){ //we're outside
    //can use the sign of distance to determine if we should be on the left or right tack; this works because when we do sin, it takes care of wrapping around 0/360
    //a negative distance means that we are to the right of the corridor, waypoint is less than wind
    if ( (distance  < 0 && wind_angl_newest > 180) || (distance > 0 && wind_angl_newest < 180) ){
      //want newest_wind_angle < 180, ie wind coming from the right to left (starboard to port?) side of the boat when distance is negative; opposite when distance positive
         tack();     //tack function should not return until successful tack
         Serial.println("Outside corridor, tacking");
    }
   
    return distance - corridorHalfWidth*(distance/abs(distance)); //this should be positive or negative... depending on left or right side of corridor.
   // We want this to be how far the boat is outside ie 0 if we're inside and -5 if we're 5 meters to the left, +5 if we're 5 meters to the right
   //If distance is positive, distance/abs(distance) is +1, therefore we subtract the corridor halfwidth from a positive number, giving 0 at the boundary and +'ve number outside
   //If distance is negative, distance/abs(distance) is -1, therefore we add the corridor halfwidth to a negative number, giving 0 at the boundary and -'ve number outside
  }
  else return 0;
}

void getStationKeepingCentre(double *centreLatMin, double *centreLonMin){
  //this function averages the GPS locations to find the centre point of the rectangle; has to be tested on Arduino
  /*
  double stationLatDeg = 44;
  double stationCornersLatMin[4] = {13.6803, 13.6927, 13.7067, 13.7139};
  double stationLonDeg = -76;
  double stationLonMin[4] = {29.5175,29.5351,29.4647,29.5007};
  */
  double sumLatMin = 0;
  double sumLonMin = 0;
  
  int i;//counter
  
  for (i = 0; i < 4; i++)
  {
//    sumLatMin+= stationCornersLatMin[i];
//    sumLonMin+= stationCornersLonMin[i];
  }
  
  *centreLatMin = sumLatMin/4;
  *centreLonMin = sumLonMin/4;
 // *centreLatDeg = 
 // *centreLonDeg = 
}

void fillStationKeepingWaypoints(double centreLatMin, double centreLonMin, int windBearing){
  
  double deltaLat;
  double deltaLon;
  int i;
  
  //distance in meters from midpoint to each mark is in STATION_KEEPING_RADIUS; this is the hypotenuse of a lat/long right angled triangle
  
  //the wind bearing is the angle from north to the direction the wind is coming from
  //it's also the direction we're putting the mark (want one mark directly upwind, 90 degrees to wind, downwind, -90 degrees)
  
  for (i = 0; i < 4; i++){
    deltaLat = STATION_KEEPING_RADIUS*cos(windBearing+90*i)/LATITUDE_TO_METER; //latitude is along the north vector
    deltaLon = STATION_KEEPING_RADIUS*sin(windBearing+90*i)/LONGITUDE_TO_METER; //longitude is perpendicular to the north vector
//    stationWaypointsLatMin[i] = deltaLat + centreLatMin;
  }    
}

int stationKeep(){
  //update the waypoints every bit to make sure we're compensating for the wind correctly
  //straightsail to the waypoints
  //ensure we've reached each waypoint before going to the next one
  
  // this function presently sails in a square with radius 15m from the centre-point; 
  //sailing between waypoints 1 and 3 will have the boat sailing in a beam reach (90 degrees to wind) always and may be more successful
  //this logic may fail (or at least take a long time to leave the box) in very light winds

//Tacking vs downwindCorridor:
//- for stationKeeping, sailtoWaypoint calls downwindCorridor, with the default 10m width;
//- if waypoints are set properly, it shouldnt ever be downwind, so dont need to worry about downwindCorridor
//- but if it calls it, this 10m width is too wide for a 5m barrier
//- can just call tack when we switch waypoints, assume that everything is fine :) instead of just turning, this will prevent failures but may lead to the boat leaving the box
//
//
//Future station-keeping strategy:
//- figure 8 at the top of the box (towards the middle to allow for tacking radius); check time before tacking to see if we should just leave the box
//- exit at bottom if theres time to kill before 5 minutes, if short time keep sailing straight to exit faster
//- sail down edge and check time, leave as 5 minutes hits


  // setup waypoints (requires that wayoints are manually entered
  double centreLatMin, centreLonMin;
  int windDirn, waypointWindDirn;
  int error;

  //Present waypoint variables
  double waypointLatDeg;//Present waypoint's latitude (x) degrees (north/south, +'ve is north) coordinate
  double waypointLatMin;//Present waypoint's latitude (x) minutes (north/south, +'ve is north) coordinate
  double waypointLongDeg;//Present waypoint's longitude (y) degrees (east/west, +'ve is east) coordinate
  double waypointLongMin;//Present waypoint's longitude (y) minutes (east/west, +'ve is east) coordinate
  struct points staypoint;
  int waypoint; //waypoint counter
  int distanceToWaypoint;//the boat's distance to the present waypoint
  
  //Timer variables
  long startTime, elapsedTime, currentTime, waypointTime;
  boolean timesUp = false;
  
  //get data from sensors for global variables
  error = sensorData(BUFF_MAX,'c');  
  error = sensorData(BUFF_MAX,'w');  
  
  //set up waypoints
  getStationKeepingCentre(&centreLatMin, &centreLonMin); //find the centre of the global stationkeeping corner variables
  windDirn = getWindDirn(); //find the wind direction so we can set out waypoints downwind from it
  waypointWindDirn = windDirn;
  fillStationKeepingWaypoints(centreLatMin, centreLonMin, windDirn);//set global station keeping waypoints  
  
  //sail between waypoints until 5 minute timer is up

  //initialize waypoints
 // waypointLatDeg =  stationWaypointsLatDeg[0];
 // waypointLongDeg = stationWaypointsLonDeg[0];    
  
  waypoint = 2; //start by sailing to the downwind waypoint  
  
  startTime = millis();//record the starting clock time
  waypointTime = startTime;
  
  //timed 5 minute loop of going through the waypoints
  do {
      //latitude
  //    waypointLatMin =  stationWaypointsLatMin[waypoint];
      //longitude
  //    waypointLongMin =  stationWaypointsLonMin[waypoint];   
          
      distanceToWaypoint = GPSdistance(boatLocation, staypoint);//returns in meters

      while (distanceToWaypoint > MARK_DISTANCE && !timesUp)
      {           
        //send data to xbee for reporting purposes
        relayData();
        Serial.println(distanceToWaypoint);
        
        //set rudder and sails 
        error = sensorData(BUFF_MAX,'c');     
        error = sensorData(BUFF_MAX,'w');            
        error = sailToWaypoint(staypoint); //sets the rudder, stays in corridor if sailing upwind       
        delay(100);//give rudder time to adjust? this might not be necessary
        error = sailControl(); //sets the sails proprtional to wind direction only; should also check latest heel angle from compass; this isnt turning a motor    
        delay(100); //pololu crashes without this delay; maybe one command gets garbled with the next one?
      
        //check timer
        currentTime = millis(); //get the Arduino clock time

        //update waypoints every second
        if (currentTime - waypointTime > 1000){
          error = sensorData(BUFF_MAX,'c'); //these might need to be taken out if the sensorData buffer is wrapping around from being called too frequently (wrap-around is broken)
          error = sensorData(BUFF_MAX,'w');
          windDirn = getWindDirn(); //find the wind direction so we can set out waypoints downwind from it
          if (!between(waypointWindDirn, windDirn + WIND_CHANGE_THRESHOLD, windDirn - WIND_CHANGE_THRESHOLD)){ //the present wind direction has changed from the previous waypoint setup
            fillStationKeepingWaypoints(centreLatMin, centreLonMin, windDirn);//set global station keeping waypoints  
            waypointWindDirn = windDirn;
          }
          waypointTime = currentTime;
        }        
        
        elapsedTime = currentTime - startTime;//calculate elapsed miliseconds since the start of the 5 minute loop
        if(elapsedTime > 300000) // (5min) * (60s/min) * (1000ms/s)
          timesUp = true;
        
        distanceToWaypoint = GPSdistance(boatLocation, staypoint);//returns in meters
      } //end go to waypoint
      
      waypoint++;
      if (waypoint ==5)       
          waypoint = 0;

   //   turnToWaypoint(); //gybe    
          
  } while(!timesUp); //loop the whole go to waypoint, check sensors and go to next waypoint until the time is up
  
  //leave square; can either calculate the closest place to leave, or just head downwind as we do here:
  while (1)
  {
    error = sensorData(BUFF_MAX,'c'); //these might need to be taken out if the sensorData buffer is wrapping around from being called too frequently (wrap-around is broken)
    error = sensorData(BUFF_MAX,'w');
      
    windDirn = getWindDirn();
    error = straightSail(windDirn+180); //sail based on compass only in downwind direction
    delay(100);//give rudder time to adjust? this might not be necessary
    error = sailControl(); //sets the sails proprtional to wind direction only; should also check latest heel angle from compass; this isnt turning a motor    
    delay(100); //poolu crashes without this delay; maybe one command gets garbled with the next one?     
  }    
  return 0;
}

//**Alternate sailcourse code by laz, works the same but does not use long loops for waypoint selection, less responsive but allows for menu usage while sailing
//Instead of looping globals keep track of current waypoint, code updates that waypoint when reached and sets boat in the direction of the next one, this will be slightly less responsive as
//the time between each adjustment will include checking the menu but it should still be fast enough. Needs to be tested and compared to existing sailcourse function. Original in sailcode5
void sailCourse(){
  //sail the race course   
  //**declare things static so that they persist after each call, eliminate globals
  int error; 
  int distanceToWaypoint;//the boat's distance to the present waypoint
      
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
        RC(1,1); //back to RC mode
       }     
  } //end loop through waypoints

int sail(int waypointDirn){
  //sails towards the waypointDirn passed in, unless this is upwind, in which case it sails closehauled.
  //sailToWaypoint will take care of when tacking is necessary 
  
  //This function replaces straightsail which originally only controlled rudder
  
  
  /* old description of Straightsail (deprecated)
         //this should be the generic straight sailing function; getWaypointDirn should return a desired compass direction, 
         //taking into account wind direction (not necc just the wayoint dirn); (or make another function to do this)
          //needs to set rudder to not try and head directly into the wind
   */
  int error = 0; //error flag
  int timer = 0; //loop timer placeholder; really we'll be timing?
  int directionError = 0;
  int angle = 0; 
  int windDirn;
  int waypointDirn;
  
 
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
        directionError = getCloseHauledDirn() - heading_newest;      //*should* prevent boat from ever trying to sail upwind
    }
    else{
    directionError = waypointDirn - heading_newest;//the roller-skate-boat turns opposite to it's angle
    }
    if (directionError < 0)
      directionError += 360;
      
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
  return 0;
}

//new version of sailToWaypoint, this version checks if boat should tack or 'sail', thats it
int sailToWaypoint(struct points waypoint){
    int waypointDirn;
    int distanceOutsideCorridor;
    int error = 0;
     waypointDirn = getWaypointDirn(waypoint); //get the next waypoint's compass bearing; must be positive 0-360 heading;
    
    if(checkTack(10, waypoint) == true){                  //checks if outside corridor and sailing into the wind 
     tack(); 
    }
    else{                        //not facing upwind or inside corridor
     error = sail(waypointDirn); //get the next waypoint's compass bearing; must be positive 0-360 heading;); 
    }
}

//Checks if tacking is neccessary,returns true if it is false if not.
//looks to see if boat is in the downwind corridor and if its angle to the wind is closehauled.
//if the boat is out the corridor and sailing closehauled then it will tack. This results in better turning and 
//will allow for the safety of the getOutOfIrons being called during any turn into the wind
boolean checkTack(int corridorHalfWidth, struct points waypoint){
   int currentHeading;
   int windDirn;  
   int theta;
   float distance, hypotenuse;
   int difference;
   
   windDirn = getWindDirn();
   currentHeading = heading;
   difference = currentHeading - windDirn;          //call between fix later
  if(abs(difference) < TACKING_ANGLE +5){            //checks if closehauled first, +5 for good measure
  //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for); 
  // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
  theta = getWaypointDirn(waypoint) - getWindDirn();  
  
  // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
  hypotenuse = GPSdistance(boatLocation, waypoint);//latitude is Y, longitude X for waypoints
  
   //opp = hyp * sin(theta)
  distance = hypotenuse * sin(degreesToRadians(theta));
  
  if (abs(distance) > corridorHalfWidth){ //we're outside
         if ( (distance  < 0 && wind_angl_newest > 180) || (distance > 0 && wind_angl_newest < 180) ) // check the direction of the wind so it doesn't try to tack away from the corridor
         {
          return true;
         }
     }    
  }
  return false;
}
// 0 is autonomous, 1 is RC controlled
void RC(int steering, int sails)
//change the RC vs autonomous selection mode; also delay to allow the signals time to propogate before sending motor commands
{
  if (steering){
    digitalWrite(RCsteeringSelect, HIGH);
   
  }
  else{
    digitalWrite(RCsteeringSelect, LOW);
  }
  
    //Serial.print("Set rudder control to value: ");
   // Serial.println(steering);
    
  if (sails){
    digitalWrite(RCsailsSelect, HIGH);
  }
  else  {
    digitalWrite(RCsailsSelect, LOW);
  }
  
   // Serial.print("Set sails control to value: ");
    //Serial.println(sails);
 
  delayMicroseconds(100); //0.1ms delay to allow select signals time to propogate and settle (this is maybe overkill?)
}

//this functin controls the sails, proportional to the wind direction with no consideration for wind strength (yet)
int sailControl(){
  int error =0;
  int windAngle;
  
  if (abs(roll) > 30){ //if heeled over a lot
   setSails(30); //set sails all the way out
   return (1); //return 1 to indicate heel
  }
   
  error = sensorData(BUFF_MAX, 'w'); //updates wind_angl_newest
  
  if (wind_angl_newest > 180) //wind is from port side, but we dont care
    windAngle = 360 - wind_angl_newest; //set to 180 scale, dont care if it's on port or starboard right now, though we will for steering and will in future set a flag here
  else
    windAngle = wind_angl_newest;
    
  if (windAngle > TACKING_ANGLE) //not in irons
    setSails(windAngle*60/(180 - TACKING_ANGLE) - TACKING_ANGLE - TACKING_ANGLE*60/150);//scale the range of winds from 30->180 (150 degree range) onto -30 to +30 controls (60 degree range); -30 means all the way in
  else
    setSails(-30);// set sails all the way in, in irons
           
  return error;
}


void setup()
{
        
	Serial.begin(9600);
	//Serial1.begin(9600);
//For interrupt sets frequency
//  TCCR2A |= ((1 << CS22) | (1 << CS21) | (1 << CS20));
//  //Timer2 Overflow Interrupt Enable
//  TIMSK2 |= (1 << TOIE2);
//  RESET_TIMER2;
//  sei();
//         
 Serial2.begin(19200);
 //Serial2.begin(9600);
 Serial3.begin(4800);

//for pololu
        pinMode(txPin, OUTPUT);
        pinMode(resetPin, OUTPUT);
                            
        servo_ser.begin(2400);

        //next NEED to explicitly reset the Pololu board using a separate pin
        //else it times out and reports baud rate is too slow (red LED)
        digitalWrite(resetPin, 0);
        delay(10);
        digitalWrite(resetPin, 1);  
        
//for arduino Servo library
 myservo.attach(servoPin);  // attaches the servo on pin 9 to the servo object 

 //setup indicator LEDs       
 pinMode(oldDataLED, OUTPUT); //there is data, but buffer is full, error indicator light
 pinMode(noDataLED, OUTPUT);  // no data, error indicator LED
 pinMode(twoCommasLED, OUTPUT); // indicates that there were two commas in the data, and it has been discarded and not parsed
 pinMode(checksumBadLED, OUTPUT);// indicates checksum fail on data
 pinMode(goodCompassDataLED, OUTPUT); // indicates that strtok returned PTNTHTM, so we probably got good data
 pinMode(rolloverDataLED, OUTPUT); //indicates data rolled over, not fast enough
            
 digitalWrite(oldDataLED, LOW); //there is data, but buffer is full, error indicator light
 digitalWrite(noDataLED, LOW);  // no data, error indicator LED
 digitalWrite(twoCommasLED, LOW); // indicates that there were two commas in the data, and it has been discarded and not parsed
 digitalWrite(checksumBadLED, LOW);// indicates checksum fail on data
 digitalWrite(goodCompassDataLED, LOW); // indicates that strtok returned PTNTHTM, so we probably got good data
 digitalWrite(rolloverDataLED, LOW); //indicates data rolled over, not fast enough
        
 //setup MUX controls   
 pinMode(RCsteeringSelect, OUTPUT);
 pinMode(RCsailsSelect, OUTPUT);
 
 digitalWrite(RCsteeringSelect, HIGH);
 digitalWrite(RCsailsSelect, HIGH);        
      
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

  //Counters (Used for averaging)
  PTNTHTM=0;
  GPGLL=0;
  HCHDG=0;
  WIMWV=0;
  GPVTG=0;
  
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
//  Serial3.println("$PAMTC,EN,ALL,0*1D"); //disable all commands; this doesnt seem to have worked
//  Serial3.println("$PAMTX*50");//temporarily disable commands until power cycles; not working
  
//$PAMTC,EN,S // save to EEPROM (changing wind sensor settings only affects RAM; unless this command is used, settings will return to previous state when power is cycled)


  RC(0,0);// autonomous sail and rudder control
  
  delay(10);
  
  setrudder(0);
   
  delay(5000);  //setup delay
}

void loop()
{
  int error;
  int i;
  char input;
  int numWaypoints = 1;
  int waypoint;
  int distanceToWaypoint;
  int menuReturn;
  int GPSerrors = 0;
  int compassErrors = 0;

  delay(100);//setup delay, avoid spamming the serial port
   
 //  connectSensors(); //waits for sensors to be connected; this isnt working, re-test

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
  Serial.println("sailing to waypoint");
  sailCourse();
  break;
        default:
  Serial.println("Invalid menu return. Press any key and enter to open the menu."); 
 }
}
