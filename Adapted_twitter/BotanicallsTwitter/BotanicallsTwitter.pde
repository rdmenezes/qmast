// Botanicalls allows plants to ask for human help.
// Rob Faludi  http://www.faludi.com with additional code from various public examples
// including LadyAda's Twitter and Software Serial examples
// http://www.botanicalls.com
// Botanicalls is a project with Kati London, Rob Faludi, Kate Hartman and Rebecca Bray


#define VERSION "2.15" // initial leaf board


///// BOTANICALLS DEFINTIONS ////////
#define USERNAMEPASS "botanicalls1:dirtynails"  // your twitter username and password, seperated by a :

#define MOIST 425 // minimum level of satisfactory moisture
#define DRY 300  // maximum level of tolerable dryness
#define SOAKED 575 // minimum desired level after watering
#define WATERING_CRITERIA 115 // minimum change in value that indicates watering

#define MOIST_SAMPLE_INTERVAL 120 // seconds over which to average moisture samples
#define WATERED_INTERVAL 60 // seconds between checks for watering events

#define TWITTER_INTERVAL 1// minimum seconds between twitter postings

#define MOIST_SAMPLES 10 //number of moisture samples to average

int moistValues[MOIST_SAMPLES];

#define LEDPIN 13 // generic status LED
#define MOISTPIN 0 // moisture input is on analog pin 0
#define PROBEPOWER 8 // feeds power to the moisture probes
#define MOISTLED 9  // LED that indicates the plant needs water
#define COMMLED 10 // LED that indicates communication status
#define SWITCH 12// input for normally open momentary switch

unsigned long lastMoistTime=0; // storage for millis of the most recent moisture reading
unsigned long lastWaterTime=0; // storage for millis of the most recent watering reading
unsigned long lastTwitterTime=0; // storage for millis of the most recent Twitter message

int lastMoistAvg=0;
int lastWaterVal=0;

///// TWITTER DEFINITIONS ///////
#include "AFSoftSerial.h"
#include "avr/io.h"
#include "string.h"
#include "avr/pgmspace.h"

// defines for putstring function that saves RAM memory
#define putstring(x) ROM_putstring(PSTR(x), 0)
#define putstring_nl(x) ROM_putstring(PSTR(x), 1)
#define putstringSS(x) ROM_putstringSS(PSTR(x), 0)
#define putstringSS_nl(x) ROM_putstringSS(PSTR(x), 1)

#define IPADDR "128.121.146.100"  // twitter.com
#define PORT 80                   // HTTP
#define HTTPPATH "/statuses/update.xml"      // the person we want to follow

#define TWEETLEN 141
char linebuffer[256]; // oi
int lines = 0;

#define XPORT_RXPIN 3 // pin definitions for connection to XPort Shield
#define XPORT_TXPIN 2 
#define XPORT_RESETPIN 4
#define XPORT_DTRPIN 5
#define XPORT_CTSPIN 6
#define XPORT_RTSPIN 7

#define ERROR_NONE 0 // defines numbers for error messages

#define ERROR_TIMEDOUT 2
#define ERROR_BADRESP 3
#define ERROR_DISCONN 4
uint8_t errno;

AFSoftSerial mySerial =  AFSoftSerial(XPORT_RXPIN, XPORT_TXPIN); // start up Ladyada version of software serial

uint32_t laststatus = 0, currstatus = 0;


void setup()  { 

  uint8_t ret;

  pinMode(LEDPIN, OUTPUT);
  pinMode(PROBEPOWER, OUTPUT);
  pinMode(MOISTLED, OUTPUT);
  pinMode(COMMLED, OUTPUT);
  pinMode(SWITCH, INPUT);
  digitalWrite(SWITCH, HIGH); // turn on internal pull up resistors

  for(int i = 0; i < MOIST_SAMPLES; i++) { // initialize moisture value array
    moistValues[i] = 0; 
  }
  digitalWrite(PROBEPOWER, HIGH);
  lastWaterVal = analogRead(MOISTPIN);//take a moisture measurement to initialize watering value
  digitalWrite(PROBEPOWER, LOW);

  Serial.begin(9600);   // set the data rate for the hardware serial port
  mySerial.begin(9600);   // set the data rate for the software serail port
  putstring_nl("");   // begin printing to debug output
  putstring("Botanicalls v");
  putstring_nl(VERSION);
  if(digitalRead(SWITCH)==LOW) { // show the username and password if the test switch is held on startup
  putstring("ID: ");
  putstring_nl(USERNAMEPASS);
  }

  // xport
  pinMode(XPORT_RESETPIN, OUTPUT); // set input and output properly for XPort shield
  if (XPORT_DTRPIN) {
    pinMode(XPORT_DTRPIN, INPUT);
  }
  if (XPORT_CTSPIN) {
    pinMode(XPORT_CTSPIN, OUTPUT);
  }
  if (XPORT_RTSPIN) {
    pinMode(XPORT_RTSPIN, INPUT);
  }

  // uint8_t response = posttweet("Botanicalls!");  // send a startup message to Twitter
  // notify(response);
  blinkLED(COMMLED,2,200); // version 2
  delay(200);
  blinkLED(COMMLED,1,200); // point 1
  delay(200);
  blinkLED(COMMLED,5,200); // point 5

  analogWrite(MOISTLED, 36);
}


void loop()       // main loop of the program     
{

  moistureCheck(); // check to see if moisture levels require Twittering out
  wateringCheck(); // check to see if a watering event has occured to report it
  buttonCheck(); // check to see if the debugging button is pressed
  analogWrite(COMMLED,0); // douse comm light if it was on
  digitalWrite(XPORT_RESETPIN, LOW); // hold XPort in reset when it's not in use to lower current draw
}



