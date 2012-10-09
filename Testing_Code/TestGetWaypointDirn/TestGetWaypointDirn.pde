#include "structures.h"


#define DEGREE_TO_MINUTE 60 //there are 60 minutes in one degree
#define LATITUDE_TO_METER 1850 // there are (approximately) 1855 meters in a minute of latitude everywhere; this isn't true for longitude, as it depends on the latitude
//there are approximately 1314 m in a minute of longitude at 45 degrees north (Kingston); this difference will mean that if we just use deltax over deltay in minutes to find an angle it will be wrong
#define LONGITUDE_TO_METER 1464 //for kingston; change for Annapolis 1314 was kingston value
//motor control constants (deprecated, these need updating)

int radiansToDegrees(float angle){
  return 180*angle/PI;
}
int getWaypointDirn(struct points waypoint){
// computes the compass heading to the waypoint based on the latest known position of the boat and the present waypoint, both in global variables
// first converting minutes to meters
  float waypointHeading;//the heading to the waypoint from where we are
  int integerHeading;
  float deltaX, deltaY; //the difference between the boats location and the waypoint in x and y

  // there are (approximately) 1855 meters in a minute of latitude; this isn't true for longitude, as it depends on the latitude
  //there are approximately 1314 m in a minute of longitude at 45 degrees north; this difference will mean that if we just use deltax over deltay in minutes to find an angle it will be wrong

  deltaX = (waypoint.latDeg - boatLocation.latDeg)*DEGREE_TO_MINUTE + (waypoint.latMin - boatLocation.latMin); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
  deltaY = (waypoint.lonDeg - boatLocation.lonDeg)*DEGREE_TO_MINUTE + (waypoint.lonMin - boatLocation.lonMin); //y is the east/west coordinate, + in the east direction
  deltaX = deltaX*LATITUDE_TO_METER;
  deltaY = deltaY*LONGITUDE_TO_METER;
   Serial.println(deltaX);
   Serial.println(deltaY);
  waypointHeading = atan2(deltaY, deltaX); // atan2 returns -pi to pi, taking account of which variables are positive to put in proper quadrant 
  Serial.println(waypointHeading);
  waypointHeading = radiansToDegrees(waypointHeading);
  Serial.println(waypointHeading);
  //normalize direction
  if (waypointHeading < 0)
    waypointHeading += 360;
  else if (waypointHeading > 360)
    waypointHeading -= 360;
  integerHeading = waypointHeading;  
  return integerHeading;
}
void setup(){
  Serial.begin(9600);
  //boatLocation = {44.0, 13.6803, -76.0, 29.5175};
  //coursePoints[1] = {44.0, 13.6927, -76.0, 29.5351};
}


void loop(){
  int dirn;
  int i;
  double delX;
  double delY;
  double result;
  for(i = 0 ; i < 4; i++){ 
  dirn = getWaypointDirn(waypoints[i]);
  Serial.println(dirn);
  delay(5000);
//  delX = (waypoints[i].latDeg - boatLocation.latDeg)*DEGREE_TO_MINUTE + (waypoints[i].latMin - boatLocation.latMin);
//  delY = (waypoints[i].lonDeg - boatLocation.lonDeg)*DEGREE_TO_MINUTE + (waypoints[i].lonMin - boatLocation.lonMin);
//  Serial.println(delX,5);
//  Serial.println(delY,5);
//  delX = delX*LATITUDE_TO_METER;
//  delY = delY*LONGITUDE_TO_METER;
//  Serial.print("distance from middle lampost to ");
//  Serial.println(i);
//   Serial.println(delX,5);
//  Serial.println(delY,5);
//  result = delX/delY;
//  Serial.println(result,5);
//  result = atan(result);
//  result = radiansToDegrees(result);
//  Serial.println("");
//    Serial.println("");
//      Serial.println(result);
//        Serial.println("");
//     result = atan2(-62.32773,-22.07510);
//     result = radiansToDegrees(result);
//    Serial.println(result);
//    
//    result = atan2(-39.32456,-45.20283);
//      result = radiansToDegrees(result);
//    Serial.println(result);
  }
//  result = atan2(10.0,10.0)*180/PI;
//  Serial.println(result),4;
//    result = atan2(-10.0,10.0)*180/PI;
//  Serial.println(result),4;
//    result = atan2(10.0,-10.0)*180/PI;
//  Serial.println(result),4;
//    result = atan2(-10.0,-10.0)*180/PI;
//  Serial.println(result),4;
//  delay(5000);
}
