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

#include "LocationStruct.h"
#include <SoftwareSerial.h> 
//for pololu non-buffering serial channel
#include <String.h> //for parsing - necessary?
#include <stdio.h> //for parsing - necessary?
#include <avr/io.h>

// Global variables and constants
////////////////////////////////////////////////

//Constants
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
#define DEGREE_TO_MINUTE 60 //there are 60 minutes in one degree
#define LATITUDE_TO_METER 1855 // there are (approximately) 1855 meters in a minute of latitude everywhere; this isn't true for longitude, as it depends on the latitude
//there are approximately 1314 m in a minute of longitude at 45 degrees north (Kingston); this difference will mean that if we just u
e deltax over deltay in minutes to find an angle it will be wrong
#define LONGITUDE_TO_METER 1314 //for kingston; change for Annapolis 1314 was kingston value

//Error bit constants
#define noDataBit  0 // no data, error error bit
#define oldDataBit 1 //there is data, but buffer is full, error bit
#define checksumBadBit 2 // indicates checksum fail on data
#define twoCommasBit 3 // indicates that there were two commas in the data, and it has been discarded and not parsed
#define rolloverDataBit 4 //indicates data rolled over, not fast enough
#define badCompassDataBit 5 // indicates that strtok did not return PTNTHTM, so we probably got bad data
#define tooMuchRollBit 6    //indicates the boat is falling over
#define badWindData 7    //indicates an error from the wind sensor
#define badGpsData 8    //indicates error in gps data

//sail control constants
#define ALL_IN 0
#define ALL_OUT 100

//pololu pins

#define resetPin 8 //Pololu reset (digital pin on arduino)
#define txPin 9 //Pololu serial pin (with SoftwareSerial library)

//for serial data aquisition
#define SHORTEST_NMEA 5
#define LONGEST_NMEA 120

//!when testing by sending strings through the serial monitor, you need to select "newline" ending from the dropdown beside the baud 
ate
//------------------------
// for reliable serial data  
int		extraWindData = 0; //'clear' the extra global data buffer, because any data wrapping around will be destroyed by clearing the buffer
int            extraCompassData = 0;
int		savedWindChecksum = 0;//clear the global saved XOR value
int		savedWindXorState = 0;//clear the global saved XORstate value
int		savedCompassChecksum = 0;
int		savedCompassXorState = 0;
char 		extraWindDataArray[LONGEST_NMEA]; // a buffer to store roll-over data in case this data is fetched mid-line
char           extraCompassDataArray[LONGEST_NMEA];

//Sensor data
//Heading angle using wind sensor
float heading;//heading relative to true north, do not use, only updating 2 times a second
float deviation;//deviation relative to true north; do we use this in our calculations?Nope
float variance;//variance relative to true north; do we use this in our calculations?Nope
//Boat's speed
float bspeed; //Boat's speed in km/h
float bspeedk; //Boat's speed in knots
//Wind data
float wind_angl;//wind angle, (relative to boat I believe, could be north, check this)
float wind_velocity;//wind velocity in knots
//Compass data
float headingc;//heading from compass
float pitch;//pitch 
float roll;//roll 
float trueWind;// wind direction calculated at checkteck
//variables for transmiting data
int rudderVal;      
int jibVal;
int mainVal;
float headingVal;    //where we are going, temporary compass smoothing test
float distanceVal;    //distance to next waypoint
// one-shots, no averaging, present conditions
float heading_newest;//heading relative to true north
float wind_angl_newest;//wind angle, (relative to boat)

//Pololu
SoftwareSerial servo_ser = SoftwareSerial(7, txPin); // for connecting via a nonbuffered serial port to pololu -output only

int rudderDir = -1; //global for reversing rudder if we are parking lot testing
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

//tacking globals
boolean tacking;       
int tackingSide;    //1 for left -1 for right
int ironTime;

//error code
int errorCode;

void setup()
{       
  Serial.begin(19200);

  //for pololu
  pinMode(txPin, OUTPUT);
  pinMode(resetPin, OUTPUT);

  servo_ser.begin(4800);
  delay(2000);
  //next NEED to explicitly reset the Pololu board using a separate pin
  //else it times out and reports baud rate is too slow (red LED)
  digitalWrite(resetPin, 0);
  delay(10);
  digitalWrite(resetPin, 1);  

  Serial2.begin(19200);
  Serial3.begin(4800);
  // 
  delay(10);          

  //initialize all counters/variables
  //current position from sensors
  boatLocation = clearPoints;    //sets initial location of the boat to 0;
  //Heading angle using wind sensor
  heading = 0;//heading relative to true north
  deviation = 0;//deviation relative to true north; do we use this in our calculations?
  variance = 0;//variance relative to true north; do we use this in our calculations?
  //Boat's speed
  bspeed = 0; //Boat's speed in km/h
  bspeedk = 0; //Boat's speed in knots
  //Wind data
  wind_angl = 0;//wind angle, (relative to boat)
  wind_velocity = 0;//wind velocity in knots
  //Compass data
  headingc = 0;//heading relative to true north
  pitch = 0;//pitch relative to ??
  roll = 0;//roll relative to ??

  //Testing variables; present conditions, used for testing
  heading_newest = 0;//heading relative to true north, newest
  wind_angl_newest = 0;//wind angle relative to boat

  //compass setup code
  delay(1000); //give everything some time to set up, especially the serial buffers
  Serial2.println("$PTNT,HTM*63"); //request a data sample from the compass for heading/tilt/etc, and give it time to get it
  delay(200);
  //wind sensor setup code, changes rates
  Serial3.println("$PAMTC,EN,RMC,0,10");     //disable GPRMC
  Serial3.println("$PAMTC,EN,GLL,1,3");      //change gps to send 3.3 times a second
  Serial3.println("$PAMTC,EN,HDG,1,5");      //change heading to send 2 times a second
  Serial.println("$PAMTC,EN,MWVR,1,2");      //change wind to send 5 times a second default for now, need to make sure we can get everything out of the buffer
  delay(500);
  setrudder(0);   
  delay(2000);  //setup delay
  RCMode();
}

void loop()
{
  int menuReturn; 

  transmit();
  sensorData(BUFF_MAX, 'w');
  sensorData(BUFF_MAX, 'c');

  if(Serial.available())
  {
    menuReturn = displayMenu();
    if(menuReturn != 0) //if menu returned 0, any updating happened in the menu function itself and we want the code to just keep doing what it was doing be
      ore (e.g. setting RC mode)
      {
        CurrentSelection = menuReturn;
      }  
  }
  switch (CurrentSelection) {
  case 0:
    break;
  case 1:        //this will be station keeping
    stationKeep();
    break;    
  case 2:
    sailCourse();
    break;
  case 3://Straight Sail towards N,S,E,W as 0, 180, 90, 270. No sail control.
    sail(StraightSailDirection); // Straightsail can no longer be called in isolation, needs sailtoWaypoint which keeps track of when tacking is necessary
    break;
  case 4:
    sailToWaypoint(waypoints[point]);
    break;
  case 5:
    stationKeepSinglePoint();      //stationskeeps around a single spot in the middle of the square
    break;
  default:
    Serial.println("Invalid menu return. Press any key"); 
    delay(40);     
  }
}



