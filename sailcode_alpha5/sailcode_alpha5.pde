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

//#include <math.h> doesnt work

#include <SoftwareSerial.h> 
//for pololu non-buffering serial channel
#include <String.h> //for parsing - necessary?
#include <stdio.h> //for parsing - necessary?


#include <Servo.h>  //for arduino generating PWM to run a servo
 

// Global variables and constants
////////////////////////////////////////////////



//Constants

//Boat parameter constants
#define TACKING_ANGLE 30 //the highest angle we can point
//Navigation constants
#define MARK_DISTANCE 1 //not sure what the units on this would be; the distance we have to be to a mark before moving to the next one
//serial data constants
#define BUFF_MAX 511 // serial buffer length, set in HardwareSerial.cpp in arduino0022/hardware/arduino/cores/arduino
//Calculation constantes
//#define PI 3.14159265358979323846
#define d2r (PI / 180.0)
#define EARTHRAD 6367515 // for long trips only
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
float latitude; //Curent latitude
float longitude; //Current longitude
float GPSX; //Target X coordinate
float GPSY; //Target Y coordinate
float prevGPSX; //previous Target X coordinate
float prevGPSY; //previous Target Y coordinate
float waypointX;//Present waypoint's X (north/south, +'ve is north) coordinate
float waypointY;//Present waypoint's Y (east/west, +'ve is east) coordinate

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

boolean tackSide=0;//tacking to left or right
int port1;//what is this?
char total[10000];//cb buffer variable


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
						//stayInMenu = false;
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
//LEVEL 4 Functions
////////////////////////////////////////////////////

int DataValid(char *val) 
{
	if (val[0] != '$') 
	{
		Serial.println("wrong data\n");
		return 1;
	}
	return 0;
	//Check the end of the string
}

int Parser(char *val) 
{
  //I changed parser to no longer sum up the data
  
//parses a string of NMEA wind sensor data
// this also changes the global variables depending on the data; this would be much better split into separate functions
// presently, the changes to global variables are not conducive to a moving average; they CAN be used for an average, which could perhaps go into a moving average

// This parser breaks when there are blanks in the data ie $PTNTHTM,,N,-2.4,N,10.7,N,59.1,3844*27


  char *str; //dummy string to absorb the type of data, as %5s, value not used; I guess strtok automatically calls realloc?
  char cp[100]; //temporary array for parsing, a copy of val

  //GPSGLL gps latitude and longitude data
  double grades, frac; //the integer and fractional part of Degrees.minutes
  float lat_deg_nmea, lon_deg_nmea; // latitude and longitude in ddmm.mmmm degrees minutes format
  double lat; //latitude read from the string converted to decimal dd.mmmm
  double lon; //longitude read from the string converted to decimal dd.mmmm
  char lat_dir, lon_dir; //N,S,E,W direction character
  int hms; //the time stamp on GPS strings; hours minutes seconds
  char valid;//checks for the 'V' in GPS data strings (it's A if its invalid)
  char *lat_deg_nmea_string, *lon_deg_nmea_string, *hms_string; //strings to use during tokenizing

  //HCHDG compass data
  float head_deg, dev_deg, var_deg;
  char dev_dir, var_dir;
  char *head_deg_string, *dev_deg_string, *var_deg_string;//strings to use during tokenizing

  //WIMWV wind data
  float wind_ang, wind_vel;
  char wind_ref, speed_unit; //wind_ref R = relative to boats direction; speed_unit N = knots
  char *wind_ang_string, *wind_vel_string;//strings to use during tokenizing
  
  //GPVTG boat speed data
  float cov_true, cov_meg, sov_knot, sov_kmh; //cov_true is the actual course the boat has been travelling in, relative to true north; 
  //cov_meg is relative to magnetic north; 
  //sov_knot is speed in knots; 
 //  sov_kmh is speed in kmh;
  char ref_true, ref_meg, ref_knot, ref_kmh;  
  //ref_meg = M this is relative to magnetic north; 
  //ref_true = T this is relative to true north; ref_knot is always N to indicate knots; 
  //ref_kmh is always K to indicate kilometers
  char *cov_true_string, *cov_meg_string, *sov_knot_string, *sov_kmh_string; // strings to use during tokenizing
  
    //PTNTHTM data for heading and tilt
  float head2_deg, pitch_deg, roll_deg; //head2_deg is the true heading; pitch_deg the pitch referenced to.. ?; roll_deg the roll referenced to...?
  char head_st, pitch_st, roll_st; //these are a status indicator; see compass manual on dropbox
  char *head2_string; //sscanf, strtok doesnt support directly scanning into floats; hence we are scanning into strings and then using atof to convert to float
  char *roll_string;
  char *pitch_string;
    
  if (DataValid(val) == 0){ //check if the data is valid - ideally we'd do this by checking the checksum
    //Serial.print("Parses says: valid string, val (full string) is:\n");
  }
  else { Serial.println("Datavalid fail"); digitalWrite(twoCommasLED, HIGH); return 1; } // if data isnt valid, dont try to parse it and throw error code

 // Serial.println(val);//echo what we're about to parse

  strcpy(cp, val); //make a backup copy of the data to parse; if not copied val gets corrupted when tokenized
  str = strtok(cp, ","); //find location of first ',', and copy everything before it into str1; returns a pointer to a character array. this will be the type of command, should return $xxxxx identifier

 // Serial.print("command portion from cp strtok is: ");
 // Serial.println(str);
  
  //now we know what type of command we're dealing with and can parse it - wooooo
  
  
  //GPS String
  if (strcmp(str, "$GPGLL") == 0) 
  {
   // sscanf(val, "$%5s,%f,%c,%f,%c,%d,%c,", str, &lat_deg_nmea, &lat_dir, &lon_deg_nmea, &lon_dir, &hms, &valid);
   //"$GPGLL,4413.7075,N,07629.5199,W,192945,A,A*5E"
   
   //THIS ISNT WORKING because on arduino, floats only have 6 to 7 points of accuracy, same for doubles, so we're losing precision
   //perhaps try splitting at the decimal point, subtracting the known degrees (huge accuracy, we wont travel a degree) to regain 2 extra digits
   /* this is the output:
   $GPGLL4413.71
  0.14
  44.00
  7629.52
  0.30
  76.00
  44.23
  -76.49

   */
   
    Serial.print(val); //test for what GPS data is being returned
    
    lat_deg_nmea_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
    lat_dir = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok. 
          // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
    lon_deg_nmea_string = strtok(NULL, ",");
    lon_dir = (char) * strtok(NULL, ",");
    hms_string = strtok(NULL, ",");
    
    lat_deg_nmea = atof(lat_deg_nmea_string);
    lon_deg_nmea = atof(lon_deg_nmea_string);
    hms = atoi(hms_string); //hms is converted to integer, not float

     //check 'valid' before continuing; throw error code if not valid -> do this properly
  //  if (valid == 'V')
  //    return 1; 

    //     lat_deg is in the format ddmm.mmmm 


//testing gpgll with prints
    Serial.println(lat_deg_nmea);//this should have 4 decimals, only printing 2
    //this first moves the decimal so that the latitude degrees is the whole part of the number
    //then modf returns the integer portion to 'grades' and the fractional (minutes) to 'frac'.
    frac = modf(lat_deg_nmea / 100.0, &grades); 
    Serial.println(frac);
    Serial.println(grades);
    // Frac is out of 60, not 100, since it's in minutes; so convert to a normal decimal
    lat = (double) (grades + frac * 100.0 / 60.0) * (lat_dir == 'S' ? -1.0    : 1.0); // change the sign of latitude based on if it's north/south


    Serial.println(lon_deg_nmea);
    //do the same for longitude
    frac = modf(lon_deg_nmea / 100.0, &grades);
    Serial.println(frac);
    Serial.println(grades);
    lon = (double) (grades + frac * 100.0 / 60.0) * (lon_dir == 'W' ? -1.0 : 1.0);

    /*print("The string: %s\n", str);
     printf("Lat_dir nmea: %f\n", lat_deg_nmea);
     printf("Lat: %f\n", lon1);
     printf("Lat_dir: %c\n", lon_dir);*/

    latitude = lat; //cb! dont we want a moving average? 
    longitude = lon;        
  }

  //Wind sensor compass
  if (strcmp(str, "$HCHDG") == 0) 
  {
   // sscanf(val, "$%5s,%f,%f,%c,%f,%c,", str, &head_deg, &dev_deg, &dev_dir, &var_deg, &var_dir);

    /*                printf("The string: %s\n", str);
     printf("Heading: %f\n", head_deg);
     printf("Dev: %f\n", dev_deg);
     printf("Dev dir: %c\n", dev_dir);
     printf("Var: %f\n", var_deg);
     printf("Var dir: %c\n", var_dir);*/
  
    //parse
    head_deg_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
    dev_deg_string = strtok(NULL, ",");
    dev_dir = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok. 
          // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
    var_deg_string = strtok(NULL, ",");
    var_dir = (char) * strtok(NULL, ",");
    
    //convert to floats from strings
    head_deg = atof(head_deg_string); 
    dev_deg = atof(dev_deg_string);
    var_deg = atof(var_deg_string); 

    //process
    heading = head_deg; //cb! dont we want a moving average?
    deviation = dev_deg; //what is this in compass terminology? I think we should be taking dev_dir into account
    variance = var_deg; //what is this in compass terminology? I think we should be taking var_dir into account
  }

  //Wind speed and wind direction
  //when parsing this, need to verify that wind is strong enough to give a reading on the sensor
  if (strcmp(str, "$WIMWV") == 0) 
  {
    //sscanf(val, "$%5s,%f,%c,%f,%c,%c,", str, &wind_ang, &wind_ref,&wind_vel, &speed_unit, &valid);
    //    printf("Wing angle: %f\n", wind_ang);
    
    wind_ang_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
    wind_ref = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok. 
          // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
    wind_vel_string = strtok(NULL, ",");
    speed_unit = (char) * strtok(NULL, ",");
        
    //convert to floats from strings
    wind_ang = atof(wind_ang_string); 
    wind_vel = atof(wind_vel_string);
    
    //check 'valid' before continuing; throw error code if not valid
    //if (valid == 'V')
     // return 1; 

    //wind_ref for the PB100 is always R? (relative to boat)
    //speed unit for the PB100 is always N? (knots)
    wind_angl = wind_ang; //cb! dont we want a moving average?
    wind_velocity = wind_vel;
    
    wind_angl_newest = wind_ang; //for testing purposes, save the newest wind angle
  }

  //Boat's speed
  if (strcmp(str, "$GPVTG") == 0) 
  {
    //Add sscanf
  //  sscanf(val, "$%5s,%f,%c,%f,%c,%f,%c,%f,%c", str, &cov_true, &ref_true,&cov_meg, &ref_meg, &sov_knot, &ref_knot, &sov_kmh, &ref_kmh,&valid);
    //    printf("True course made good over ground: %f\n", sov_kmh);


    //parse
    cov_true_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string    
    ref_true = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok. 
          // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
    cov_meg_string = strtok(NULL, ",");
    ref_meg = (char) * strtok(NULL, ",");
    sov_knot_string = strtok(NULL, ",");
    ref_knot = (char) * strtok(NULL, ",");
    sov_kmh_string = strtok(NULL, ",");
    ref_kmh = (char) * strtok(NULL, ",");
    
    //convert to floats from strings
    cov_true = atof(cov_true_string); 
    cov_meg = atof(cov_meg_string);
    sov_knot = atof(sov_knot_string); 
    sov_kmh = atof(sov_kmh_string); 

    //check 'valid' before continuing; throw error code if not valid
    //if (valid == 'V')
     // return 1; 

    //cov_true is the actual course the boat has been travelling in; ref_true = T this is relative to true north
    //meg_true is the actual course the boat has been travelling in; ref_true = M this is relative to magnetic north
    //ref_knot is always N to indicate knots
    //ref_kmh is always K to indicate kilometers

    bspeed = sov_kmh; //actual speed not the average
    bspeedk = sov_knot;
	
   //bspeed += sov_kmh; //cb! dont we want a moving average?
    //bspeedk += sov_knot;
    //GPVTG++;
  }
 
 
  //Compass
  if (strcmp(str, "$PTNTHTM") == 0) 
  { //"$PTNTHTM,285.2,N,-2.4,N,10.7,N,59.1,3844*27" is actual data
    // sscanf(val, "$%7s,%s,%c,%s,%c,%s,%c,%c", str1, &head2_string, &head_st, &pitch_string, &pitch_st, &roll_string, &roll_st, &valid);
    /*printf("Heading is : %f\n", head2_deg);
     printf("String is : %s\n", str);
     
     "The %s format in sscanf is defined to read a string until it encounters white space.  If you want it to stop on a comma, you should use the %[^,] format." - some forum
     */

     //need a way to parse commands with blanks in their data ie $PTNTHTM,,N,-2.4,N,10.7,N,59.1,3844*27 , which is what the compass returns when its tipped over too much; right now that breaks this parsing
    digitalWrite(goodCompassDataLED, HIGH);
    
    head2_string = strtok(NULL, ","); // should return 285.2; this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
    head_st = (char) * strtok(NULL, ","); //head_st is only a (char) not a array of chars. It's value is only N or S. Hence, head_st = typecast(char) dereferenced strtok. 
          // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
    pitch_string = strtok(NULL, ",");
    pitch_st = (char) * strtok(NULL, ",");
    roll_string = strtok(NULL, ",");
    roll_st = (char) * strtok(NULL, ",");
   // valid = (char) * strtok(NULL, ","); //this was a temp data checking; our sensor doesnt behave like this
    
    head2_deg = atof(head2_string);
    roll_deg = atof(roll_string);
    pitch_deg = atof(pitch_string);

// Diagnostic printing

  /*  Serial.print("Str command portion strtok1 from cp: ");
    Serial.println(str);
    Serial.print("Heading portion strtok2from cp: ");
    Serial.println(head2_string);
    Serial.print("Direction of heading: ");
    Serial.println(head_st);
    Serial.println(pitch_string);
    Serial.println(pitch_st);
    Serial.println(roll_string);
    Serial.println(roll_st);      
   // Serial.println(valid);

    //... and print their decimal conversions!
    Serial.println("\n");      
    Serial.println(head2_deg);
    Serial.println(pitch_deg);      
    Serial.println(roll_deg);
    Serial.println("\n");
    */
  //   end diagnostic printing 

    //check 'valid' before continuing; throw error code if not valid -> see compass manual on dropbox, this isnt actually correct
   /* if (valid == 'V') //we need to check the checksum, not the V code (doesnt exist in our data); also check status codes of each variable that returns a status code; but for now no error checking
      {
      Serial.println("Compass reports invalid data!");
      return 1; 
      }
*/
    if (head2_deg < 0)
      head2_deg += 360;
    else if (head2_deg > 360)
      head2_deg -= 360;

    //data isnt valid if the boat is heeled over too much, so discard it if pitch is more than 45 degrees <- parser breaks before this, as the compass doesnt return a heading when its tipped
    if (abs(pitch_deg) > 45) 
    {
      Serial.println("OMG WERE FALLING OVER");
      head2_deg = 0;
      pitch_deg = 0;
      roll_deg = 0;
    }
    headingc = head2_deg; //cb! dont we want a moving average?
    pitch = pitch_deg;
    roll = roll_deg;
    
    heading_newest = head2_deg;//also track the newest heading
  }

  return 0;
	
}


float degreesToRadians(int angle){
  return PI*angle/180.0;
}


int radiansToDegrees(float angle){
  return 180*angle/PI;
}

boolean between(int angle, int a, int b){
  //figures out if angle is between a and b on a circular scale
 
 //first ensure angles are 0 to 360 normalized
 while (angle < 0)
        angle+= 360;
 while (angle >= 360)
        angle-= 360;

  while (a < 0)
        a+= 360;
  while (a >= 360)
        a-= 360;
  
  while (b < 0)
        b+= 360;
  while (b >= 360)
        b-= 360;        
   

  //now check which boundary condition is higher and then determine if angle is between a and b, either on the inside or outside
   if (a < b){ //b is bigger
     if ((b - a) < 180) //check if the range numerically between a and b is smaller than the range numerically outside of a and b
        return a <= angle && angle <= b; //small angle is between a and b
     else //angle either has to be bigger than both bounds (b to 360) or smaller than both bounds (a to 0)
        return (a <= angle && b <= angle) || (angle <= a && angle <=b); //small angle is outside a and b, either on the left or right side of zero
   }
   else { //a is the bigger number, same as above with a switched for b
     if ((a - b) < 180) 
        return b <= angle && angle <= a;
     else
        return (b <= angle && a <= angle) || (angle <= b && angle <=a);   
   }
}

//from reliable serial data merge
//adapted from http://forum.sparkfun.com/viewtopic.php?f=17&t=9570
//(all of our checksums have numbers or capital letters so no worries about the UTIL_TOUPPER)
char convertASCIItoHex (const char ch)
{
       if(ch >= '0' && ch <= '9')
       // if it's an ASCII number 
       {
         return (ch - '0'); //subtract ASCII 0 value to get the hex value
       }
       else
       // if its a letter (assumed upper case)
       {
         return ((ch - 'A') + 10);//subtract ASCII A value then add 10 to get the hex value
       }
}

/////////////////////////////////////////////////////
//LEVEL 3 Functions
////////////////////////////////////////////////////

//arduino servo library
void arduinoServo(int pos){
      myservo.write(pos);              // tell servo to go to position in variable 'pos' 
}


//Pololu servo board test in Mini SSC II mode
//(mode jumper innplace on Pololu board)

//Servo_command receieves a servo number (acceptable range: 00-FE) and a position (acceptable range: 00-FE)
void servo_command(int whichservo, int position, byte longRange)
{
 servo_ser.print(0xFF, BYTE); //servo control board sync
 //Plolou documentation is wrong on servo numbers in MiniSSCII
 servo_ser.print(whichservo+(longRange*8), BYTE); //servo number, 180 mode
 servo_ser.print(position, BYTE); //servo position
}


//Accept a angle range to turn the rudder to 
//float ang acceptable values: 90 degree total range (emulation); -45 = left; +45 = right; 0 = centre 
// this direction (-'ve angles are LEFT turns) has been verified on the roller skate boat, with the wheel at the back emulating the rudder properly
// except the servo is upside down; so on the real boat, -'ve angles are RIGHT turns
void setrudder(float ang)
{
//fill this in with the code to interface with pololu 
 
  int servo_num =1;
  int pos; //position ("position" was highlighted as a special name?)
 // Serial.println("Controlling motors");
  
//check input, and change is appropriate
  if (ang > 45)
    ang = 45;
  else if (ang < -45)
    ang = -45;
  
  pos = (ang + 45) * 254.0 / 90.0;//convert from 180 degree range, -90 to +90 angle to a 0 to 256 maximum position range
  
  servo_command(servo_num,pos,0);
  //delay(10);
}

void setSails(float ang)
//this could make more sense conceptually for sails if it mapped 0 to 90 rather than -45 to +45
// presently the working range on the smartwinch (april 3) only respoings to -30 to +30 angles
{
  int servo_num =2;
  int pos; //position ("position" was highlighted as a special name?)
 // Serial.println("Controlling motors");
  
//check input, and change is appropriate
  if (ang > 45)
    ang = 45;
  else if (ang < -45)
    ang = -45;
  
  pos = (ang + 45) * 254.0 / 90.0;//convert from 180 (90?) degree range, -90 to +90 (-45 to +45?) angle to a 0 to 256 maximum position range
  
  servo_command(servo_num,pos,0); //0 tells it to only turn short range

}

// 'c' = compass
// 'w' = wind sensor
// sensorData replaces Compass() and Wind() with one function. This is not complete; the rollover array (at least) needs to be split into two separate arrays.
int sensorData(int bufferLength, char device) 
{ //compass connects to serial2
  int dataAvailable; // how many bytes are available on the serial port
  char array[LONGEST_NMEA];//array to hold data from serial port before parsing; 2* longest might be too long and inefficient

  char checksum; //computed checksum for the NMEA data between $ and *
  char endCheckSum; //the HEX checksum that is added by the NMEA device
  int xorState; //holds the XOR  state (whether to use the next data in the xor checksum) from global
  int j; //j is a counter for the number of bytes which have been stored but not parsed yet

  int i; //counter

  int error;//error flag for parser
  bool twoCommasPresent = false; //Alright, this flag will be set if the data being read in has two commas in a row. This is needed since
  	  	  	  	  	  	  	  	 //it will crash the program as strtok will have trouble with the delimiters later.

  Serial.println(device); //display that data is being gathered from a device

   // delay(5000);
   if(device == 'c')
   dataAvailable = Serial2.available(); //check how many bytes are in the buffer
   else if (device == 'w')
   dataAvailable = Serial3.available(); //check how many bytes are in the buffer
 
 if(!dataAvailable){
    noData = 1;//set a global flag that there's no data in the buffer; either the loop is running too fast or theres something broken
    Serial.println("No data available. ");
    digitalWrite(noDataLED,HIGH);//turn on error indicator LED to warn about no data present
    digitalWrite(goodCompassDataLED, LOW); //data isnt good if it isnt there
  } 
  else {
    digitalWrite(oldDataLED,LOW); //there is data, buffer isnt full, so turn off error indicator light
    digitalWrite(noDataLED,LOW);//turn off error indicator LED to warn about no data
    
    if (dataAvailable > bufferLength) { //the buffer has filled up; the data is likely corrupt;
    //may need to reduce this number, as the buffer will still fill up as we read out data and dont want it to wraparound between here an
    //when we get the data out
    
    //flushing data is probably not the best; the data will not be corrupt since the port blocks, it will justbe old, so accept it.
//      Serial2.flush(); //clear the serial buffer
//    extraWindData = 0; //'clear' the extra data buffer, because any data wrapping around will be destroyed by clearing the buffer
//    savedChecksum=0;//clear the saved XOR value
//    savedXorState=0;//clear the saved XORstate value
//    lostData = 1;//set a global flag to indicate that the loop isnt running fast enough to keep ahead of the data

        Serial.println("You filled the buffer, data old. ");
        digitalWrite(oldDataLED,HIGH);//turn on error indicator LED to warn about old data
        digitalWrite(goodCompassDataLED, LOW); //data is old, so not so goood
       }

    
    //first copy all the leftover data into array from the buffer; !!! this has to depend on if it's wind or compass, and different arrays for them!
    for (i = 0; i < extraWindData; i++){
      array[i] = extraWindDataArray[i]; //the extraWindData array was created the last time the buffer was emptied
      //probably actually don't need the second global array
    }
    
    //now continue filling array from the serial port
    checksum = savedChecksum;//set the xor error checksum to the saved value (only xor if between $ and *)
    xorState = savedXorState;//set the XOR state (whether to use the next data in the xor checksum) from global
    j = extraWindData; //j is a counter for the number of bytes which have been stored but not parsed yet

    extraWindData = 0;//reset for the next time, in case there isn't any extraData; could optimize these variable declarations
    savedChecksum = 0;//reset for the next time
    savedXorState = 0;//reset for next time

  //  Serial.print(array[0]);
   // Serial.print(array[1]);
   // Serial.print(array[2]);
    
    while(dataAvailable){//this loop empties the whole serial buffer, and parses every time there is a newline
    
     if(device == 'c')
      array[j] = Serial2.read();
      else  if(device == 'w')
      array[j] = Serial3.read();
      
      //Serial.print(array[j]);      
    	if (j > 0) {
    		if (array[j] == ',' && array[j-1] == ',') {
    			twoCommasPresent = true;
                        digitalWrite(goodCompassDataLED, LOW); //data is bad
                        digitalWrite(twoCommasLED,HIGH);//turn on error indicator LED to warn about old data                         
    		}
    	}

        if ((array[j] == '\n') && j > SHORTEST_NMEA) {//check the size of the array before bothering with the checksum
        //if you're not getting here and using serial monitor, make sure to select newline from the line ending dropdown near the baud rate
      //  Serial.print("read slash n, checksum is:  ");
        //compass strings seem to end with *<checksum>\r\n (carriage return, linefeed = 0x0D, 0x0A) so there's an extra j index between the two checksum values (j-3, j-2) and the current j.
        //just skip over it when checking the checksum
        endCheckSum = (convertASCIItoHex(array[j-3]) << 4) | convertASCIItoHex(array[j-2]); //calculate the checksum by converting from the ASCII to HEX 
     //   Serial.print(endCheckSum,HEX);
    //    Serial.print("  , checksum calculated is  ");
     //   Serial.println(checksum,HEX);
        //check the XOR before bothering to parse; if its ok, reset the xor and parse, reset j
        if (checksum==endCheckSum){
        //since hex values only take 4 bits, shift the more significant half to the left by 4 bits, the bitwise or it with the least significant half
        //then check if this value matches the calculated checksum (this part has been tested and should work)
        //  Serial.println("checksum good, parsing.");

          //Before parsing the valid string, check to see if the string contains two consecutive commas as indicated by the twoCommasPresent flag
          if (!twoCommasPresent) {
             // Serial.println(array[0]); //print first character (should be $)
              array[j+1] = '\0';//append the end of string character
              digitalWrite(twoCommasLED,LOW);//turn off error indicator LED to warn about old data
              error = Parser(array); //checksum was successful, so parse              
              //delay(500);  //trying to add a delay to account for the fact that the code works when print out all the elements of the array, but not when you don't. Seems sketchy.
          } else {
        	  twoCommasPresent = false;
                  Serial.println("Two commas present, didnt parse");
                  
        	  //This will be where we handle the presence of twoCommas, since it means that the boat is doing something strange
        	  //AKA tilted two far, bad compass data
        	  //GPS can't locate satellites, lots of commas, no values.
          }
          
          digitalWrite(checksumBadLED,LOW);//checksum was bad if on, its not bad anymore
          
        } else {
            Serial.println("checksum not good...");// else statement and this line are only here for testing
            digitalWrite(checksumBadLED,HIGH);//checksum was bad, turn on indicator
            digitalWrite(goodCompassDataLED, LOW); //data is bad
        }
        //regardless of checksum, reset array to beginning and reset checksum
        j = -1;//this will start writing over the old data, need -1 because we add to j
        //should be fine how we parse presently to have old data tagged on the end,
        //but watch out if we change how we parse
        checksum=0;//set the xor checksum back to zero
        twoCommasPresent = false; // there isnt any data, so reset the twoCommasPresent
      } //end if we're at the end of the data
      
      else if (array[j] == '$') {//if we encounter $ its the start of new data, so restart the data
    //  Serial.println("found a $, restarting...");
        //if its not in the 0 position there's been an error so get rid of the data and start a new line anyways
        array[0] = '$'; //move the $ to the first character
        j = 0;//start at the first byte to fill the array
        checksum=0;//set the xor checksum back to zero
        xorState = 1;//start the Xoring for the checksum once a new $ character is found
        twoCommasPresent = false; // there isnt any data, so reset the twoCommasPresent
      } 
      else if (j > LONGEST_NMEA){//if over the maximum data size, there's been corrupted data so just start at 0 and wait for $
      Serial.println("string too long, clearing some stuff");
        j = -1;//start at the first byte to fill the array
        // Serial2.flush(); //dont flush because there might be good data at the end
        checksum=0;//set the xor checksum back to zero
        xorState = 0;//only start the Xoring for the checksum once a new $ character is found, not here
        twoCommasPresent = false; // there isnt any data, so reset the twoCommasPresent
       
        digitalWrite(goodCompassDataLED,LOW);//turn on error indicator LED to warn about old data
      } 
      else if (array[j] == '*'){//if find a * within a reasonable length, stop XORing and wait for \n
        //could set a flag to stop XORing
      //  Serial.println("found a *");
        xorState = 0;
      } 
      else if (xorState) //for all other cases, xor unless it's after *
        checksum^=array[j];

      //removed this because it can be checked when a newline is encountered
      //else checksumFromNMEA=checksumFromNMEA*8+array[j];//something like this, keep shifting it up a character
     // Serial.println(array[j]/*,HEX*/);
      j++;
      
      //keep emptying buffer until it's empty; doing this should limit roll-over data
      if(device == 'c')
        dataAvailable = Serial2.available(); //check how many bytes are in the buffer
      else if (device == 'w')
        dataAvailable = Serial3.available(); //check how many bytes are in the buffer
    }//end loop, used to be from 0 to dataAvailable, now its while dataAvailable

//Jan 28, Christine:
//this is the part where the data is being messed up; extraWindDataArray isnt saving useful data, just 0's. Memory issue??? 
//Patch/fix: add in delay, so that partial data never wraps around and data is disgarded instead!

 //   Serial.print("end, 0 is:");
 //   Serial.println(array[0]);

    if ((j > 0) && (j < LONGEST_NMEA) && (twoCommasPresent==false)) { //this means that there was leftover data; set a flag and save the state globally

      for (i = 0; i < j; i++)
        extraWindDataArray[i] = array[i]; //copy the leftover data into the temp global array

      extraWindData = j;
      savedChecksum=checksum;
      savedXorState=xorState;
      // twoCommasPresent status isnt saved, since data isnt saved if it has two commas
      Serial.println("Stored extra data - ");
      digitalWrite(rolloverDataLED, HIGH); //indicates data rolled over, not fast enough
      
  //    Serial.print(extraWindData);
  //    Serial.print(",");
 //     Serial.print(extraWindDataArray[0],HEX);
 //     Serial.print(extraWindDataArray[1],HEX);
 //     Serial.print(extraWindDataArray[2],HEX);
  //    Serial.print(extraWindDataArray[3],HEX);      
    }
    else if (j > LONGEST_NMEA)
       digitalWrite(twoCommasLED, HIGH); //error light
    else 
      digitalWrite(rolloverDataLED, LOW); //indicates data didnt roll over
      
  }//end if theres data to parse
 

 
 /*  Serial.println(headingc);
   Serial.println(pitch);
   Serial.println(roll);
   Serial.println(PTNTHTM); */ 

//wind doesn't have a sample mode...
  if(device == 'c')
   Serial2.println("$PTNT,HTM*63"); //compass is in sample mode now; so request the next sample! :)
   
   return error;
}



int Wind() 
{	//fill in code to get data from the serial port if availabile
//wind connects to serial1
//replace this with finished compass code
 int error = 0;

      //Uncomment a section to test it parsing that kind of command! (will print the global variables)
  //GPS testing:
  error = Parser("$GPGLL,4413.7075,N,07629.5199,W,192945,A,A*5E"); // this is returning 44.23  and -76.49; off by 0.1, 0.2?
  Serial.println(latitude);//curent latitude
  Serial.println(longitude); //Current longitude
  //Serial.println(GPSX); //Target X coordinate
  //Serial.println(GPSY); //Target Y coordinate
  //Serial.println(prevGPSX); //previous Target X coordinate
  //Serial.println(prevGPSY); //previous Target Y coordinate


 /* Heading angle using wind sensor testing:
  int error = Parser("$HCHDG,204.4,0.0,E,12.6,W*67"); //returning 204.4, 0.0, 12.6 - > good!
  Serial.println(heading);//heading relative to true north
  Serial.println(deviation);//deviation relative to true north; do we use this in our calculations?
  Serial.println(variance);//variance relative to true north; do we use this in our calculations?
 */

 /* Boat's speed testing:
  int error = Parser("$GPVTG,225.1,T,237.7,M,0.1,N,0.2,K,A*25"); //returning 0.20, 0.10 -> good I think? (which parameters are these)
  Serial.println(bspeed); //Boat's speed in km/h
  Serial.println(bspeedk); //Boat's speed in knots
  */
  
 /* Wind data testing:
  int error = Parser("$WIMWV,251.4,R,3.1,N,A*23"); //returning 251.40, 3.10 -> good~
  Serial.println(wind_angl);//wind angle, (relative to boat or north?)
  Serial.println( wind_velocity);//wind velocity in knots
 */
 
  /* Compass testing
  // The 75.9 is the dip angle; 2618 is the magnetic field ; http://www.google.ca/url?sa=t&source=web&cd=3&ved=0CCEQFjAC&url=http%3A%2F%2Fgpsd.googlecode.com%2Ffiles%2Ftruenorth-reference.pdf&ei=jLn-TLaTAtvtnQeE1KGgCw&usg=AFQjCNFKgSCpWdeEoXWtQQiYeHJYXeXQ-g; http://lists.berlios.de/pipermail/gpsd-dev/2006-October/004558.html
  int error = Parser("$PTNTHTM,71.3,N,-0.4,N,-1.4,N,75.9,2618*03"); //returning 71.30, -0.40, -1.40 -> good!
   Serial.println(headingc);
   Serial.println(pitch);
   Serial.println(roll);
   Serial.println(PTNTHTM);
   */	return error;
}

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

int getWaypointDirn(){
// computes the compass heading to the waypoint based on the latest known position of the boat, stored in latitude and longitude
  int waypointHeading;//the heading to the waypoint from where we are
  float x, y; //the difference between the boats location and the waypoint in x and y
    
  x = (waypointX - longitude); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
  y = (waypointY - latitude); //y is the east/west coordinate, + in the east direction
  waypointHeading = radiansToDegrees(atan2(y, x)); // atan2 returns -pi to pi, taking account of which variables are positive to put in proper quadrant 
        
  if (waypointHeading < 0)
    waypointHeading += 360;
  else if (waypointHeading > 360)
    waypointHeading -= 360;
    
  return waypointHeading;

 // return (90); //for testing, waypoint is always 90 degrees
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
  //find the compass bearing the wind is coming from (ie if we were pointing this way, we'd be in irons)
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
 Serial.print(latitude); //Curent latitude
 Serial.print(",");
 Serial.print(longitude); //current longitude
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
int stayInDownwindCorridor(int corridorHalfWidth){
//calculate whether we're still inside the downwind corridor of the mark; if not, tacks if necessary
  
  int theta;
  float distance, hypotenuse;
  
  //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for);
 
  // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
  theta = getWaypointDirn() - getWindDirn();  
  
  // the hypotenuse is as long as the distance between the boat and the waypoint
  hypotenuse = GPSconv(latitude, longitude, waypointX, waypointY); //this function might not work, nader wrote it
  
  //opp = hyp * sin(theta)
  distance = hypotenuse * sin(degreesToRadians(theta));
  
  if (abs(distance) > corridorHalfWidth){ //we're outside
    //can use the sign of distance to determine if we should be on the left or right tack; this works because when we do sin, it takes care of wrapping around 0/360
    //a negative distance means that we are to the right of the corridor, waypoint is less than wind
    if ( (distance  < 0 && wind_angl_newest > 180) || (distance > 0 && wind_angl_newest < 180) ){
      //want newest_wind_angle < 180, ie wind coming from the right to left (starboard to port?) side of the boat when distance is negative; opposite when distance positive
         tack();     //tack function should not return until successful tack
    }
   
    return distance; //this should be positive or negative... depending on left or right side of corridor
  }
  else return 0;
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
  
  
  //Position variables
  latitude=0;//curent latitude
  longitude=0; //Current longitude
  GPSX=0; //Target X coordinate
  GPSY=0; //Target Y coordinate
  prevGPSX=0; //previous Target X coordinate
  prevGPSY=0; //previous Target Y coordinate
  //Two locations in the parking lot as a test waypoint
  waypointX=44.24;//Present waypoint's latitude (north/south, +'ve is north) coordinate
  waypointY=-76.48;//Present waypoint's longitude (east/west, +'ve is east) coordinate
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


  delay(200);
  
  setrudder(0);
  
  RC(0,0);// autonomous sail and rudder control
  
  delay(5000);
  
  
}

void loop()
{
  int error;
  int i;
  char input;
  int waypointDirn, closeHauledDirection, windDirn =0;
  int distanceOutsideCorridor;
  int numWaypoints =1;
  int waypoint;
  int distanceToWaypoint;
  int menuReturn;
  
  delay(1000);
  
  //errorchecking parse, float accuracy issue with gpgll
  //error = Wind();
  
    //Sail using Menu
  if(Serial.available())
  {
      menuReturn = displayMenu();
         if(menuReturn != 0) //if menu returned 0, any updating happened in the menu function itself and we want the code to just keep doing what it was doing before (e.g. setting RC mode)
      {
        CurrentSelection = menuReturn;
      }  
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
  
  
  
  
  
  //April 2 sailcode:
//
//  error = sensorData(BUFF_MAX,'w');
//  error = sensorData(BUFF_MAX,'c');  
//  
//  for (waypoint = 0; waypoint < numWaypoints; waypoint++){  
//    //  waypointX = waypointXArray[waypoint]; //4413.7075;//Present waypoint's latitude (north/south, +'ve is north) coordinate
//    //  waypointY = waypointYArray[waypoint]; //07629.5199;//Present waypoint's longitude (east/west, +'ve is east) coordinate
//    // error = sailToMark();
//    distanceToWaypoint = GPSconv(latitude, longitude, waypointX, waypointY);
//    while (distanceToWaypoint > MARK_DISTANCE){
//      //sail testing code; this makes the pololu yellow light come on with flashing red
//
//      relayData();//send data to xbee
//      Serial.println(distanceToWaypoint);
//     //pseudocode to decide to sail upwind, and how to handle it:
//   
//     //based on the waypoint direction and the wind direction, decide to sail upwind or straight to target
//     //if straight to target, continually update the major waypoint direction, and call straightSail to target
//     //if upwind, set an intermediate target and call sailStraight to target
//     //use getCloseHauledDirn, getWaypointDirection, sailUpWind (with lots of mods) to sort this out 
//
//      waypointDirn = getWaypointDirn(); //get the next waypoint's compass bearing; must be positive 0-360 heading
//      windDirn = getWindDirn();
//      //check if the waypoint is upwind, ie between the wind's direction and the direction we can point the boat without going into irons
//      if (between(waypointDirn, windDirn, windDirn + TACKING_ANGLE) || between(waypointDirn, windDirn, windDirn - TACKING_ANGLE)) //check if the waypoint's direction is between the wind and closehauled on either side
//      {
//       //can either turn up until this is not true, or find the heading and use the compass... uise the compass, wind sensor doesnt respond fast enough 
//        closeHauledDirection = getCloseHauledDirn(); // heading we can point when closehauled on our current tack
//        error = straightSail(closeHauledDirection);   //sail closehauled always when upwind
//    //  if (wind_angl_newest > TACKING_ANGLE) //when sailing upwind this means that we're being inefficient; but is we're sailing closehauled shouldnt ever have to check this
//    
//        //this uses GPSconv, naders function which may not work:
//        //I made up 10, I dont know what the units on the corridor halfwidth distance would be
//        distanceOutsideCorridor = stayInDownwindCorridor(10); //checks if we're in the downwind corridor from the mark, and tacks if we aren't and arent heading towards it
//    
//        //perhaps kill the program or switch to RC mode if we're way off course?
//        if (abs(distanceOutsideCorridor) > 50) //made up 50, i dont know what the units on distance would be
//          RC(1,1);  
//      }  
//      
//      else  //not upwind
//        error = straightSail(waypointDirn); //sail based on compass only in a given direction
//      
//      delay(100);
//    
//        error = sailControl(); //sets the sails proprtional to wind direction only; should also check latest heel angle from compass; this isnt turning a motor
//      
//      delay(100); //poolu crashes without this delay; maybe one command gets garbled with the next one?
//    } 
//  }
//  RC(1,1);  //back to RC mode
//  Serial.println("Close to waypoint, program over.");
//  while(1); //end program
/*
//Testing code below here
*/
   
//compass sample mode testing code, parsed
//      error = sensorData(BUFF_MAX, 'c'); //updates heading_newest
//      Serial.println(heading_newest);
//      delay(5000);


//compass sample mode testing code, unparsed        
//  while (Serial2.available()>0)
//   {
//     input = Serial2.read();
//     Serial.print(input);
//   }
//   Serial2.println("$PTNT,HTM*63");
//   delay(1000);
//  

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
////  arduinoServo(30);
//delay(2000); 
//  Serial.print("\n10 degrees");   
//setrudder(10);
//delay(2000);
    
}




