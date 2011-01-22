/*
 * Test.c: Sailing algorithm diagnostics program
 *
 *  Ported to Arudino November 2010 by Christine and the supercool software team

 *  Created on: 2010-05-11
 *      Author: Nader for MAST Software
 */

/* ////////////////////////////////////////////////
// Changelog
////////////////////////////////////////////////
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
#include <String.h> //for parsing - necesary?
#include <stdio.h> //for parsing - necessary?

////////////////////////////////////////////////
// Global variables and constants
////////////////////////////////////////////////



//Constants
//#define PI 3.14159265358979323846
#define d2r (PI / 180.0)
#define EARTHRAD 6367515 // for long trips only
#define MAXRUDDER 210  //Maximum rudder angle
#define MINRUDDER 210   //Minimum rudder angle
#define NRUDDER 210  //Neutral position
#define MAXSAIL 180 //Neutral position
#define resetPin 8 //Pololu reset (digital pin on arduino)
#define txPin 9 //Pololu serial pin (with SoftwareSerial library)

//Counters (Used for averaging)
int PTNTHTM;
int GPGLL;
int HCHDG;
int WIMWV;
int GPVTG;

//Global variables
float latitude; //Curent latitude
float longitude; //Current longitude
float GPSX; //Target X coordinate
float GPSY; //Target Y coordinate
float prevGPSX; //previous Target X coordinate
float prevGPSY; //previous Target Y coordinate
//Heading angle using wind sensor
float heading;//heading relative to true north
float deviation;//deviation relative to true north; do we use this in our calculations?
float variance;//variance relative to true north; do we use this in our calculations?
//Boat's speed
float bspeed; //Boat's speed in km/h
float bspeedk; //Boat's speed in knots
//Wind data
float wind_angl;//wind angle, (relative to boat or north?)
float wind_velocity;//wind velocity in knots
//Compass data
float headingc;//heading relative to true north
float pitch;//pitch relative to ??
float roll;//roll relative to ??

float heading_newest;//heading relative to true north

//Pololu
SoftwareSerial servo_ser = SoftwareSerial(7, txPin); // for connecting via a nonbuffered serial port to pololu -output only


int port1;//what is this?
char total[10000];//cb buffer variable


//set the reach target flag up
int finish; //something similar is needed for the actual program
int rc = 0; 
//char waypts[] = "$WAYP"; //for arduino, this should be implemented in String class objects (unless the memory use is too high)
int waypt[20]; //maximum of 10 waypoints for now
//String waypts = String("$WAYP"); //for arduino


/////////////////////////////////////////////////////
//LEVEL 4 Functions
////////////////////////////////////////////////////

int DataValid(char *val) 
{
	if (val[0] != '$') 
	{
		Serial.println("wrong data\n");
		return 0;
	}
	return 1;
	//Check the end of the string
}

int Parser(char *val) 
{
//parses a string of NMEA wind sensor data
// this also changes the global variables depending on the data; this would be much better split into separate functions
// presently, the changes to global variables are not conducive to a moving average; they CAN be used for an average, which could perhaps go into a moving average

// This parser breaks when there are blanks in the data ie $PTNTHTM,,N,-2.4,N,10.7,N,59.1,3844*27


  char *str; //dummy string to absorb the type of data, as %5s, value not used; I guess strtok automatically calls realloc?
  char cp[100]; //temporary array for parsing, a copy of val

  //GPSGLL gps latitude and longitude data
  double grades, frac; //the integer and fractional part of Degrees.minutes
  float lat_deg_nmea, lon_deg_nmea; // latitude and longitude in ddmm.mmmm degrees minutes format
  float lat; //latitude read from the string converted to decimal dd.mmmm
  float lon; //longitude read from the string converted to decimal dd.mmmm
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
  
  if (DataValid(val) == 1){ //check if the data is valid - ideally we'd do this by checking the checksum
    Serial.print("Parses says: valid string, val (full string) is:\n");
  }
  else return 1; // if data isnt valid, dont try to parse it and throw error code

  Serial.println(val);//echo what we're about to parse

  strcpy(cp, val); //make a backup copy of the data to parse; if not copied val gets corrupted when tokenized
  str = strtok(cp, ","); //find location of first ',', and copy everything before it into str1; returns a pointer to a character array. this will be the type of command, should return $xxxxx identifier

 // Serial.print("command portion from cp strtok is: ");
 // Serial.println(str);
  
  //now we know what type of command we're dealing with and can parse it - wooooo
  
  
  //GPS String
  if (strcmp(str, "$GPGLL") == 0) 
  {
   // sscanf(val, "$%5s,%f,%c,%f,%c,%d,%c,", str, &lat_deg_nmea, &lat_dir, &lon_deg_nmea, &lon_dir, &hms, &valid);

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

    //this first moves the decimal so that the latitude degrees is the whole part of the number
    //then modf returns the integer portion to 'grades' and the fractional (minutes) to 'frac'.
    frac = modf(lat_deg_nmea / 100.0, &grades); 
    // Frac is out of 60, not 100, since it's in minutes; so convert to a normal decimal
    lat = (double) (grades + frac * 100.0 / 60.0) * (lat_dir == 'S' ? -1.0    : 1.0); // change the sign of latitude based on if it's north/south

    //do the same for longitude
    frac = modf(lon_deg_nmea / 100.0, &grades);
    lon = (double) (grades + frac * 100.0 / 60.0) * (lon_dir == 'W' ? -1.0 : 1.0);

    /*print("The string: %s\n", str);
     printf("Lat_dir nmea: %f\n", lat_deg_nmea);
     printf("Lat: %f\n", lon1);
     printf("Lat_dir: %c\n", lon_dir);*/

    latitude = latitude + lat; //cb! dont we want a moving average? 
    longitude = longitude + lon;        
    GPGLL++;
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
    heading = heading + head_deg; //cb! dont we want a moving average?
    deviation = deviation + dev_deg; //what is this in compass terminology? I think we should be taking dev_dir into account
    variance = variance + var_deg; //what is this in compass terminology? I think we should be taking var_dir into account
    HCHDG++;
  }

  //Wind speed and wind direction
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
    wind_angl = wind_angl + wind_ang; //cb! dont we want a moving average?
    wind_velocity = wind_velocity + wind_vel;
    WIMWV++;
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

    bspeed += sov_kmh; //cb! dont we want a moving average?
    bspeedk += sov_knot;
    GPVTG++;
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
    headingc = headingc + head2_deg; //cb! dont we want a moving average?
    pitch = pitch + pitch_deg;
    roll = roll + roll_deg;
    PTNTHTM++;//how many times summed
    
    heading_newest = head2_deg;//also track the newest heading
  }

  return 0;
	
}


/////////////////////////////////////////////////////
//LEVEL 3 Functions
////////////////////////////////////////////////////

void servo_command(int whichservo, int position)
{
 servo_ser.print(0xFF, BYTE); //servo control board sync
 //Plolou documentation is wrong on servo numbers in MiniSSCII
 servo_ser.print(whichservo+8, BYTE); //servo number, 180 mode
 servo_ser.print(position, BYTE); //servo position
}


//Pololu servo board test in Mini SSC II mode
//(mode jumper innplace on Pololu board)

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


int Compass() 
{
	//fill in code to get data from the serial port if availabile

char inputArrayPtr[256]; // look into changing this to a byte array; stores the input data
char byteRead; //used to read one single byte at a time
int error =0; //error flag
int i; //loop counter
int availableBytes = Serial2.available();

//prevent array overflow
if (availableBytes > 255)
  availableBytes = 255;
  
//inputArrayPtr = (char*)malloc( sizeof(char) * availableBytes);

for(i=0; i < availableBytes; i++)
{
    inputArrayPtr[i] = Serial2.read();
    if ( inputArrayPtr[i] == '\n' || inputArrayPtr[i] == '\0' )
      break;
} 
 Serial.print("\nCompass string from port 2: ");
 Serial.println(inputArrayPtr);
 Serial.print("\n Avail bytes port 2: ");
 Serial.println(availableBytes);
 
 error = Parser(inputArrayPtr); 
 
// free(inputArrayPtr); // release the memory we realloc'ed
   
//this way works to print to screen..
//byte input; 
//  while(Serial3.available()>0){
//    input = Serial3.read();
//   Serial.print(input);
//  }

	//char sResult[254] = fromSerialPortCompass();//array of string data from wind sensor (this isnt a real function yet)
      //if data available; can use strtok to split the data based on $ sign at beginning of data, and then send to parse to process; if not, return 1 (error code):
      
	  // Compass testing
  // The 75.9 is the dip angle; 2618 is the magnetic field ; http://www.google.ca/url?sa=t&source=web&cd=3&ved=0CCEQFjAC&url=http%3A%2F%2Fgpsd.googlecode.com%2Ffiles%2Ftruenorth-reference.pdf&ei=jLn-TLaTAtvtnQeE1KGgCw&usg=AFQjCNFKgSCpWdeEoXWtQQiYeHJYXeXQ-g; http://lists.berlios.de/pipermail/gpsd-dev/2006-October/004558.html
 // int error = Parser("$PTNTHTM,71.3,N,-0.4,N,-1.4,N,75.9,2618*03"); //returning 71.30, -0.40, -1.40 -> good!

 
 /*  Serial.println(headingc);
   Serial.println(pitch);
   Serial.println(roll);
   Serial.println(PTNTHTM); */ 

   return error;
}



int Wind() 
{	//fill in code to get data from the serial port if availabile
char inputArrayPtr[256]; // look into changing this to a byte array; stores the input data
int error =0; //error flag
int i; //loop counter
int availableBytes = Serial3.available();

//prevent array overflow
if (availableBytes > 255)
  availableBytes = 255;
  
for(i=0; i < availableBytes; i++)
{
    inputArrayPtr[i] = Serial3.read();
    if ( inputArrayPtr[i] == '\n' || inputArrayPtr[i] == '\0' )
      break;
} 
 Serial.print("\n Wind string from port 3: ");
 Serial.println(inputArrayPtr);
  Serial.print("\n Avail bytes port 3: ");
 Serial.println(availableBytes);
 
 error = Parser(inputArrayPtr); 
	//char sResult[254] = fromSerialPortWind();//array of string data from wind sensor (this isnt a real function yet)
      //if data available; can use strtok to split the data based on $ sign at beginning of data, and then send to parse to process; if not, return 1 (error code):
      
      //Uncomment a section to test it parsing that kind of command! (will print the global variables)
 /* //GPS testing:
 int error = Parser("$GPGLL,4413.7075,N,07629.5199,W,192945,A,A*5E"); // this is returning 44.23  and -76.49; off by 0.1, 0.2?
  Serial.println(latitude);//curent latitude
  Serial.println(longitude); //Current longitude
  //Serial.println(GPSX); //Target X coordinate
  //Serial.println(GPSY); //Target Y coordinate
  //Serial.println(prevGPSX); //previous Target X coordinate
  //Serial.println(prevGPSY); //previous Target Y coordinate
 */

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
   */
	

	return error;
}


void setup()
{
	Serial.begin(9600);
	//Serial1.begin(9600);

 Serial.begin(9600);
 Serial2.begin(19200);
 Serial3.begin(4800);

        pinMode(txPin, OUTPUT);
        pinMode(resetPin, OUTPUT);
               
        servo_ser.begin(2400);

        //next NEED to explicitly reset the Pololu board using a separate pin
        //else it times out and reports baud rate is too slow (red LED)
        digitalWrite(resetPin, 0);
        delay(10);
        digitalWrite(resetPin, 1);  
        
        //initialize all counters/variables
  
  latitude=0;//curent latitude
  longitude=0; //Current longitude
  GPSX=0; //Target X coordinate
  GPSY=0; //Target Y coordinate
  prevGPSX=0; //previous Target X coordinate
  prevGPSY=0; //previous Target Y coordinate
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
        
        heading_newest=0;//heading relative to true north, newest
}



void loop()
{
  int error;
  int i;
  
  error = Compass();
  error = Wind();   
  
     //this doesnt seem to be reacting to the serial data as expected - I believe the problem is largely due to how we're parsing and the lack of error checking
//  Serial.print("\nNew heading");   
//  setrudder(heading_newest);
//  delay(2000);
  

//note: output is even MORE garbled over zigbee; interference? or buffers full?


//the below worked for about 10 iterations and then pololu started blinking red light - error?
//we need to monitor pololu's feedback to detect these error codes
//resetting the arduino fixed the problem

 Serial.print("\n 320 degrees");   
  setrudder(320);
  delay(2000);
  
  Serial.print("\n10 degrees");   
  setrudder(10);
  delay(2000);
  
 // for (i=0; i<10; i++) //read 10 times to ensure buffer doesnt get full
 //    error = Compass();
   
}



