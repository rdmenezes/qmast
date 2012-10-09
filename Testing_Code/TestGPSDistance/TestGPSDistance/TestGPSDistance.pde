#include "structures.h"


#define DEGREE_TO_MINUTE 60 //there are 60 minutes in one degree
#define LATITUDE_TO_METER 1855 // there a
#define LONGITUDE_TO_METER 1314 //for 

int radiansToDegrees(float angle){
  return 180*angle/PI;
}

double GPSdistance(struct points location1, struct points location2){
  //finds the distance between two latitude, longitude gps coordinates, in meters
    double deltaLat, deltaLong; //distance in x and y directions
    double distance;
    
    deltaLong = (location2.lonDeg - location1.lonDeg)*DEGREE_TO_MINUTE + (location2.lonMin - location1.lonMin); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
    deltaLat = (location2.latDeg - location1.latDeg)*DEGREE_TO_MINUTE + (location2.latMin - location1.latMin); //y is the east/west coordinate, + in the east direction
//     Serial.println(deltaLat,5);
//    Serial.println(deltaLong,5);
    //convert to meters, based on the number of meters in a minute, looked up for the given latitude
    deltaLat = deltaLat*LATITUDE_TO_METER; 
    deltaLong = deltaLong*LONGITUDE_TO_METER;
//    Serial.println("");
//    Serial.println(deltaLat);
//    Serial.println(deltaLong);
//    Serial.println("");
    deltaLat = deltaLat*deltaLat;
    deltaLong = deltaLong*deltaLong;
    distance = deltaLat + deltaLong;
    distance = sqrt (distance);     
    
    return distance;
}

void setup(){
  Serial.begin(9600);
  //boatLocation = {44.0, 13.6803, -76.0, 29.5175};
  //coursePoints[1] = {44.0, 13.6927, -76.0, 29.5351};
}


void loop(){
  float dirn;
  int i;
  double delX;
  double delY;
  double result;
  for(i = 0 ; i < 4; i++){ 
  dirn = GPSdistance(waypoints[i],boatLocation);
  Serial.println(dirn);
  delay(5000);
  
  }

}
