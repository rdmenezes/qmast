

// Boat MAIN
#include <EEPROM.h>
#include <Servo.h>
#include <Wire.h>
#include <LSM303DLH.h>
#include <PID_v1.h>


// DEFINES
#define pi 3.14159265

char *token;
char *tokenTempJ;
// function PROTOTYPES (put in a header)
void init_compass(void);
void getCompassData(void);
void transmit(void);
void init_AIRMAR(void);
void get_AIRMAR(void);
float comp2pol(float);
float pol2comp(float);
void  pol2cart(float *, float *, float , float );
void cart2pol(float ,float ,float *,float *);
void boatlogic(void);
void stationkeep(void);  
void convertC2P(void);
void control(void);
void get_Lipo(void);
void get_WPTS(void);
void eeprom2arr(void);
void eeprom2rud(void);
//GPS prototypes
void gps_str_to_int(char*, struct gps_int_t* );
void gps_int_to_float(struct gps_int_t*, struct gps_int_t*, float*);
void gps_rel_pos(struct gps_int_t*, struct gps_int_t*, float*);
//Waypoints
void wptcheck(void);
void setcourse(void);
//Control
void control(void);
void rudder_ctrl(void);
void tail_ctrl(void);
//---------WORM-----------
void worm_ctrl(void);
//--------ENDWORM---------
void camber_ctrl(void);
void servo_out(void);
float boatlogicSUB(void);
void stop_loop(void);
void wind_average(void);




//VARIABLES
float vwthetaC = 0;                 //true wind dirn (compass)
float vwtheta = 0;                  //true wind dirn (polar)
float vbx = 0;                      //boat velocity cart xy
float vby = 0;
float vb = 0;                       // boat velocity polar
float vbtheta = 0;                  // Where we want the point to point, in polar

//NMEA VARIABLES
float 	ground_speed 		= 0;                    // vb in knots
long 	ground_course 		= 0;			// degrees * 100 dir of plane  
float magvar;
char magvarEW;
float vbthetaT;    //vbtheta true
float vbthetaTP;   //vbtheta true polar
float vbthetaM;
float vbthetaMP;
float vwthetaBR;  //vwtheta measured from bow, relative
float vwthetaBT;  //vwtheta measred from bow, true
float vwR;        //vw relative
float vwT;        //vw true
float vwthetaT; //true wind dirn true(compass)
float vwthetaTP; //true wind dirn true(polar)
float vwthetaM; //true wind dirn mag (compass)
float vwthetaMP; //true wind dirn mag (polar)
float vw;        //true wind speed knots


//Moving Average Variables
int av_cnt_BR = 0;  //counter for the moving average BR
int L_BR = 5;      //Length of MA, not sure what the loop frequency is..
float vwthetaBRarr[5];  //Array for moving average
float vwthetaBRtmp =0;        //Load Variables into these.

int av_cnt_T = 0;    //counter for the moving average TRUE
int L_T = 120;
float vwthetaTarr[120];
float vwthetaTtmp =0;


boolean GPSLOCK = 0;
int WINDTEST = 0;
int tempval=0;
float Lipo;
short int event = 0; //Used to transmit messages

//control var
short int tailrev = 1;      //make these -1 to change reverse the autopilot controls
short int rudrev = 1;
short int camrev = 1;

Servo Rudd_Servo;
Servo Camb_Servo;
Servo Tail_Servo;
Servo Worm_Servo;

float tPt; //tail proportional to tilt
float tP; //tail proportional gain
float tPw;
float rP = 0.7; //rudder proportional gain.
float rmax = 20;
//float rdead = 2.0;
//float rmaxerr = 14;
//float rinter = 4;
//float rmax = 17;
double err;
double Kp = 0.7;
double Ki = 0.25;
double Kd = 0.0;


double rudder_out =0;
int tail_out = 91;
int camber_out = 91;
int worm_out = 91;
double setPoint = 0;

//PID rudderPID(&err,&rudder_out,&setPoint,Kp,Ki,Kp, DIRECT);

//Digital Compass var
float Comp_heading =0;



//**HEADING HOLD AND LOOP BREAK***
//Heading only hold.
double heading=-1;//If it's negative, then we ignore it.
char comm_buffer[100];
int WPTi=999;  // get_WPTs will terminate when this index is set to 999 (ie skip get_WPTs on startup).

struct gps_int_t
{
	short int deg;
	short int min;
	short int decimin1;
	short int decimin2;
};



struct gps_int_t home[2];  //load the home base from EEPROM            
struct gps_int_t WP[2];  
struct gps_int_t current_loc_deg[2];


float BXY[2];                                                            //current location XY
float WPTXY[20][2];                                                      //Waypoints in XY
float wptxy[100][2];                                                      // sub waypoints in XY
//int WPTturn[] = {1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
int WPTturn = 1;

//station keeping

int stnkeep = 0;    //have we started the timer
int stnkeepON = 0;  //are we running the program
long int stnkeept1 = 0;  //time on entering box
long int stnkeept2 = 0;  //time
long int stnkeepsec = 270;  //total time to stay before sailing home


struct Location {
	long lat;
	long lng;
};
struct Location current_loc 		        = {0,0};		// current location for transmitting to base station

// Waypoints
// ---------

int 	wp_total			= 0;	// # of waypoints
int 	wp_index			= 1;	// Current WP index,
int     wpsub_total;                                        //subwaypoint index


//-------- Worm Gear Variables --------
float wing_pos = 0.00;                                  // This float is the position of the main wing                                              

volatile int pulse_counter = 0;                         // The number of counted pulses
float delta_wing_angle;                                 // That's the angle we want the mast to move to!!! (Using Float)

float AoA;                                        // Angle of attack 
float AoAUP = 1.5;                                     // AoA for upwind sailing
float AoADOWN = 6.5;                                    // AoA for normal sailing

int n_pulses;                                           // That's the number of Pulses that we are looking for to reach the mast angle
float n_pulses1;                                        // This Float will bring more precision before converting it in a INT

int motor = LOW;                                        // When the motor is not running, motor = LOW... When it is, motor = HIGH
                                                        // If the PROGRAM receives a new "Wind_direction" in the middle of when the motor is moving,
                                                        // it will wait that the motor stops before telling it to move to the next position.

//-------------ENDWORM------------------


void setup()
{
  

  Serial.begin(9600);         // USB
  Serial1.begin(4800);        // AIRMAR
  Serial.println("RMC SAILBOAT program start");
  
  Rudd_Servo.attach(5);
  Camb_Servo.attach(4);
  Tail_Servo.attach(3);
  Worm_Servo.attach(6);
  
  //----PID-----
  //rudderPID.SetMode(AUTOMATIC);
  //rudderPID.SetOutputLimits(-25, 25);
  
      if((token = (char*) malloc(128)) == NULL) {
    Serial.println("memory allocation failed");
  }
      if((tokenTempJ = (char*) malloc(12)) == NULL) {
    Serial.println("memory allocation failed tokenTempJ");
  }  
  
  delay(1000);
  init_compass();
  //init_AIRMAR();             //don't need to do this anymore, settings are saved to EEPROM
  get_WPTS();                  //load waypoints into the EEPROM
  eeprom2arr();                //load waypoints from EEPROM into XY var
  eeprom2rud();                //load the rudder PID values
  setcourse();
  
//---------------WORM--------------------  
  attachInterrupt(0, count, RISING);                    // Is used to count the pulses from the encoder!! (insteand of pulseIn )
}

void count(){
       pulse_counter++;                                //function that counts the pulses from encoder
}
//-------------ENDWORM------------------

void loop()
{
  //read Pilot, get control mode
  
  
  
  // 5Hz Loop {
    //read sensors

    get_AIRMAR();
    //replace below with a 5Hz timer. 
    getCompassData();
    wind_average();
    transmit();    //boradcast data/
    convertC2P();   //compass 2 polar
    boatlogic();  //find where to go - sail to the markers
    //boatlogicSUB();  //use the subwaypoints set around the markers
    wptcheck();
    //wptchecksub();
    control();
    
    stationkeep();   
    stop_loop(); 
    
    delay(50);
  //}
  
}

void stop_loop(void)
{
    //Check to see if we should return to the input waypoint loop.
    if(Serial.available()>0){ 
      comm_buffer[0] = Serial.read();
      if(comm_buffer[0]=='%')//Verify if is the loop break %
        {
          WPTi=0;//Need to reset the index to get it going.
          get_WPTS();//Back to the waypoint loader.
          eeprom2arr();                //load waypoints from EEPROM into XY var
          setcourse();
        }
    } 
}


