/*
 * Test.c: Sailing algorithm diagnostics program
 *
 *  Ported to Arudino November 2010 by Christine and the wonderful software team

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

/*
////////////////////////////////////////////////
//function prototype level 1
////////////////////////////////////////////////
void setrudder(float ang);
void prompt();
void Sail();
void poll();
void setwayp(int wayp);

////////////////////////////////////////////////
//Function Prototypes level 2 & below
////////////////////////////////////////////////
void scanln(char, int *);//added for arduino to emulate scanf (scan a full line from the serial port); will need some variables & filling in.
void sailupwind();
void sailside();
void saildown();
float targetang();
float targetdist();
void tack(int side);
double GPSconv(double lat1, double long1, double lat2, double long2);


int DataValid(char *val);
int writeport(int port1, char *chars);
int getbaud(int fd);//cb added
//int readport(int port1, char *result);
int readport(int fd, char *result);//cb changed to serial3.c's readport june7
int SerialPort(int baud, char *port, int j);
int SerialPortCB(int baud, char *port, int j);//cb june7
int Compass();//cb june7
int initportC(int fd2);//cb june7
int Wind();//cb june7
void Parser(char *val);

void initVar();
int initport(int port1, long baud);
int Corridor2();

*/

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

  Serial.print("command portion from cp strtok is: ");
  Serial.println(str);
  
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

  Serial.println("Controlling motors");
  
  servo_command(servo_num,ang);
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


void poll()
{	//fill in
	int stat; //check for successful return of function; how should we implement this? probably just report to zigbee every time theres an error
	Serial.println("Polling sensors");
	//Wind sensor data
	stat = Wind();
	
	//Compass data
	stat = Compass();
}

double GPSconv(double lat1, double long1, double lat2, double long2) 
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

void setwayp(int wayp)
{	//Set waypoints
	
	//all the other stuff that was here appears not to be required.... may need to put it back in though
	prevGPSX = GPSX;
	prevGPSY = GPSY;
	
	GPSX = waypt[2 * wayp];
	GPSY = waypt[2 * wayp + 1];	
	
}

float targetang() 
{
/* targetang function
 * Duty: compute the angle between the boat and the target
 * Inputs: none
 * Output: none
 * Returns: target's angle
 */	
	float angle, x, y;
	x = (longitude - GPSX);
	y = (latitude - GPSY);
	angle = tan(y / x);
	
	if (angle < 0)
		angle += 360;
	else if (angle > 360)
		angle -= 360;
	return angle;
}

void target() 
{
        //need to change the rudder angles to some proportional value	
  
        //Target tells the boat to look for the next waypoint
        
	//Calculate the direction of the next waypoint
	//Turn the rudder all the way out
	//Then slowly return it to the direction of the next target
	
	float tarang;
	setwayp(0); //Change this for the actual program to reference the global list of waypoints and get the next one
	tarang = targetang();
	if ((headingc - tarang) < 0) 
	{	//The target is left to the boat
		//turn to the right
		setrudder(MAXRUDDER); // cb! nader says: Not sure about MIN or MAX
		do 
		{
			Compass();
			
		} while (abs(headingc - tarang) < 5);
		setrudder(NRUDDER);
	} 
	else 
	{
		//turn to the right
		setrudder(MINRUDDER); //Not sure about MIN or MAX
		do 
		{
			Compass();
			
		} while (abs(headingc - tarang) < 5); //If the boat is heading towards the target
		setrudder(NRUDDER);
	}
	
}


int Corridor2() 
{
    //checks if the boat is within a corridor along the path to the nexy waypoint	
        float angle;
	float angle2;
	float x;
	double temp;
	float tarang;
	float temp2;
	
	temp = (latitude - prevGPSY) / (longitude - prevGPSX);
	angle = atan(temp);
	tarang = targetang();
	angle2 = tarang - 90.0;
	temp2 = angle - angle2;
	temp = GPSconv(latitude, longitude, prevGPSX, prevGPSY);
	x = ((float) temp) * cos(temp2);
	if (x > 20.0) 
	{	// check if it straied 20 meters away from the target line
		return 1;
	}
	else 	
	{
		return 0;
	}
}


void tack(int side) 
{ 
 
/* tack function
 * Duty: performs tacking
 * Inputs: on which direction tacking is needed
 * Output: controls the rudder
 * Returns: none
 * Side: is set by the sailupwind/downwind/side functions, and changed there if in irons
 */	
	
	//cb! tacking should have a timer to turn the rudder the other way if it's not successful
	float phead;
	phead = headingc; //The heading before the tack
	//side = 0 means that close haul is done from the positive side (west of the boat)
	//side = 1 means that close haul is done from the negative side (east of the boat)
        
        Serial.println("Tacking");
        
	if ((bspeed > 5) && side == 0) 
	{
		setrudder(MAXRUDDER);
		Compass();
		if (abs(headingc + phead) < 5) 
		{
			setrudder(NRUDDER);
		}
		
	} 
	else
		if ((bspeed > 5) && side == 1) 
		{
			setrudder(MINRUDDER);
			Compass();
			if (abs(headingc + phead) < 5) 
			{
				setrudder(NRUDDER);
			}
	}
	
}

/////////////////////////////////////////////////////
//LEVEL 2 Functions
////////////////////////////////////////////////////

void scanln(char type, int *variable)
{
	//Presently this is a dummy function; needs to be completed
	//Reads a full line from the serial port if available; should time out after a given time if no data given? Same as scanf in C.
	int incomingByte = 0; //should this be an int?
	//  String data() = String(NULL); something like this
	
	if (Serial.available() > 0)
	{	// && incomingByte!=EOL) 
		// read the incoming byte:
		incomingByte = Serial.read();
		//add it to an ever-increasing string; either with malloc and an array, or String class above
		//do this until receive the EOL character
	}
	//update variables to return (right now none, but there should be some!)
	
}


void sailupwind() 
{
/* sailupwind function
 * Duty: sail logic when upwind sail is needed
 * Inputs: none
 * Output: controls the rudder and the sail
 * Returns: none
 */	
	double tar_dist; //Target distance
	float tar_ang; //Target angle
	float ang_diff; // Difference between wind direction and target direction
	float prev_vel; //stores the previous velocity
	int corr; //1 if it is far from the target
	int side; // keep track the wind from which side; this doesnt seem to be being updated enough
	prev_vel = 0;

	Serial.println("\n Sailing upwind \n");

	do 
	{
		poll(); //invoke the parser
		
		//Calculate the target distance and angle and wind difference
		
		tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
		tar_ang = targetang();
		ang_diff = wind_angl - tar_ang;
		
		//prev_vel =  bspeed;
		
		//cases to check if the boat is in irons or not
		if (abs(ang_diff) < 40 && ang_diff < 0) 
		{
			setrudder(MAXRUDDER); //turn the rudder all the way to get out of irons
			side = 0;
		} 
		else if ((abs(ang_diff) < 40) && (ang_diff > 0)) 
		{
			setrudder(MINRUDDER); //turn the rudder all the way to get out of irons
			side = 1;
		} 
		else
			setrudder(NRUDDER); //sail straight
		
		do 
		{
			poll();
			ang_diff = wind_angl - tar_ang;
/*
			 if ((bspeed - prev_vel) < 0 && (bspeed == 0)) {
			 setsail(10); //set the main sail out by 10 degrees
			 }
			 prev_vel = bspeed; */			
		} while (0);//(abs(ang_diff) < 40);
		setrudder(NRUDDER);
		//once sailing
		//setsail(0); //bring back the sails to zero
		// poll();
		corr = Corridor2(); //Check if a tack is needed
		if (corr == 1) 
		{
			tack(side);
		}
		tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
		//tar_ang = targetang();
		
	} while (0);//(1000 * tar_dist < 5.0); //Loop until distance is 5 meters away from target
	
	target(); //go to next target
}


void sailside() 
{
	double tar_dist; //Target distance
	float tar_ang; //Target angle
	float dir_ang; // sailing direction
	float wind_diff; // difference between the wind angle and the boat direction
	//tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
	//tar_ang = targetang();

	Serial.println("\n Sailing sideways \n");

	do 
	{
		poll();
		//calculate target
		tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
		tar_ang = targetang();
		//check the sign
		dir_ang = headingc - tar_ang;
		wind_diff = abs(wind_angl - headingc);
		setrudder(dir_ang);
/*
		 //let main sail out
		 if (abs(dir_ang) < 10) {
		 //setsail(wind_diff);

		 } */		
		//recalculate target
		tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
		//tar_ang = targetang();
	} while (0);//(1000 * tar_dist < 5.0); //Loop until distance is 5 meters away from target

	target(); //go to next target
	
}


void saildown()
{
/* saildown function
 * Duty: sail logic when sailing downwind
 * Inputs: none
 * Output: controls the rudder and the sail
 * Returns: none
 */	
	
	double tar_dist; //Target distance
	float tar_ang; //Target angle
	float dir_ang; // sailing direction

	Serial.println("Sailing downwind");

	do 
	{
		poll();
		//calculate target
		//tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
		tar_ang = targetang();
		//check the sign
		dir_ang = headingc - tar_ang;
		setrudder(dir_ang);
		
		//let main sail out
		//setsail(MAXSAIL);
		
		//recalculate target
		tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
		//tar_ang = targetang();
	} while (0);//(1000 * tar_dist < 5.0); //Loop until distance is 5 meters away from target

	target(); //go to next target
}


float targetdist()
{	return 0;	
   // this function is never called?
}




/////////////////////////////////////////////////////
//LEVEL 1 Functions
////////////////////////////////////////////////////



void prompt()
{
        //presently this function is a dummy	
        //This function isnt returning properly; or perhaps scanf isnt? look into this!
	//cb! is numwp accessed properly outside of this function?
	
	//Porting:
	//changed String waypts to array of ints waypt[i]
	//commented out scanf, changed to scanln (we cant simulate scanf with the simulator, this will save hassle)
	
	int numwp=0, i;
	//String temp;
	
	int Way[24];//changed to an int from float; prompt seems to repeatedly be asking for the number of waypoints - corrupt stack?
	
	Serial.println("Prompt");
	//Serial.println("\nPlease enter the number of way points, at least 2 (start and finish), maximum 12: ");//CB changed prompt to include the maximu of 12 WPs
	
	//	scanln('d', &numwp); //(assume it returns in format specified by the type... may need to change this function around to only return strings)     
	numwp = 1; //remove when we're reading number of waypoints
	
	//waypts = waypts+String(numwp); //turn the integer into a string representation, and do string catenation
	//this replaced :
	//sprintf(temp, ",%d", numwp);//cb! does temp have to be initialized to something? it has 253 garbage values... doesnt look like it http://www.rohitab.com/discuss/index.php?showtopic=11505
	//strcat(waypts, temp);
	
	for (i = 0; i < 2 * numwp; i++) 
	{
		
		//Serial.println("\nPlease enter the GPS X coordinates of the way point:");
		//scanln("%f", &Way[i]);
		
		waypt[i]=1;
		
		//This is for doing waypoitns as strings... instead just do as an array
		//Way[i]=1.0;//replace with actual coordinate
		//temp =  String("1.0"); //has to be formatted as string... String creator cannot create a string from a float -> issue?
		//waypts = waypts + temp;
		
		i++;
		
		//Serial.println("\nPlease enter the GPS Y coordinates of the way point:");
		//scanln("%f", &Way[i]);
		
		waypt[i]=2;
		
		//This is for doing waypoitns as strings... instead just do as an array
		//Way[i]=2.0;//replace with actual coordinate
		//waypts = waypts + String(2); //can't create a string from a float, had to round... maybe an issue; we should just do this in an array of floats anyways, not a string
	}
	//Serial.println("The way points are:\n");
	
	for (i = 0; i < numwp; i++) 
	{
//		Serial.print("\n way point");//saw here: http://arduino.cc/en/Reference/Comparison that cant print mixed tokens 
//		Serial.print(i + 1);
//		Serial.print(" is ");
//		Serial.print(waypt[2 * i]);
//		Serial.print(",");
//		Serial.println(waypt[2 * i + 1]);
		
		//sprintf(temp, ",%f,%f", Way[2 * i], Way[2 * i + 1]);
		//strcat(waypts, temp);
		// waypts = waypts + String(Way[2*i]) + String(Way[2*i+1]); //moved this to put them in as they are entered to avoid "call of overload 'String(float&) is ambiguous" error
	}
	//printf("\nThe string:%s",waypts);
	//Serial.println("Done prompt");
}


void Sail() 
{
	//Ported
	
	//Calculate the target distance and angle and wind difference
	float tar_dist; //Target distance
	float tar_ang; //Target angle
	float ang_diff; // Difference between wind direction and target direction
	int n; //used to identify cases	
	
        Serial.println("Sailing, sailing... ladeladela...");
        
	//Poll data from sensors
	poll();
	
	tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
	tar_ang = targetang();
	ang_diff = wind_angl - tar_ang;
	
	//check ang_diff and sets the cases variable
	
        /* The sailing cases:
	 * Case 1 (Upwind case): angle [-45,45]
	 * Case 2 (sides): angle (-135,-45) U (45,135)
	 * Case 3 (downwind): angle (-180, -135] U [135, 180)
	 */	
        Serial.println("Checking sail angle condition");
        
	if (abs(ang_diff) < 45)
		n = 1;
	else if (abs(ang_diff) > 45 && abs(ang_diff) < 135)
		n = 2;
	else
		n = 3;
	
	switch (n) 
	{
		
		case 1:
			sailupwind();
			break;
		case 2:
			sailside();
			break;
		case 3:
			saildown();
			break;
			
		default:
			sailupwind();
		break; // break isn?t necessary here
	}
	
/********************END OF SWITCH CASES********************/	
	//NOTE: Need an array to keep the acceleration values.	
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
        
        
}

void loop()
{
  int error = Wind();
  // for some reason "sailing sideways" is appearing in our output??
  
  /*	float dist;
	int i; //temp variable for testing, replace once there is actually a dist

	rc = 1; // start out in manual mode?
//        setrudder(MAXRUDDER); //this would also be an option; start with rudder all the way over (not going anywhere ideally)
	
	prompt(); // CB ok, one place needs realloc or pre-size array (setting number of waypoints) -> fixed, set size to 12 points (24 variables)
	
	finish = 0;
	setwayp(0); // CB ok
	//Serial.print("\nPlease use Radio control to drive the boat to the start line\n");
	Serial.println("\n\nLoop");

	do 
	{
		poll();
		i++; //remove for real code and replace with dist exit condition
	} while (i<10);//(dist < 10.0);
	
	rc = 0;
	Serial.println("At the start line!");//cb added
	prevGPSX = GPSX;
	prevGPSY = GPSY;
	setwayp(1);//CB this is called here, but the global variables havnt been cleared out from the old mess in waypts
	//Serial.print("Now Sailing\n");
	i=0;
	do 
	{
		Sail();
		i++; //replace with finish exit condition
	} while (i<10);//(finish == 0);
	
	
	// see if it's running
	//Serial.println("End of loop");    
	
	delay(50);//remove this delay
*/
}



