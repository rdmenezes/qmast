/*
 * Test.c: Sailing algorithm diagnostics program
 *
 *  Ported to Arudino November 2010 by Christine and the supercool software team

 *  Created on: 2010-05-11
 *      Author: Nader for MAST Software
 */
//test
/* ////////////////////////////////////////////////
// Changelog
////////////////////////////////////////////////
//CB Jan 21 data isnt clearing checksum?

// CB, Dec 7 - added ported parser function and associated updates to the loop function
// still missing:
- getting data from the serial ports; 
- switching to manual mode; 
- prompting for waypoints; 
- PID rudder; 
- sail control
*/

//All bearing calculations in this code assume that the compass returns True North readings. ie it is adjusted for declination.
//If this is not true: adjust for declination in the Parse() function, as compass data is decoded add or subtract the declination


//#include <math.h> doesnt work

#include <SoftwareSerial.h> 
//for pololu non-buffering serial channel
#include <String.h> //for parsing - necessary?
#include <stdio.h> //for parsing - necessary?


#include <Servo.h>  //for arduino generating PWM to run a servo
 

// Global variables and constants
////////////////////////////////////////////////



//Constants
#define MAIN_SERVO_RATE 1   //constants for porting to new boat
#define JIB_SERVO_RATE 1
#define RUDDER_SERVO_RATE 1
//Boat parameter constants
#define TACKING_ANGLE 30 //the highest angle we can point
//Course Navigation constants
#define MARK_DISTANCE 1 //the distance we have to be to a mark before moving to the next one, in meters

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
int		savedChecksum=0;//clear the global saved XOR value
int		savedXorState=0;//clear the global saved XORstate value
int		lostData = 1;//set a global flag to indicate that the loop isnt running fast enough to keep ahead of the data
int 		noData =1; // global flag to indicate serial buffer was empty
char 		extraWindDataArray[LONGEST_NMEA]; // a buffer to store roll-over data in case this data is fetched mid-line
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

//Global boat variables
//Position variables
//float latitude; //Curent latitude, low precision, old
//float longitude; 
double longitudeDeg; //latitude and longitude of boat's location, split into more precise degrees and minutes, to fit into a float
double longitudeMin;
double latitudeDeg;
double latitudeMin;
//as far as I know, these need to be phased out and arent used for any reason:
float GPSX; //Target X coordinate
float GPSY; //Target Y coordinate
float prevGPSX; //previous Target X coordinate
float prevGPSY; //previous Target Y coordinate
//float waypointX;//Present waypoint's X (north/south, +'ve is north) coordinate
//float waypointY;//Present waypoint's Y (east/west, +'ve is east) coordinate

double courseWaypointsLatDeg[10];//List of waypoint's latitude (x) degrees (north/south, +'ve is north) coordinate
double courseWaypointsLatMin[10];//List of waypoint's latitude (x) minutes (north/south, +'ve is north) coordinate
double courseWaypointsLonDeg[10];//List of waypoint's longitude (y) degrees (east/west, +'ve is east) coordinate
double courseWaypointsLonMin[10];//List of waypoint's longitude (y) minutes (east/west, +'ve is east) coordinate


//Station keeping variables

//Station-keeping waypoints; 4 corners of the square
double stationCornersLatDeg = 44;
double stationCornersLatMin[4] = {13.6803, 13.6927, 13.7067, 13.7139};
double stationCornersLonDeg = -76;
double stationCornersLonMin[4] = {29.5175, 29.5351, 29.4647, 29.5007};

 //GPGLL,4413.6803,N,07629.5175,W,232409,A,A*58 south lamp post
 //GPGLL,4413.6927,N,07629.5351,W,230533,A,A*51 middle tree by door
 //GPGLL,4413.7067,N,07629.4847,W,232037,A,A*53 NW corner of the dirt pit by white house
 //GPGLL,4413.7139,N,07629.5007,W,231721,A,A*57 middle lamp post
 //GPGLL,4413.7207,N,07629.5247,W,231234,A,A*5E at the top of the parking lot/bay ramp, where the edging and sidewalk end
double stationWaypointsLatDeg = 44;
double stationWaypointsLatMin[4];
double stationWaypointsLonDeg = -76;
double stationWaypointsLonMin[4];

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


//boolean tackSide=0;//tacking to left or right
//int port1;//what is this?
//char total[10000];//cb buffer variable


//set the reach target flag up
int finish; //something similar is needed for the actual program
int rc = 0; 
//char waypts[] = "$WAYP"; //for arduino, this should be implemented in String class objects (unless the memory use is too high)
int waypt[20]; //maximum of 10 waypoints for now
//String waypts = String("$WAYP"); //for arduino


//Menu hack globals
int StraightSailDirection;
int CurrentSelection;


//Andrew Brannan wrote this during 2010-2011
//returns the value of the menu item so loop knows what to do.
//returns 0 when all updating happened in the menu (e.g. setting RC mode) and code should continue with previous selection
int displayMenu()
{
  /*
  Menu tasks:
   change the time to exit station-keeping (ie 2 minutes before 5 minutes in very light wind, at 5 minute in strong wind, based on subjective idea of how long the boat might take to leave the square)
   switch rudder/sail control directions (ie different mechanical setups may reverse which direction is left/right, in/out);
   enable RC mode; 
   input GPS locations for a regular course and for station-keeping;
   tell the boat to start navigating a course; 
   tell the boat to start station-keeping; 
   report data; 
   probably some other things that we'll think of as we parking-lot test
   adjust for compass declination
   Neat ideas:
   - verbose mode
   */  
  
	boolean stayInMenu = true; 					
	boolean hasSelection = false;
	boolean hasSailDirection = false;
	char selection;
	boolean someVal = false;
	boolean hasTackVal = false;
        boolean compassData = false;
        boolean windData = false;
        boolean speedData = false;
	boolean hasX = false;
        boolean hasY = false;
        boolean badGPS = false;
        boolean hasRudderRCvalue = false;
        boolean hasSailsRCvalue = false;
        double gpsDigit = 0;
        int power = 3;
        
        
	char sailDirection;
        byte rudderRCvalue;
        byte sailsRCvalue;
	byte tackVal;
	
	float temp;
	
	//GAELFORCE!
		
	
	Serial.println("");
	
	//Val: not anymore, now return stuff based on inputs, 0 for unchanged //this loops through the menu until the user has selected the "exit menu" function 
	while(true)//stayInMenu == true)
	{
		//menu options
		Serial.println("");
		Serial.println("___________________  MENU  ______________________");
		Serial.println("");
		Serial.println("");
		Serial.println("a.	Input Waypoints");
		Serial.println("b.	Begin automated sailing");
		Serial.println("c.     *Straight sail");
		Serial.println("d.	Sailside");
		Serial.println("e.	Tack");
		Serial.println("f.	Get Wind Sensor Data");
		Serial.println("g.      Get Compass Data");
                Serial.println("h.      Get Speed Data");
                Serial.println("i.     *Toggle RC");
		Serial.println("j.     *Exit Menu");
                Serial.println("z.     *Clear serial buffer");
		Serial.println("");
		Serial.println("Select option:");
		
		//clears values from previous menu selection
		hasSelection = false;
		Serial.flush();
		
		//waits for user input to come from serial port
		while(hasSelection == false)
		{
			if(Serial.available() > 0)
			{ 
				selection = Serial.read(); //Val: switched to char values since out of single digits // - '0';     //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)			
				hasSelection = true;
			}	
		}
		
		
		//calls appropriate function, and returns to the menu after function execution
		//Serial.println(selection,BYTE);    this prints the input, but the serial input is stored as its ASCII value, (ie 1 = 49, 2 = 50, etc)
		switch(selection)
		{
			//call input waypoints function
                        //assuming that waypoints are of the form XXXX.XXXX....X
			case 'a':
				Serial.println("Selected a");

                                prevGPSX = GPSX; //Storing current GPS values and then reseting them too zero
                                prevGPSY = GPSY;
                                GPSY = 0;
                                GPSX = 0;
                                hasX = false;
                                hasY = false;	
                                power = 3;
                                
                                /*
                                BASIC LOGIC TO PARSE COORDONITES
                                
                                The Serial input can only take 1 character at a time, so you have to read each character from the input co-ordoninte (eg. 1234.5678) 
                                and then rebuild the co-ordonite inside the arduino.  The way this program does it is to keep a running "power" variable.  Each time 
                                a new character is read, it is mulitplied by 10^power, then added to the final value.  Power is then deceremented by one and the
                                process is repeated until there are no more characters to be read.
                                */
                              
                                Serial.println("Enter GPS X Co-ordonite:  ");
                                while(!hasX){
                                  if(Serial.available() > 0){
                                    //Code to get serial data from the buffer and put it into GPSX
                          
                                    while(gpsDigit != (46-'0')){
        //                              while(Serial.available() == 0);    //wait until serial data is available
                                      gpsDigit = Serial.read() - '0';
                                      
                                      /*if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      }   
                                       */  
                                      GPSX = GPSX + (gpsDigit*pow(10,power));
                                      
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                           
                                    }
                                   // if(badGPS = true)
                                   //   break;
                                    gpsDigit = Serial.read(); //Just reading the '.' to get rid of it and get too the stuff after the decimal
                                    //power--;
                                    while(Serial.available() > 0){
                                      gpsDigit = Serial.read() - '0';
                                      GPSX = GPSX + (gpsDigit * pow(10,power));
                                      
                                     /* if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      } 
                                      */
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--; 

                                    }
                                    
                                    hasX = true;
                                    Serial.println(GPSX);
                                  }
                                  
                                  
                                }
                                
                                power = 3;
                                
                                Serial.println("Enter GPS Y Co-ordonite:  ");
                                while(!hasY){
                                  if(Serial.available() > 0){
                                    //Code to get serial data from the buffer and put it into GPSX
                          
                                    while(gpsDigit != (46-'0')){
                                      gpsDigit = Serial.read() - '0';
                                      
                                      /*if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      }   
                                       */  
                                      GPSY = GPSY + (gpsDigit*pow(10,power));
                                      
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                           
                                    }
                                   // if(badGPS = true)
                                   //   break;
                                    gpsDigit = Serial.read(); //Just reading the '.' to get rid of it and get too the stuff after the decimal
                                    //power--;
                                    while(Serial.available() > 0){
                                      gpsDigit = Serial.read() - '0';
                                      GPSY = GPSY + (gpsDigit * pow(10,power));
                                      
                                     /* if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      } 
                                      */
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--; 

                                    }
                                    
                                    hasY = true;
                                    Serial.println(GPSY);
                                  }
                                  
                                  
                                }
                                
                                                              
                                Serial.print("Entered waypoints:  X = ");
                                Serial.print(GPSX);
                                Serial.print(" ,Y = ");
                                Serial.println(GPSY);
                                
                                return 0; //function set waypoints but then still need to tell boat what to do
				break;
				
				//start automated sailing	
			case 'b':
				Serial.println("Selected autonomous sailing. Currently unused in menu.");
				//Sail();      calls functions to begin automated sailing

                                return 0;//update this when it does something :)
				break;
				
				//call rudder angle set function
			case 'c':
				Serial.println("Enter desired compass direction (n, s, e, w): ");
                                //april 8th 2011 in process of being hacked from set rudder angle to set sail angle, Valerie is being really lazy and keeping the name rudderAngle for now
				while(hasSailDirection == false)
				{
					if(Serial.available() > 0)
					{ 
						//this will have to be changed to use Serial.readln function
						sailDirection = Serial.read(); //- '0'; now reading a char    //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)	
//						if(rudderAngle >= 0 && rudderAngle <= 360)	//check for valid rudder angle input
//						{
//							hasRudderAngle = true;
//							//setRudder(float(rudderAngle)); 
//                                                        StraightSailDirection = rudderAngle;
//							Serial.print("Compass bearing set to: ");
//							temp = float(rudderAngle);
//							Serial.println(temp);
//						}
//						else
//						{
//							Serial.println("Invalid Angle");
//						}

                                                switch(sailDirection)
                                              {  //the input char sailDirection
                                                case 'n':
                                                  StraightSailDirection = 0;
                                                  hasSailDirection = true;
                                                break;
                                                case 's':
                                                  StraightSailDirection = 180;
                                                  hasSailDirection = true;
                                                break;
                                                case 'e':
                                                  StraightSailDirection = 90;
                                                  hasSailDirection = true;
                                                break;
                                                case 'w':
                                                  StraightSailDirection = 270;
                                                  hasSailDirection = true;
                                                break;
                                                default:
                                                  Serial.println("Invalid entry, please enter n,s,e or w");
                                                break;
                                              }
                                                
                                                
					}

                                       
				}
                                return 3;	
				//hasSailDirection = false; // Val: why set this local variable back to false? Can probably delete this.
				break;
				
				//call sailside function
				case 'd':
					Serial.println("Selected SailSide. Currently unused in menu.");	
					//Sailside();     
                                        return 0;
  					break;
					
					//call tack function
				case 'e':
                                        Serial.println("Select tack direction. Currently unused in menu");
					Serial.println("Enter Tack direction: ");
					while(hasTackVal == false)
					{
						if(Serial.available() > 0)
						{ 
							//this will have to be changed to use Serial.readln function
							tackVal = Serial.read() - '0';     //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)	
							if(tackVal >= 0 && tackVal <= 9)	//check for valid tackVal input
							{
								hasTackVal = true; 
								Serial.print("Tack chosen is: ");
								Serial.println(tackVal);
							}
							else
							{
								Serial.println("Invalid Tack Direction");
							}
						}	
					}
					
                                        return 0;
					break;
					
					//call wind function	
					case 'f':
						Serial.println("Selected Wind");
						windData = sensorData(BUFF_MAX,'w');

                                                if(windData == false){
                                                  Serial.println("Wind Sensor Data: ");
                                                  Serial.print("  Wind Angle:  ");
                                                  Serial.println(wind_angl);
                                                  Serial.print("  Wind Velocity (knots):   ");
                                                  Serial.println(wind_velocity);
                                                  
                                                }

						break;
						//exits the menu
					case 'g':
						Serial.println("Selected Compass");
						compassData = sensorData(BUFF_MAX,'c');
        						
                                                if(compassData == false){
                                                  Serial.println("Compass Data: ");
                                                  Serial.print("  Heading:  ");
                                                  Serial.println(headingc);
                                                  Serial.print("  Pitch:   ");
                                                  Serial.println(pitch);
                                                  Serial.print("  Roll   ");
                                                  Serial.println(roll);
                                                  
                                                }
                                                else{
                                                  Serial.println("Error fetching compass data");
                                                }
                                                
                                                return 0;
						break;

                                        case 'h':
						Serial.println("Selected Speed");
        						                         
                                                  Serial.println("Speed Data: ");
                                                  Serial.print("  Boat's speed (km/h):  ");
                                                  Serial.println(bspeed);
                                                  Serial.print("  Boat's speed(knots):   ");
                                                  Serial.println(bspeedk);
                                                return 0;
						break;
					
                                        case 'i':
                                            Serial.println("Selected Toggle RC");
                                            Serial.println("Enter desired RUDDER control value (1 for RC, 0 for autonomous)");
                                            while (!hasRudderRCvalue) {
                                              if(Serial.available())
                                              {
                                                rudderRCvalue = Serial.read() - '0';
                                                if(rudderRCvalue == 0 || rudderRCvalue == 1)
                                                {
                                                 hasRudderRCvalue = true;
                                                }
                                                else
                                                {
                                                  Serial.print("read value: ");
                                                  Serial.println(rudderRCvalue, DEC);
                                                  Serial.println("Invalid value, please enter 0 or 1");
                                                  
                                                }
                                              }
                                              
                                            }//end rudder rc value
                                            Serial.println("Enter desired SAILS control value (1 for RC, 0 for autonomous)");
                                            while (!hasSailsRCvalue) {
                                               if(Serial.available())
                                              {
                                                sailsRCvalue = Serial.read() - '0';
                                                if(sailsRCvalue == 0 || sailsRCvalue == 1)
                                                {
                                                  hasSailsRCvalue = true;
                                                  
                                                }
                                                else
                                                {
                                                  Serial.println("Invalid value, please enter 0 or 1");
                                                }
                                              }
                                              
                                            }// end sails rc value
                                            
                                            RC(rudderRCvalue, sailsRCvalue);      
           
                                         return 0;                                 
                                        
                                        break;
					case 'j':
						Serial.println("Exiting Menu");
                                                return 0;
					//	stayInMenu = false;
						//does nothing

                                        case 'z': //If you press z it clears the serial buffer
                                                Serial.flush();
                                                Serial.println("Serial Buffer Cleared");
                                                break;
                                        
					default:
						break;
			}	
						
			
	}
}	

/////////////////////////////////////////////////////
//LEVEL 3 Functions
////////////////////////////////////////////////////

//this function assumes wind_angl_newest is relative to north. This still needs to be fixed -Val and Tom; This has been abandoned - christine, april 3
//void sailUpWind(){ 
//  int closeHauledDirn=0;//desired direction
//  int directionError=0;//difference between actual direction and desired
//  int waypointDirn=0;//direction to waypoint
//  int tackDirection=0;
//  int timer=0;
//  
//  closeHauledDirn=getCloseHauledDirn(tackSide);
//
////sail in a straight line to close hauled direction
//  straightSail(closeHauledDirn); //I believe this replaces the below block comment?
///*  directionError = heading_newest - closeHauledDirn;
//  
//  while (timer < 10){
//    if  (abs(directionError) > 10){
//      setrudder(directionError); //adjust rudder proportional
//      delay (10);
//      setrudder(0); //straight rudder
//    }  
//    delay(500);
//    timer ++;
//  }*/
//  
//  //---check if we can close haul to target by tacking---
//  waypointDirn = getWaypointDirection();
//  tackDirection = getCloseHauledDirn(!tackSide);//other close hauled angle
//  float slopeDesiredLine=0;//final close hauled path to target(slope)
//  int yIntLine=0;//final close hauled path to target(y-intercept)
//  slopeDesiredLine=1/(tan(degreesToRadians(180-tackDirection)));//this will explode if tan returns 0, but it shouldnt if you think about the sail logic
//  yIntLine=latitude-slopeDesiredLine*longitude;//y=m*x+b ==>  b=y-m*x
//  boolean aboveLine;//is the boat further north then the line
//  
//  if (latitude < slopeDesiredLine*longitude+yIntLine){//is y_boat < y_line at current x pos
//    if (wind_angl_newest>=90&&wind_angl_newest<=270){//is wind coming from south
//     if (canTack()){
//       tackSide=!tackSide; 
//       //maybe have tack function wich controls sails too       
//     }else{
//       //should bear off then tack
//     }
//    }
//  }else{
//   if (wind_angl_newest<=90||wind_angl_newest>=270){//is wind coming from noth
//     if (canTack()){
//       tackSide=!tackSide; 
//       //maybe have tack function wich controls sails too
//     }else{
//       //should bear off then tack 
//     }
//    }
//  }  
//  
//  //should also tack if we are far off course ; use a corridor to decide this
//}
//boolean canTack(){ //abandonned, april 3, Christine
//  return true;//placeholder should use wind speed vs boat speed
//}

void tack(){
//fill in
}


double GPSconv(double lat1, double long1, double lat2, double long2) 
//this is code to calculate the distance between 2 GPS coordinates, written by nader without any comments. Maybe it works. We'll see.
{		
	double dlong;
	double dlat;
	double a;
	double c;
	double d;

	Serial.println("GPSconv");

	dlong = (long2 - long1) * d2r;
	dlat = (lat2 - lat1) * d2r;
	a = sin(dlat / 2.0)*sin(dlat / 2.0) + cos(lat1 * d2r) * cos(lat2 * d2r) * sin(dlong / 2.0)*sin(dlong / 2.0);
	c = 2 * atan(sqrt(a) / sqrt(1 - a)); //replaced atan2 with atan ? is there such thing as atan2 function before arduino?
	d = 6367 * c;
	
	return d;
}

double GPSdistance(double latitudeDeg1, double latitudeMin1, double longitudeDeg1, double longitudeMin1, double latitudeDeg2, double latitudeMin2, double longitudeDeg2, double longitudeMin2) {
  //finds the distance between two latitude, longitude gps coordinates, in meters
    double deltaLat, deltaLong; //distance in x and y directions
    double distance;
    
    deltaLong = (longitudeDeg2 - longitudeDeg1)*DEGREE_TO_MINUTE + (longitudeMin2 - longitudeMin1); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
    deltaLat = (latitudeDeg2 - latitudeDeg1)*DEGREE_TO_MINUTE + (latitudeMin2 - latitudeMin1); //y is the east/west coordinate, + in the east direction
    
    //convert to meters, based on the number of meters in a minute, looked up for the given latitude
    deltaLat = deltaLat*LATITUDE_TO_METER; 
    deltaLong = deltaLong*LONGITUDE_TO_METER;
    
    distance = sqrt (deltaLat*deltaLat + deltaLong*deltaLong);     
    
    return distance;
}

int getWaypointDirn(double waypointLatDeg, double waypointLatMin, double waypointLongDeg, double waypointLongMin){
// computes the compass heading to the waypoint based on the latest known position of the boat and the present waypoint, both in global variables
// first converting minutes to meters
  int waypointHeading;//the heading to the waypoint from where we are
  float deltaX, deltaY; //the difference between the boats location and the waypoint in x and y
  
  // there are (approximately) 1855 meters in a minute of latitude; this isn't true for longitude, as it depends on the latitude
  //there are approximately 1314 m in a minute of longitude at 45 degrees north; this difference will mean that if we just use deltax over deltay in minutes to find an angle it will be wrong

  deltaX = (waypointLatDeg - latitudeDeg)*DEGREE_TO_MINUTE + (waypointLatMin - latitudeMin); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
  deltaY = (waypointLongDeg - longitudeDeg)*DEGREE_TO_MINUTE + (waypointLongMin - longitudeMin); //y is the east/west coordinate, + in the east direction
   
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
 Serial.print(latitudeDeg);
 Serial.print(","); 
 Serial.print(latitudeMin);
 Serial.print(",");
 Serial.print(longitudeDeg); //latitude and longitude of boat's location, split into more precise degrees and minutes, to fit into a float
 Serial.print(",");
 Serial.print(longitudeMin);
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
int stayInDownwindCorridor(int corridorHalfWidth, double waypointLatDeg, double waypointLatMin, double waypointLongDeg, double waypointLongMin){
//calculate whether we're still inside the downwind corridor of the mark; if not, tacks if necessary
// corridorHalfWidth is in meters
  
  int theta;
  float distance, hypotenuse;
  
  //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for);
 
  // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
  theta = getWaypointDirn( waypointLatDeg,  waypointLatMin, waypointLongDeg, waypointLongMin) - getWindDirn();  
  
  // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
  hypotenuse = GPSdistance(latitudeDeg, latitudeMin, longitudeDeg, longitudeMin, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin);//latitude is Y, longitude X for waypoints
  
  //GPSconv(latitude, longitude, waypointX, waypointY); //this function might not work, nader wrote it
  
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
    sumLatMin+= stationCornersLatMin[i];
    sumLonMin+= stationCornersLonMin[i];
  }
  *centreLatMin = sumLatMin/4;
  *centreLonMin = sumLonMin/4;
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
    stationWaypointsLatMin[i] = deltaLat + centreLatMin;
    stationWaypointsLonMin[i] = deltaLon + centreLonMin;
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
  waypointLatDeg =  stationWaypointsLatDeg;
  waypointLongDeg = stationWaypointsLonDeg;    
  
  waypoint = 2; //start by sailing to the downwind waypoint  
  
  startTime = millis();//record the starting clock time
  waypointTime = startTime;
  
  //timed 5 minute loop of going through the waypoints
  do {
      //latitude
      waypointLatMin =  stationWaypointsLatMin[waypoint];
      //longitude
      waypointLongMin =  stationWaypointsLonMin[waypoint];   
          
      distanceToWaypoint = GPSdistance(latitudeDeg, latitudeMin, longitudeDeg, longitudeMin, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin);//returns in meters

      while (distanceToWaypoint > MARK_DISTANCE && !timesUp)
      {           
        //send data to xbee for reporting purposes
        relayData();
        Serial.println(distanceToWaypoint);
        
        //set rudder and sails 
        error = sensorData(BUFF_MAX,'c');     
        error = sensorData(BUFF_MAX,'w');            
        error = sailToWaypoint(waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin); //sets the rudder, stays in corridor if sailing upwind       
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
        
        distanceToWaypoint = GPSdistance(latitudeDeg, latitudeMin, longitudeDeg, longitudeMin, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin);//returns in meters
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
  
}

void sailCourse(){
  //sail the race course 
  
  int error; 

  //waypoint variables
  int numWaypoints = 1;//total number of waypoints
  int waypoint; //waypoint counter, advances when we reach each waypoint
  int distanceToWaypoint;//the boat's distance to the present waypoint
      
  //Present waypoint variables
  double waypointLatDeg;//Present waypoint's latitude (x) degrees (north/south, +'ve is north) coordinate
  double waypointLatMin;//Present waypoint's latitude (x) minutes (north/south, +'ve is north) coordinate
  double waypointLongDeg;//Present waypoint's longitude (y) degrees (east/west, +'ve is east) coordinate
  double waypointLongMin;//Present waypoint's longitude (y) minutes (east/west, +'ve is east) coordinate

 //Known Waypoints:
 //GPGLL,4413.6803,N,07629.5175,W,232409,A,A*58 south lamp post
 //GPGLL,4413.6927,N,07629.5351,W,230533,A,A*51 middle tree by door
 //GPGLL,4413.7067,N,07629.4847,W,232037,A,A*53 NW corner of the dirt pit by white house
 //GPGLL,4413.7139,N,07629.5007,W,231721,A,A*57 middle lamp post
 //GPGLL,4413.7207,N,07629.5247,W,231234,A,A*5E at the top of the parking lot/bay ramp, where the edging and sidewalk end


  //Global variable setup (put this in setup() function), and as a manu option to input waypoints

  //set the waypoint to the south lamp post
  courseWaypointsLatDeg[0] = 44;//List of waypoint's latitude (x) degrees (north/south, +'ve is north) coordinate
  courseWaypointsLatMin[0] = 13.6803;//List of waypoint's latitude (x) minutes (north/south, +'ve is north) coordinate
  courseWaypointsLonDeg[0] = -76;//List of waypoint's longitude (y) degrees (east/west, +'ve is east) coordinate
  courseWaypointsLonMin[0] = -29.5175;//List of waypoint's longitude (y) minutes (east/west, +'ve is east) coordinate

  //set our initial position to the tree by the door 
  latitudeDeg = 44;
  latitudeMin = 13.6927;
  longitudeDeg = -76;
  longitudeMin = -29.5351;
 
  
 //get wind and compass data before starting to move

  error = sensorData(BUFF_MAX,'c');  
  error = sensorData(BUFF_MAX,'w');  
  
  for (waypoint = 0; waypoint < numWaypoints; waypoint++){
    
    //transfer from the global list to our local single waypoint so that we can have simpler code; 
    //it might be better to just send in the "waypoint" variable and have each function reference the global array
    //or create a "GPScoordinate" structure to simplify things; right now there are 4 variables per location
    
    //latitude
    waypointLatDeg = courseWaypointsLatDeg[waypoint];
    waypointLatMin = courseWaypointsLatMin[waypoint];
    //longitude
    waypointLongDeg = courseWaypointsLonDeg[waypoint];
    waypointLongMin = courseWaypointsLonMin[waypoint];   
          
    distanceToWaypoint = GPSdistance(latitudeDeg, latitudeMin, longitudeDeg, longitudeMin, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin);//returns in meters

    while (distanceToWaypoint > MARK_DISTANCE){
      //sail testing code; this makes the pololu yellow light come on with flashing red
      
      //send data to xbee for reporting purposes
      relayData();
      Serial.println(distanceToWaypoint);
      
      //set rudder and sails    
      error = sailToWaypoint(waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin); //sets the rudder, stays in corridor if sailing upwind       
      delay(100);//give rudder time to adjust? this might not be necessary
      error = sailControl(); //sets the sails proprtional to wind direction only; should also check latest heel angle from compass; this isnt turning a motor    
      delay(100); //poolu crashes without this delay; maybe one command gets garbled with the next one?
      
      distanceToWaypoint = GPSdistance(latitudeDeg, latitudeMin, longitudeDeg, longitudeMin, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin);//returns in meters
    } 
  } //end loop through waypoints
  
  RC(1,1);  //back to RC mode
}

int straightSail(int waypointDirn){
 //this should be the generic straight sailing function; getWaypointDirn should return a desired compass direction, 
 //taking into account wind direction (not necc just the wayoint dirn); (or make another function to do this)

  //int waypointDirn=0; //direction we want to sail //moved outside straightSail
  int error=0; //error flag
  int timer=0; //loop timer placeholder; really we'll be timing?
  int directionError=0;
  int angle=0; 
   
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
    
    directionError = waypointDirn - heading_newest;//the roller-skate-boat turns opposite to it's angle
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

  return 0;
}

int sailToWaypoint(double waypointLatDeg, double waypointLatMin, double waypointLongDeg, double waypointLongMin){
  //must update sensor data before calling this
  
  //sets the rudder to sail towards the waypoint, either upwind or downwind
  // if outside of a downwind corridor, subfunction stayInDownwindCorridor will tack 
  //the subfunctions still use the global variables for the waypoint to sail to
    int waypointDirn, closeHauledDirection, windDirn =0;
    int distanceOutsideCorridor;
    int error = 0;
     //based on the waypoint direction and the wind direction, decide to sail upwind or straight to target
     //if straight to target, continually update the major waypoint direction, and call straightSail to target
     //if upwind, set an intermediate target and call sailStraight to target
     //use getCloseHauledDirn, getWaypointDirection, sailUpWind (with lots of mods) to sort this out 

      waypointDirn = getWaypointDirn(waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin); //get the next waypoint's compass bearing; must be positive 0-360 heading
      windDirn = getWindDirn();
      //check if the waypoint is upwind, ie between the wind's direction and the direction we can point the boat without going into irons
      if (between(waypointDirn, windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) //check if the waypoint's direction is between the wind and closehauled on either side (ie are we downwind?)
      {
        Serial.println("Downwind of waypoint");
       //can either turn up until this is not true, or find the heading and use the compass... uise the compass, wind sensor doesnt respond fast enough 

    //  if (wind_angl_newest > TACKING_ANGLE) //when sailing upwind this means that we're being inefficient; but is we're sailing closehauled shouldnt ever have to check this
    
        //this uses GPSconv, naders function which may not work:
        //I made up 10, the units are in meters
        distanceOutsideCorridor = stayInDownwindCorridor(10, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin); //checks if we're in the downwind corridor from the mark, and tacks if we aren't and arent heading towards it
        // if distanceOutsideCOrridor is non-zero, the boat is outside the corridor, stayInDownwindCorridor ensures it is on the tack that would bring it back into the corridor
        if (distanceOutsideCorridor != 0)
          Serial.println("Outside downwind corridor");
        
        closeHauledDirection = getCloseHauledDirn(); // heading we can point when closehauled on our current tack
        error = straightSail(closeHauledDirection);   //sail closehauled always when upwind

        
        //perhaps kill the program or switch to RC mode if we're way off course?
        if (abs(distanceOutsideCorridor) > 50) //made up 50, this is the distance from a point directly downwind of the waypoint in meters
          RC(1,1);  
      }  
      
      else  //not upwind
        error = straightSail(waypointDirn); //sail based on compass only in a given direction
        
      return (error);
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
      
 //test pin
// pinMode(13, OUTPUT);
// digitalWrite(13, HIGH);
        
 delay(10);          
  
  //initialize all counters/variables
  
  
  //Old Position variables, no longer used
//  latitude=0;//curent latitude
//  longitude=0; //Current longitude
//  //Two locations in the parking lot as a test waypoint
//  waypointY=44.24;//Present waypoint's latitude (north/south, +'ve is north) coordinate
//  waypointX=-76.48;//Present waypoint's longitude (east/west, +'ve is east) coordinate

  //current position from sensors
  latitudeDeg=0;//curent latitude
  latitudeMin=0;//curent latitude
  longitudeDeg=0; //Current longitude
  longitudeMin=0; //Current longitude
  
 
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
  int numWaypoints =1;
  int waypoint;
  int distanceToWaypoint;
  boolean downWind;
  int menuReturn;
  int GPSerrors =0;
  int compassErrors = 0;

  delay(100);//setup delay, avoid spamming the serial port
   
 //  connectSensors(); //waits for sensors to be connected; this isnt working, re-test
 

    //Sail using Menu
  if(Serial.available())
  {
      menuReturn = displayMenu();
         if(menuReturn != 0) //if menu returned 0, any updating happened in the menu function itself and we want the code to just keep doing what it was doing before (e.g. setting RC mode)
      {
        CurrentSelection = menuReturn;
      }  
  
  switch (CurrentSelection) {
  case 3:
  Serial.print("Sailing towards: ");
  Serial.print(StraightSailDirection, DEC);
  Serial.println(" degrees.");
  straightSail(StraightSailDirection);
  break;
        
  default:
  Serial.println("Invalid menu return. Press any key and enter to open the menu."); 
   } 
 }
 
  
  
  
  //April 2 sailcode:
//  sailCourse();
//  
//  while(1){
//    Serial.println("Program over.");
//    delay(1000);
//  } //end program
//

/*
//Testing code below here
*/
   
//compass sample mode testing code, parsed
      error = sensorData(BUFF_MAX, 'c'); //updates heading_newest
      Serial.println(heading_newest);
      delay(5000);


//compass sample mode testing code, unparsed        
//  while (Serial2.available()>0)
//   {
//     input = Serial2.read();
//     Serial.print(input);
//   }
//   Serial2.println("$PTNT,HTM*63");
//   delay(1000);
  

//////compass run mode testing code, unparsed
////  while (Serial2.available()>0)
////   {
////     input = Serial2.read();
////     Serial.print(input);
////   }
////  delay(20);
//     
//////wind run mode testing code, unparsed (note* this doesnt need the arduino to be switched to xbee and the onboard power, works with arduino USB powered)
//  while (Serial3.available()>0)
//   {
//     input = Serial3.read();
//     Serial.print(input);
//   }        
//   delay(250);
     
  
////wind sample mode testing code, parsed; this is working for the wing angle and speed (tested by blowing on it)
//      error = sensorData(BUFF_MAX, 'w'); //updates heading_newest
//      Serial.println("Wind angle is: ");
//      Serial.println(wind_angl_newest);
//      Serial3.println("$PAMTC,EN,ALL,0*1D"); //disable all commands; this doesnt seem to have worked
//      Serial3.println("$PAMTX*50");//temporarily disable commands until power cycles; not working
//      delay(100);  


////wind based sail control testing code
//  RC(0,0);// autonomous sail control
//  
//  for(i = 0; i < 10; i++)
//  {
//      Serial.println("Wind angle is: ");
//      Serial.println(wind_angl_newest);
//      error = setSails();
//      delay(100);  
//  }

  

  
//MUX with motor testing  ; with present hardware setup, this makes rudder turn from Pololu and then jitter (no RC controller turned on)
// the sails just trill and occasionally seems to mirror rudder with rudder plugged in; with rudder unplugged they jitter and low-pitched jittery-beep
// this is likely due to the fact that the sail pin (11) seems to be broken (or that MUX channel is broken on the other side), it ranges .8to3.2V)
// full back, middle, front with this code -> front=sails in = negative, back=sails out = positive;
// if motor range is small, battery is probably dead (7.2V non-regulated)
// this MUX switching code is working - > mux working now to switch RC to autonomous; RC mode very noisy, perhaps need to replace antenna/transmitter
//
// RC(0,0);//total autonomous
// digitalWrite(noDataLED,LOW);
// Serial.println("0 degrees");
// setrudder(-15);
// setSails(-15);
//  Serial.println("-15 degrees");
// delay(1000);
//  Serial.println("-15 degrees");
// setSails(15);
// setrudder(15);
//  Serial.println("15 degrees");
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
//  Serial.println("-45 degrees");
//  setrudder(-45);
// setSails(-45);
//  Serial.println("-45 degrees");
// delay(1000);
//  Serial.println("45 degrees");
// setSails(45);
// setrudder(45);
// Serial.println("45 degrees");
// delay(1000);
//  Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
// Serial.println("0 degrees");
//  
// RC(1,1);//RC steering 
// digitalWrite(noDataLED,HIGH);
//  Serial.println("0 degrees");
// setrudder(-15);
// setSails(-15);
//  Serial.println("-15 degrees");
// delay(1000);
//  Serial.println("-15 degrees");
// setSails(15);
// setrudder(15);
//  Serial.println("15 degrees");
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
//  Serial.println("-45 degrees");
//  setrudder(-45);
// setSails(-45);
//  Serial.println("-45 degrees");
// delay(1000);
//  Serial.println("45 degrees");
// setSails(45);
// setrudder(45);
// Serial.println("45 degrees");
// delay(1000);
//  Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
// Serial.println("0 degrees");
//  
  
// simple compass, rudder control testing code
//    if (heading_newest < 180)//the roller-skate-boat turns opposite to it's angle
//        setrudder(-180);  //adjust rudder proportional; setrudder accepts -45 to +45
//    else
//        setrudder(180); //adjust rudder proportional; setrudder accepts -45 to +45     
//
//    delay(100);


//  Serial2.print("$PAMTC,");
     //this doesnt seem to be reacting to the serial data as expected - I believe the problem is largely due to how we're parsing and the lack of error checking
     //problem seemed to be the compass data; compass seems to be broken, see the chart taped to the whiteboard
  //Serial.print("\nNew heading");   
 // setrudder(heading_newest);
  //relayData();
 // delay(5000);
  //seems more responsive with 50 delay than 10 (perhaps servo doesnt have tim eto move, or serial data is being garbled with 10?)

//note: output is even MORE garbled over zigbee; interference? or buffers full?


//the below worked for about 10 iterations and then pololu started blinking red light - error?
//we need to monitor pololu's feedback to detect these error codes
//resetting the arduino fixed the problem

//Polulu Test Code
//Serial.print("\n 320 degrees");   
//setrudder(320);
//setSails(15);
////  arduinoServo(30);
//delay(2000); 
//  Serial.print("\n10 degrees");   
//setrudder(10);
//setSails(-15);
//
//delay(2000);



//error-checking navigation code:  

//  //set present latitude and longitude to the middle tree
//  error = Parser("$GPGLL,4413.6939,N,07629.5335,W,230544,A,A*5C"); 
//    
//  //set the waypoint to the corner of the dirt pit
//  //latitude
//  waypointLatDeg = 44;
//  waypointLatMin = 13.7067;
//  //longitude
//  waypointLongDeg = -76;
//  waypointLongMin = -29.4847;
//  
//  //set wind direction
//  error = Parser("$WIMWV,40.0,R,0.5,N,A*26");
//   
//  //leave compass direction at it's 0 default
//  heading_newest=0;//heading relative to true north, newest
//  
//  //find the distance to the waypoint
//  distanceToWaypoint = GPSdistance(latitudeDeg, latitudeMin, longitudeDeg, longitudeMin, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin);
//  Serial.print("Waypoint distance: ");
//  Serial.println(distanceToWaypoint);
//  
//  //find the direction to the waypoint
//  waypointDirn = getWaypointDirn(); //get the next waypoint's compass bearing; must be positive 0-360 heading
//  Serial.print("Waypoint dirn: ");
//  Serial.println(waypointDirn);
//  
//  //find the wind direction
//  windDirn = getWindDirn();
//  Serial.print("Wind dirn: ");
//  Serial.println(windDirn);
//  
//  //closehauled dirn
//  closeHauledDirection = getCloseHauledDirn();
//  Serial.print("Closehauled dirn: ");
//  Serial.println(closeHauledDirection);
//  
//  //check if we're downwind
//  if(between(waypointDirn, windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) //check if the waypoint's direction is between the wind and closehauled on either side
//    Serial.println("Downwind");
//  else  
//    Serial.println("not downwind");
//  
//  //check downwind corridor  
//  distanceOutsideCorridor = stayInDownwindCorridor(10);
//  Serial.print("Corridor distance: ");
//  Serial.println(distanceOutsideCorridor);    
    
}

