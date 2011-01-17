/*
 * Test.c: Sailing algorithm diagnostics program
 *
 *  Ported to Arudino November 2010 by Christine and the supercool software team

 *  Created on: 2010-05-11
 *      Author: Nader for MAST Software
 */
 
 
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
String waypts = String("$WAYP");

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
void scanf();//added for arduino to emulate scanf (scan a full line from the serial port); will need some variables & filling in.
void sailupwind();
void sailside();
void saildown();
float targetang();
float targetdist();
void tack(int side);

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

double GPSconv(double lat1, double long1, double lat2, double long2);


void setup()
{
  Serial.begin(9600);
  Serial1.begin(9600);

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

    do {
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
    do {
  	Sail();
        i++; //replace with finish exit condition
    } while (i<10);//(finish == 0);
  
  
   // see if it's running
    Serial.println("End of loop");    
    
    delay(50);//remove this delay
}
 

/////////////////////////////////////////////////////
//LEVEL 1 Functions
////////////////////////////////////////////////////

void setrudder(float ang){}

void prompt(){
//This function isnt returning properly; or perhaps scanf isnt? look into this!
//cb! is numwp accessed properly outside of this function?
	int numwp, i;
        String temp;
        
	int Way[24];//changed to an int from float; prompt seems to repeatedly be asking for the number of waypoints - corrupt stack?

	Serial.println("\nGAELFORCE\n");
	Serial.println("\nPlease enter the number of way points, at least 2 (start and finish), maximum 12: ");//CB changed prompt to include the maximu of 12 WPs
	scanf("d", &numwp); //(assume it returns in format specified by the type... may need to change this function around to only return strings)     
        numwp = 1; //remove when we're reading number of waypoints
        
        waypts = waypts+String(numwp); //turn the integer into a string representation, and do string catenation
      //this replaced :
      //sprintf(temp, ",%d", numwp);//cb! does temp have to be initialized to something? it has 253 garbage values... doesnt look like it http://www.rohitab.com/discuss/index.php?showtopic=11505
      //strcat(waypts, temp);

	for (i = 0; i < 2 * numwp; i++) {
		
          Serial.println("\nPlease enter the GPS X coordinates of the way point:");
          scanf("%f", &Way[i]);
          Way[i]=1.0;//replace with actual coordinate
          temp =  String("1.0"); //has to be formatted as string... String creator cannot create a string from a float -> issue?
          waypts = waypts + temp;

	  i++;
	
	  Serial.println("\nPlease enter the GPS Y coordinates of the way point:");
	  scanf("%f", &Way[i]);
          Way[i]=2.0;//replace with actual coordinate
	  waypts = waypts + String(2); //can't create a string from a float, had to round... maybe an issue; we should just do this in an array of floats anyways, not a string
	}
	 Serial.println("The way points are:\n");

	for (i = 0; i < numwp; i++) {
		Serial.print("\n way point");//saw here: http://arduino.cc/en/Reference/Comparison that cant print mixed tokens 
                Serial.print(i + 1);
                Serial.print(" is ");
                Serial.print(Way[2 * i]);
                Serial.print(",");
                Serial.println(Way[2 * i + 1]);

		//sprintf(temp, ",%f,%f", Way[2 * i], Way[2 * i + 1]);
		//strcat(waypts, temp);
               // waypts = waypts + String(Way[2*i]) + String(Way[2*i+1]); //moved this to put them in as they are entered to avoid "call of overload 'String(float&) is ambiguous" error
	}
	//printf("\nThe string:%s",waypts);
   Serial.println("Done prompt");
}

void Sail(){}

void poll(){}

void setwayp(int wayp){}


/////////////////////////////////////////////////////
//LEVEL 2 Functions
////////////////////////////////////////////////////

void scanf(char type, int *variable){
 //Presently this is a dummy function; needs to be completed
  //Reads a full line from the serial port if available; should time out after a given time if no data given? Same as scanf in C.
  int incomingByte = 0; //should this be an int?
  //  String data() = String(NULL); something like this

  if (Serial.available() > 0){// && incomingByte!=EOL) 
  // read the incoming byte:
    incomingByte = Serial.read();
    //add it to an ever-increasing string; either with malloc and an array, or String class above
    //do this until receive the EOL character
  }
  //update variables to return (right now none, but there should be some!)
  
}


