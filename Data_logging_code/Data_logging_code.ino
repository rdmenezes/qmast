#include <Time.h>


/** @mainpage The QMAST Alpha 6 Sailing Code
 *
 * 	@par This Documentation
 * 	Is the same style as the JavaDoc documentation. The same commands are used in
 * 	the code, and generates these pages. For info on the program used check out a
 * 	program called Doxygen.
 *
 * 	@par
 * 	Check the Doxygen site for info about the syntac used, but basically when you
 * 	are writing the source code, you put certain patterns in the comments which
 * 	doxygen can pick up later. It also scans through and figures out how all the
 * 	functions are connected together.
 *
 * 	@par
 * 	You can use this documentation page to view all of the programs source code
 * 	and figure out which function calls what. Much of the source code's original
 * 	comments have been set to show up here, though clearer commenting is definitely
 * 	necessary.
 *
 *  @par Revised by Laszlo 2011-05-13
 *  Ported to Arudino November 2010 by Christine and the supercool software team
 *  Created on: 2010-05-11
 * 	Author: Nader for MAST Software
 */
////////////////////////////////////////////////
// Changelog
////////////////////////////////////////////////
// So this is the new alpha 6 sailcode, it is a cleaned up version of alph 5 with
// added functionality and a more advanced data structures, restructured basic
// sailcode

// All bearing calculations in this code assume that the compass returns True North
// readings. ie it is adjusted for declination. If this is not true: adjust for
// declination in the Parse() function, as compass data is decoded add or subtract
// the declination

#include "LocationStruct.h"
#include <Servo.h> /// servo motor
#include <SoftwareSerial.h> /// for pololu non-buffering serial channel
#include <stdio.h>		/// for parsing - necessary?
#include <avr/io.h>
#include <Time.h> // For time stamp in Transmit()
// #include <String.h>
/** @brief Arduino doesn't look like it contains the String.h lib, however it does have
 * its own string handling support built in.
 */


// Global variables and constants
////////////////////////////////////////////////

/** @defgroup globalconstants
 * Global Constants
 * @{
 */

/** @brief Boat parameter constants in globalconstants */
#define TACKING_ANGLE 40 //the highest angle we can point

/** @brief Course Navigation constants */
#define MARK_DISTANCE 4
// the distance we have to be to a mark before moving to the next one, in meters

/** @brief Station keeping navigation constants */
#define STATION_KEEPING_RADIUS 15
// The radius we want to stay around the centre-point of the station-keeping course;
// full width is 40 meters

#define WIND_CHANGE_THRESHOLD 10
// the angle in degrees that the wind is allowed to shift by before we recalculate
// the waypoint locations (to avoid tacking)

/** @brief serial data constants */
#define BUFF_MAX 511
// serial buffer length, set in HardwareSerial.cpp in
// arduino0022/hardware/arduino/cores/arduino

/** @brief Calculation constantes */
#define DEGREE_TO_MINUTE 60
/**
* There are (approximately) 1855 meters in a minute of latitude everywhere;
* This isn't true for longitude, as it depends on the latitude. There are
* approximately 1314 m in a minute of longitude at 45 degrees north (Kingston);
* this difference will mean that if we just use deltax over deltay in minutes to
* find an angle it will be wrong
*
* there are 60 minutes in one degree
*/
#define LATITUDE_TO_METER 1855
#define LONGITUDE_TO_METER 1314 // For Kingston; change for Annapolis 1314 was Kingston value

// Error bit constants
/** @brief no data, error error bit */
#define noDataBit  0
/** @brief there is data, but buffer is full, error bit */
#define oldDataBit 1
/** @brief  indicates checksum fail on data */
#define checksumBadBit 2
/** @brief indicates that there were two commas in the data, and it has been discarded
 * and not parsed */
#define twoCommasBit 3
/** @brief Indicates data rolled over, not fast enough */
#define rolloverDataBit 4
/** @brief indicates that strtok did not return PTNTHTM, so we probably got bad data */
#define badCompassDataBit 5
/** @brief indicates the boat is falling over */
#define tooMuchRollBit 6
/** @brief indicates an error from the wind sensor */
#define badWindData 7
/** @brief indicates error in gps data */
#define badGpsData 8

// Sail control constants
/** @brief Constant which defines when the boat is "All In" */
#define ALL_IN 0
/** @brief Constant which defines when the boat is "All Out" */
#define ALL_OUT 100

// Pololu pins
/** @brief Pololu reset (digital pin on arduino) */
#define resetPin 8
/** @brief Pololu serial pin (with SoftwareSerial library) */
#define txPin 9

//Hall Effect Sensor
#define ANGLE_PIN A5
#define NO_FIELD_PIN 2
#define ZERO_VOLTS 512
int angle; 
int HallEffectParse(void);

// For serial data acquisition
/** @brief The shortest possible NMEA String */
#define SHORTEST_NMEA 5
/** @brief The longest possible NMEA String */
#define LONGEST_NMEA 120

/** @} */

/** @warning When testing by sending strings through the serial monitor, you need to select
 * "newline" ending from the dropdown beside the baud
 */

// for reliable serial data

/** @defgroup group1 SerialData
 * Variables for Serial Communications
 * @{
 */
/** Contains extra data from the Wind Sensor.
 * @warning 'clear' the extra global data buffer, because
 * any data wrapping around will be destroyed by clearing the buffer
 */
int extraWindData                                   = 0;
int extraCompassData                                = 0;
/** @brief clear the global saved XOR value */
int savedWindChecksum                               = 0;
/** @brief clear the global saved XORstate value */
int savedWindXorState                               = 0;
int savedCompassChecksum                            = 0;
int savedCompassXorState                            = 0;
/** @brief  a buffer to store roll-over data in case this data is fetched mid-line */
char extraWindDataArray[LONGEST_NMEA];
char extraCompassDataArray[LONGEST_NMEA];

//Sensor data
//Heading angle using wind sensor
float heading;       ///< heading relative to true north, do not use, only updating 2 times a second
float deviation;     ///< deviation relative to true north; do we use this in our calculations? Nope
float variance;      ///< variance relative to true north; do we use this in our calculations? Nope
// Boat's speed
float bspeed;        ///< Boat's speed in km/h
float bspeedk;       ///< Boat's speed in knots

// Wind data
float wind_angl;     ///< wind angle, (relative to boat I believe, could be north, check this)
float wind_velocity; ///< wind velocity in knots

//Compass data
float headingc; ///< Heading from compass
float pitch; 	///< pitch
float roll; 	///< roll
float trueWind; ///< wind direction calculated at checkteck


int rudderVal; //!< variables for transmiting data
int mainVal;   //!< variables for transmiting data
float headingVal;       ///< where we are going, temporary compass smoothing test
float distanceVal;      ///< distance to next waypoint one-shots, no averaging, present conditions
float heading_newest;   ///< heading relative to true north
float wind_angl_newest; ///< wind angle, (relative to boat)

/** Pololu for connecting via a nonbuffered serial port to pololu -output only. */
SoftwareSerial servo_ser = SoftwareSerial(7, txPin);

int rudderDir = -1;   ///< global for reversing rudder if we are parking lot testing
int points;           ///< max waypoints selected for travel
int point;            ///< point for sail to waypoint in menu
int currentPoint = 0; ///< current waypoint on course of travel


long startTime;     //!< station-keeping global
int stationCounter; //!< station-keeping global
boolean timesUp;    //!< station-keeping global

/** The amount of time the boat should stay in the box before leaving (in millis).
 * To be adjusted based on intuition day of
 */
int StationKeepingTimeInBox = 270000;

//
boolean tacking; //!< tacking global
/** tacking global.
 * 1 for left -1 for right
 */
int tackingSide;
int ironTime; //!< tacking global

int errorCode; //!< error code

int angleOut; //for hall effect sensor
int HallEffectParse(void);

/** @} End of the global constants grouping*/

/** Standard Setup function for Arduino, set pins and create object instances.
 *
 * The setup function is the first function to be called. When it exits, the
 * loop function is immediately called, where the program remains.
 *
 * Also sets up the compass through serial commands.
 *
 * @warning In order for Pololu to work, it needs to be manually reset within
 * the code. Because of this, a 2 second delay is present to allow the board
 * to start-up before the reset occurs.
 */
void setup() {
    Serial.begin(9600);
    
    delay(2000);
    // next NEED to explicitly reset the Pololu board using a separate pin
    // else it times out and reports baud rate is too slow (red LED)
    digitalWrite(resetPin, 0);
    delay(10);
    digitalWrite(resetPin, 1);

    Serial2.begin(19200);
    Serial3.begin(4800);

    delay(10);

    // Initialize all counters/variables and current position from sensors
    // ---------------------------------------------------------------------------
    boatLocation = clearPoints;    // sets initial location of the boat to 0;

    // Heading angle using wind sensor
    // See global declaration for explanation
    heading = 0;
    deviation = 0;
    variance = 0;

    //Boat's speed
    bspeed = 0;           // Boat's speed in km/h
    bspeedk = 0;          // Boat's speed in knots

    // Wind data
    wind_angl = 0;        // wind angle, (relative to boat)
    wind_velocity = 0;    // wind velocity in knots

    // Compass data
    headingc = 0;         // heading relative to true north
    pitch = 0;            // pitch relative to ??
    roll = 0;             // roll relative to ??

    // Testing variables; present conditions, used for testing
    heading_newest = 0;   // heading relative to true north, newest
    wind_angl_newest = 0; // wind angle relative to boat

    // Compass setup code
    // ---------------------------------------------------------------------------
    // Give everything some time to set up, especially the serial buffers
    delay(1000);

    // request a data sample from the compass for heading/tilt/etc, and give it
    // time to get it
    Serial2.println("$PTNT,HTM*63");
    delay(200);
    // wind sensor setup code, changes rates
    Serial3.println("$PAMTC,EN,RMC,0,10");     // disable GPRMC
    // change gps to send 3.3 times a second
    Serial3.println("$PAMTC,EN,GLL,1,3");
    // change heading to send 2 times a second
    Serial3.println("$PAMTC,EN,HDG,1,5");

    /** @brief Change wind to send 5 times a second default for now, need to make
     *  sure we can get everything out of the buffer
     */
    Serial.println("$PAMTC,EN,MWVR,1,2");

    delay(2000);  //setup delay RCMode();
}

/** Main Function, handles menu input and calls the core functions.
 *
 * A lot of documentation should probably be written for this, but
 * all I know right now is that it contains the switch statement
 * in order to call the functions.
 */
void loop() {
    int menuReturn;

    transmit();
    sensorData(BUFF_MAX, 'w');
    sensorData(BUFF_MAX, 'c');
    angleOut = HallEffectParse();
    Serial.println("Angle:");
    Serial.println(angleOut);
    Serial.println("\n");
    
    delay(100);
}



