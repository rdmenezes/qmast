/*
 * Test.c: Sailing algorithm diagnostics program
 *
 *  Ported to Arudino November 2010 by Christine and the supercool software team

 *  Created on: 2010-05-11
 *      Author: Nader for MAST Software
 */
#include <math.h>

////////////////////////////////////////////////
// Global variables and constants
////////////////////////////////////////////////

float latitude; //Curent latitude
float longitude; //Current longitude
float GPSX; //Target X coordinate
float GPSY; //Target Y coordinate
float prevGPSX; //previous Target X coordinate
float prevGPSY; //previous Target Y coordinate
//Heading angle using wind sensor
float heading;
float deviation;
float variance;
//Boat's speed
float bspeed; //Boat's speed in km/h
float bspeedk; //Boat's speed in knots
//Wind data
float wind_angl;
float wind_velocity;
//Compass data
float headingc;
float pitch;
float roll;

//Counters (Used for averaging)
int PTNTHTM;
int GPGLL;
int HCHDG;
int WIMWV;
int GPVTG;
//Constants
#define PI 3.14159265358979323846
#define d2r (PI / 180.0)
#define EARTHRAD 6367515 // for long trips only
#define MAXRUDDER 90  //Maximum rudder angle
#define MINRUDDER 0   //Minimum rudder angle
#define NRUDDER 45  //Neutral position
#define MAXSAIL 180 //Neutral position

int port1;
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
		Serial.print("wrong data\n");
		return 0;
	}
	return 1;
	//Check the end of the string
}

void Parser(char *val) 
{
	//parses a string of wind sensor data
	
	//fill in
	
	latitude=1; 
	longitude=1; 
	
	//Heading angle using wind sensor
	heading =1;
	deviation=1;
	variance=1;
	//Boat's speed
	bspeed=1; //Boat's speed in km/h
	bspeedk=1; //Boat's speed in knots
	//Wind data
	wind_angl=1;
	wind_velocity=1;
	
}


/////////////////////////////////////////////////////
//LEVEL 3 Functions
////////////////////////////////////////////////////

void setrudder(float ang)
{
	//fill this in with the code to interface with pololu
}

int Compass() 
{
	//fill in
	headingc = 2; // CB wheres this come from?
	pitch = 2;
	roll = 2;
	PTNTHTM++; // CB what is this keeping track of?? .. average heading... over all time? cb!! june7 why is this commented out? put it back in
	return 0;
	
}


int Wind() 
{	//cb changed to int june7 //clean up sResult, total, and t[] parser changes the values
	//fill in
	char sResult[254];//array of string data from wind sensor
	
	Parser(sResult);	
	
	return 0;
}


void poll()
{	//fill in
	int status; //check for successful return of function
	
	//Wind sensor data
	status = Wind();
	
	//Compass data
	status = Compass();
}

double GPSconv(double lat1, double long1, double lat2, double long2) 
{		
	double dlong;
	double dlat;
	double a;
	double c;
	double d;
	
	dlong = (long2 - long1) * d2r;
	dlat = (lat2 - lat1) * d2r;
	a = pow(sin(dlat / 2.0), 2) + cos(lat1 * d2r) * cos(lat2 * d2r)
	* pow(sin(dlong / 2.0), 2);
	c = 2 * atan(sqrt(a) / sqrt(1 - a)); //replaced atan2 with atan ? is there such thing as atan2 function before arduino?
	d = 6367 * c;
	
	return d;
}

void setwayp(int wayp)
{	//Set waypoints
	
	//all the other stuff that was here appears not to be required.
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
	
	//Calculate the direction of the next waypoint
	//Turn the rudder all the way out
	//Then slowly return it to the direction of the next target
	
	float tarang;
	setwayp(0); //Change this for the actual program CB to what?
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
 * Duty: preforms tacking
 * Inputs: on which direction tacking is needed
 * Output: controls the rudder
 * Returns: none
 */	
	
	//cb! tacking should have a timer to turn the rudder the other way if it's not successful
	float phead;
	phead = headingc; //The heading before the tack
	//side = 0 means that close haul is done from the positive side (west of the boat)
	//side = 1 means that close haul is done from the negative side (east of the boat)
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
	int side; // keep track the wind from which side
	prev_vel = 0;
	
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
			setrudder(MAXRUDDER); //turn the rudder all the way
			side = 0;
		} 
		else if ((abs(ang_diff) < 40) && (ang_diff > 0)) 
		{
			setrudder(MINRUDDER); //turn the rudder all the way
			side = 1;
		} 
		else
			setrudder(NRUDDER);
		
		do 
		{
			poll();
			ang_diff = wind_angl - tar_ang;
/*
			 if ((bspeed - prev_vel) < 0 && (bspeed == 0)) {
			 setsail(10); //set the main sail out by 10 degrees
			 }
			 prev_vel = bspeed; */			
		} while (abs(ang_diff) < 40);
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
		
	} while (1000 * tar_dist < 5.0); //Loop until distance is 5 meters away from target
	
	target();
}


void sailside() 
{
	double tar_dist; //Target distance
	float tar_ang; //Target angle
	float dir_ang; // sailing direction
	float wind_diff; // difference between the wind angle and the boat direction
	//tar_dist = GPSconv(latitude, longitude, GPSX, GPSY);
	//tar_ang = targetang();
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
	} while (1000 * tar_dist < 5.0); //Loop until distance is 5 meters away from target
	target();
	
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
	} while (1000 * tar_dist < 5.0); //Loop until distance is 5 meters away from target
	target();
}


float targetdist()
{	return 0;	
}




/////////////////////////////////////////////////////
//LEVEL 1 Functions
////////////////////////////////////////////////////



void prompt()
{
	//This function isnt returning properly; or perhaps scanf isnt? look into this!
	//cb! is numwp accessed properly outside of this function?
	
	//Porting:
	//changed String waypts to array of ints waypt[i]
	//commented out scanf, changed to scanln (we cant simulate scanf with the simulator, this will save hassle)
	
	int numwp=0, i;
	//String temp;
	
	int Way[24];//changed to an int from float; prompt seems to repeatedly be asking for the number of waypoints - corrupt stack?
	
	Serial.println("\nGAELFORCE\n");
	Serial.println("\nPlease enter the number of way points, at least 2 (start and finish), maximum 12: ");//CB changed prompt to include the maximu of 12 WPs
	
	//	scanln('d', &numwp); //(assume it returns in format specified by the type... may need to change this function around to only return strings)     
	numwp = 1; //remove when we're reading number of waypoints
	
	//waypts = waypts+String(numwp); //turn the integer into a string representation, and do string catenation
	//this replaced :
	//sprintf(temp, ",%d", numwp);//cb! does temp have to be initialized to something? it has 253 garbage values... doesnt look like it http://www.rohitab.com/discuss/index.php?showtopic=11505
	//strcat(waypts, temp);
	
	for (i = 0; i < 2 * numwp; i++) 
	{
		
		Serial.println("\nPlease enter the GPS X coordinates of the way point:");
		//scanln("%f", &Way[i]);
		
		waypt[i]=1;
		
		//This is for doing waypoitns as strings... instead just do as an array
		//Way[i]=1.0;//replace with actual coordinate
		//temp =  String("1.0"); //has to be formatted as string... String creator cannot create a string from a float -> issue?
		//waypts = waypts + temp;
		
		i++;
		
		Serial.println("\nPlease enter the GPS Y coordinates of the way point:");
		//scanln("%f", &Way[i]);
		
		waypt[i]=2;
		
		//This is for doing waypoitns as strings... instead just do as an array
		//Way[i]=2.0;//replace with actual coordinate
		//waypts = waypts + String(2); //can't create a string from a float, had to round... maybe an issue; we should just do this in an array of floats anyways, not a string
	}
	Serial.println("The way points are:\n");
	
	for (i = 0; i < numwp; i++) 
	{
		Serial.print("\n way point");//saw here: http://arduino.cc/en/Reference/Comparison that cant print mixed tokens 
		Serial.print(i + 1);
		Serial.print(" is ");
		Serial.print(waypt[2 * i]);
		Serial.print(",");
		Serial.println(waypt[2 * i + 1]);
		
		//sprintf(temp, ",%f,%f", Way[2 * i], Way[2 * i + 1]);
		//strcat(waypts, temp);
		// waypts = waypts + String(Way[2*i]) + String(Way[2*i+1]); //moved this to put them in as they are entered to avoid "call of overload 'String(float&) is ambiguous" error
	}
	//printf("\nThe string:%s",waypts);
	Serial.println("Done prompt");
}


void Sail() 
{
	//Ported
	
	//Calculate the target distance and angle and wind difference
	float tar_dist; //Target distance
	float tar_ang; //Target angle
	float ang_diff; // Difference between wind direction and target direction
	int n; //used to identify cases	
	
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
	
}
void loop()
{
	float dist;
	int i; //temp variable for testing, replace once there is actually a dist
	setrudder(MAXRUDDER);
	
	prompt(); // CB ok, one place needs realloc or pre-size array (setting number of waypoints) -> fixed, set size to 12 points (24 variables)
	
	finish = 0;
	setwayp(0); // CB ok
	Serial.print("\nPlease use Radio control to drive the boat to the start line\n");
	
	do 
	{
		poll();
		i++; //remove for real code and replace with dist exit condition
	} while (i<10);//(dist < 10.0);
	
	rc = 0;
	Serial.print("At the start line!\n");//cb added
	prevGPSX = GPSX;
	prevGPSY = GPSY;
	setwayp(1);//CB this is called here, but the global variables havnt been cleared out from the old mess in waypts
	Serial.print("Now Sailing\n");
	i=0;
	do 
	{
		Sail();
		i++; //replace with finish exit condition
	} while (i<10);//(finish == 0);
	
	
	// see if it's running
	Serial.println("End of loop");    
	
	delay(50);//remove this delay
}



