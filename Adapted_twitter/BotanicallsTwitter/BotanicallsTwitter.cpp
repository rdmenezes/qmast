#include "WProgram.h"
// Botanicalls allows plants to ask for human help.
// Rob Faludi  http://www.faludi.com with additional code from various public examples
// including LadyAda's Twitter and Software Serial examples
// http://www.botanicalls.com
// Botanicalls is a project with Kati London, Rob Faludi, Kate Hartman and Rebecca Bray


#define VERSION "2.15" // initial leaf board


///// BOTANICALLS DEFINTIONS ////////
#define USERNAMEPASS "Botanicalls0138:SnuFfy_reebok8"  // your twitter username and password, seperated by a :

#define MOIST 425 // minimum level of satisfactory moisture
#define DRY 300  // maximum level of tolerable dryness
#define SOAKED 575 // minimum desired level after watering
#define WATERING_CRITERIA 115 // minimum change in value that indicates watering

#define MOIST_SAMPLE_INTERVAL 120 // seconds over which to average moisture samples
#define WATERED_INTERVAL 60 // seconds between checks for watering events

#define TWITTER_INTERVAL 1// minimum seconds between twitter postings

#define MOIST_SAMPLES 10 //number of moisture samples to average

void setup();
void loop();
void moistureCheck();
void wateringCheck();
void notify( uint8_t resp);
void moistLight (int wetness);
void buttonCheck();
uint8_t serialavail_timeout(int timeout);
uint8_t readline_timeout(int timeout);
uint8_t XPort_reset(void);
uint8_t XPort_disconnected(void);
uint8_t XPort_connect(char *ipaddr, long port);
void XPort_flush(int timeout);
uint8_t posttweet(char *tweet);
void base64encode(char *s, char *r);
void ROM_putstring(const char *str, uint8_t nl);
void ROM_putstringSS(const char *str, uint8_t nl);
void uart_putchar(char c);
void uart_putcharSS(char c);
void blinkLED(byte targetPin, int numBlinks, int blinkRate);
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




//function for checking soil moisture against threshold
void moistureCheck() {
  static int counter = 1;//init static counter
  int moistAverage = 0; // init soil moisture average
  if((millis() - lastMoistTime) / 1000 > (MOIST_SAMPLE_INTERVAL / MOIST_SAMPLES)) {
    for(int i = MOIST_SAMPLES - 1; i > 0; i--) {
      moistValues[i] = moistValues[i-1]; //move the first measurement to be the second one, and so forth until we reach the end of the array.   
    }
    digitalWrite(PROBEPOWER, HIGH);
    moistValues[0] = analogRead(MOISTPIN);//take a measurement and put it in the first place
    digitalWrite(PROBEPOWER, LOW);
    lastMoistTime = millis();
    int moistTotal = 0;//create a little local int for an average of the moistValues array
    for(int i = 0; i < MOIST_SAMPLES; i++) {//average the measurements (but not the nulls)
      moistTotal += moistValues[i];//in order to make the average we need to add them first 
    }
    if(counter<MOIST_SAMPLES) {
      moistAverage = moistTotal/counter;
      counter++; //this will add to the counter each time we've gone through the function
    }
    else {
      moistAverage = moistTotal/MOIST_SAMPLES;//here we are taking the total of the current light readings and finding the average by dividing by the array size
    } 
    //lastMeasure = millis();
    Serial.print("moist: ");
    Serial.println(moistAverage,DEC); 

    ///return values
    if ((moistAverage < DRY)  &&  (lastMoistAvg >= DRY)  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
      uint8_t response = posttweet("URGENT! Water me!");   // announce to Twitter
      notify(response); 
    }
    else if  ((moistAverage < MOIST)  &&  (lastMoistAvg >= MOIST)  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
      uint8_t response = posttweet("Water me please.");   // announce to Twitter
      notify(response); 
    }
    lastMoistAvg = moistAverage; // record this moisture average for comparision the next time this function is called
    moistLight(moistAverage);
  }
}


//function for checking for watering events
void wateringCheck() {
  int moistAverage = 0; // init soil moisture average
  if((millis() - lastWaterTime) / 1000 > WATERED_INTERVAL) {
    digitalWrite(PROBEPOWER, HIGH);
    int waterVal = analogRead(MOISTPIN);//take a moisture measurement
    digitalWrite(PROBEPOWER, LOW);
    lastWaterTime = millis();

    Serial.print("watered: ");
    Serial.println(waterVal,DEC);
    if (waterVal >= lastWaterVal + WATERING_CRITERIA) { // if we've detected a watering event
      if (waterVal >= SOAKED  &&  lastWaterVal < MOIST &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL))) {
        uint8_t response = posttweet("Thank you for watering me!");  // announce to Twitter
        notify(response); 
      }
      else if  (waterVal >= SOAKED  &&  lastWaterVal >= MOIST  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
        uint8_t response = posttweet("You over watered me.");   // announce to Twitter
        notify(response); 
      }
      else if  (waterVal < SOAKED  &&  lastWaterVal < MOIST  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
        uint8_t response = posttweet("You didn't water me enough.");   // announce to Twitter
        notify(response); 
      }
    }    
    lastWaterVal = waterVal; // record the watering reading for comparison next time this function is called
  }
}


// function that prints twitter results to debug port
void notify( uint8_t resp) {
  if (resp)
    putstring_nl("tweet ok");
  else {
    putstring_nl("tweet fail");
    blinkLED(COMMLED,2,500);
  }
}


void moistLight (int wetness) {
  if (wetness < DRY) {
    blinkLED(MOISTLED, 6, 50);
    analogWrite(MOISTLED, 8);
  }
  else if (wetness < MOIST) {
    blinkLED(MOISTLED, 2, 500);
    analogWrite(MOISTLED, 24);
  }
  else {
    analogWrite(MOISTLED,wetness/4); // otherwise display a steady LED with brightness mapped to moisture
  }
}


void buttonCheck() { 
  static boolean lastSwitch = HIGH;
  static boolean lineEnding = false;
  if (digitalRead(SWITCH) == LOW && lastSwitch == HIGH) {

    digitalWrite(PROBEPOWER, HIGH);
    long moistLevel = analogRead(MOISTPIN);
    digitalWrite(PROBEPOWER, LOW);

    char *str1 = "Current Moisture: ";
    char *str2;
    str2= (char*) calloc (4,sizeof(char)); // allocate memory to string 2
    char *str3 = "%";
    char *str4 = "."; // a period ends every other tweet so there are no repeats

    itoa((moistLevel*100)/800,str2,10); //moisture is on a scale from 0 to 790.
    char *message;
    message = (char *)calloc(strlen(str1) + strlen(str2) + strlen(str3) + strlen(str4) + 1, sizeof(char));
    strcat(message, str1);
    strcat(message, str2);
    strcat(message, str3);   
    lineEnding = !lineEnding; // flip the line ending bit so every test is different (twitter won't post repeats)
    if (lineEnding)  strcat(message, str4);
    uint8_t response = posttweet(message);   // announce to Twitter
    free(message);
    free(str2);
    notify(response);  
    if (digitalRead(SWITCH) == LOW) { // if switch is held down, send a second tweet with the version number
      digitalWrite(XPORT_RESETPIN, LOW); // hold XPort in reset when it's not in use
      blinkLED(COMMLED,4,1000);
      char *message;
      char *str1 = "v";
      message = (char *)calloc(strlen(str1) + strlen(VERSION) + 1, sizeof(char));
      strcat(message, str1);
      strcat(message, VERSION);
      uint8_t response = posttweet(message);   // announce to Twitter
      free(message);
      notify(response);  
    }
  }
  lastSwitch = digitalRead(SWITCH);
}

// adapted from Twitter Code http://www.ladyada.net

/***********************SOFTWARE UART*************************/

uint8_t serialavail_timeout(int timeout) {  // in ms

  while (timeout) {
    if (mySerial.available()) {
      if (XPORT_CTSPIN) { // we read some stuff, time to stop!
        digitalWrite(XPORT_CTSPIN, HIGH);
      }
      return 1;
    }
    // nothing in the queue, tell it to send something
    if (XPORT_CTSPIN) {
      digitalWrite(XPORT_CTSPIN, LOW);
    }
    timeout -= 1;
    delay(1);
  }
  if (XPORT_CTSPIN) { // we may need to process some stuff, so stop now
    digitalWrite(XPORT_CTSPIN, HIGH);
  }
  return 0;
}

uint8_t readline_timeout(int timeout) {
  uint8_t idx=0;
  char c;
  while (serialavail_timeout(timeout)) {
    c = mySerial.read();
    linebuffer[idx++] = c;
    if ((c == '\n') || (idx == 255)) {
      linebuffer[idx] = 0;
      errno = ERROR_NONE;
      return idx;
    }
  }
  linebuffer[idx] = 0;
  errno = ERROR_TIMEDOUT;
  return idx;
}

/********************XPORT STUFF**********************/

uint8_t XPort_reset(void) {
  char d;

  // 200 ms reset pulse

  delay(200);
  digitalWrite(XPORT_RESETPIN, HIGH);

  // wait for 'D' for disconnected
  if (serialavail_timeout(20000)) { // 20 second timeout 
    d = mySerial.read();
    //putstring("Read: "); Serial.print(d, HEX);
    if (d != 'D'){
      return ERROR_BADRESP;
    } 
    else {
      return 0;
    }
  }
  return ERROR_TIMEDOUT;
}  

uint8_t XPort_disconnected(void) {
  if (XPORT_DTRPIN != 0) {
    return digitalRead(XPORT_DTRPIN);
  } 
  return 0;
}


uint8_t XPort_connect(char *ipaddr, long port) {
  char ret;

  mySerial.print('C');
  mySerial.print(ipaddr);
  mySerial.print('/');
  mySerial.println(port);
  // wait for 'C'
  if (serialavail_timeout(5000)) { // 5 second timeout 
    ret = mySerial.read();
    putstring("Read: "); 
    Serial.print(ret, HEX);
    if (ret != 'C') {
      return ERROR_BADRESP;
    }
  } 
  else { 
    return ERROR_TIMEDOUT; 
  }
  return 0;
}

void XPort_flush(int timeout) {
  while (serialavail_timeout(timeout)) {
    mySerial.read();
  }
}

/********************TWITTER STUFF**********************/

uint8_t posttweet(char *tweet) {
  uint8_t ret=0;
  uint8_t success = 0;

  analogWrite(COMMLED,72); // light comm status light dimly
  ret = XPort_reset();
  //Serial.print("Ret: "); Serial.print(ret, HEX);
  switch (ret) {
  case  ERROR_TIMEDOUT: 
    { 
      blinkLED(COMMLED,4,500);
      putstring_nl("Timed out on reset! Check XPort config & IP"); 
      return 0;
    }
  case ERROR_BADRESP:  
    { 
      blinkLED(COMMLED,6,500);
      putstring_nl("Bad response on reset!");
      return 0;
    }
  case ERROR_NONE: 
    { 
      putstring_nl("Reset OK!");
      break;
    }
  default:
    blinkLED(COMMLED,8,500);
    putstring_nl("unknown error"); 
    return 0;
  }

  // time to connect...

  ret = XPort_connect(IPADDR, PORT);
  switch (ret) {
  case  ERROR_TIMEDOUT: 
    { 
      blinkLED(COMMLED,10,500);
      putstring_nl("Timed out on connect"); 
      return 0;
    }
  case ERROR_BADRESP:  
    { 
      blinkLED(COMMLED,12,500);
      putstring_nl("Failed to connect");
      return 0;
    }
  case ERROR_NONE: 
    { 
      putstring_nl("Connected..."); 
      break;
    }
  default:
    blinkLED(COMMLED,12,500);
    putstring_nl("Unknown error"); 
    return 0;
  }

  base64encode(USERNAMEPASS, linebuffer);

  // send the HTTP command, ie "GET /username/"
  putstringSS("POST "); 
  putstringSS(HTTPPATH);
  putstringSS_nl(" HTTP/1.1");
  putstring("POST "); 
  putstring(HTTPPATH); 
  putstring_nl(" HTTP/1.1");
  // next, the authentication
  putstringSS("Host: "); 
  putstringSS_nl(IPADDR);
  putstring("Host: "); 
  putstring_nl(IPADDR);
  putstringSS("Authorization: Basic ");
  putstring("Authorization: Basic ");
  mySerial.println(linebuffer);
  Serial.println(linebuffer);
  putstringSS("Content-Length: "); 
  mySerial.println(7+strlen(tweet), DEC);
  putstring("Content-Length: "); 
  Serial.println(7+strlen(tweet), DEC);
  putstringSS("\nstatus="); 
  mySerial.println(tweet);
  putstring("\nstatus="); 
  Serial.println(tweet);

  mySerial.print("");  

  while (1) {
    // read one line from the xport at a time
    ret = readline_timeout(3000); // 3s timeout
    // if we're using flow control, we can actually dump the line at the same time!
    Serial.print(linebuffer);
    if (strstr(linebuffer, "HTTP/1.1 200 OK") == linebuffer)
      success = 1;

    if (((errno == ERROR_TIMEDOUT) && XPort_disconnected()) ||
      ((XPORT_DTRPIN == 0) &&
      (linebuffer[0] == 'D') && (linebuffer[1] == 0)))  {
      putstring_nl("\nDisconnected...");
      return success;
    }
  }
}


void base64encode(char *s, char *r) {
  char padstr[4];
  char base64chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  uint8_t i, c;
  uint32_t n;

  c = strlen(s) % 3;
  if (c > 0) { 
    for (i=0; c < 3; c++) { 
      padstr[i++] = '='; 
    } 
  }
  padstr[i]=0;

  i = 0;
  for (c=0; c < strlen(s); c+=3) { 
    // these three 8-bit (ASCII) characters become one 24-bit number
    n = s[c]; 
    n <<= 8;
    n += s[c+1]; 
    if (c+2 > strlen(s)) {
      n &= 0xff00;
    }
    n <<= 8;
    n += s[c+2];
    if (c+1 > strlen(s)) {
      n &= 0xffff00;
    }

    // this 24-bit number gets separated into four 6-bit numbers
    // those four 6-bit numbers are used as indices into the base64 character list
    r[i++] = base64chars[(n >> 18) & 63];
    r[i++] = base64chars[(n >> 12) & 63];
    r[i++] = base64chars[(n >> 6) & 63];
    r[i++] = base64chars[n & 63];
  }
  i -= strlen(padstr);
  for (c=0; c<strlen(padstr); c++) {
    r[i++] = padstr[c];  
  }
  r[i] = 0;
  Serial.println(r);
}


//// Functions that save RAM memory by putting strings into program ROM
//// LadyAda.net
void ROM_putstring(const char *str, uint8_t nl) {
  uint8_t i;

  for (i=0; pgm_read_byte(&str[i]); i++) {
    uart_putchar(pgm_read_byte(&str[i]));
  }
  if (nl) {
    uart_putchar('\n'); 
    uart_putchar('\r');
  }
}

void ROM_putstringSS(const char *str, uint8_t nl) {
  uint8_t i;

  for (i=0; pgm_read_byte(&str[i]); i++) {
    uart_putcharSS(pgm_read_byte(&str[i]));
  }
  if (nl) {
    uart_putcharSS('\n');
  }
}

void uart_putchar(char c) {
  while (!(UCSR0A & _BV(UDRE0)));
  UDR0 = c;
}

void uart_putcharSS(char c) {
  mySerial.print(c);
}


// this function blinks the an LED light as many times as requested
void blinkLED(byte targetPin, int numBlinks, int blinkRate) {
  for (int i=0; i<numBlinks; i++) {
    digitalWrite(targetPin, HIGH);   // sets the LED on
    delay(blinkRate);                     // waits for a blinkRate milliseconds
    digitalWrite(targetPin, LOW);    // sets the LED off
    delay(blinkRate);
  }
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

