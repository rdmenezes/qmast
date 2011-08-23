
void getStationKeepingCentre(double *centreLatMin, double *centreLonMin){
  //this function averages the GPS locations to find the centre point of the rectangle; has to be tested on Arduino

  double sumLatMin = 0;
  double sumLonMin = 0;  
  int i;//counter
  
  for (i = 0; i < 4; i++)
  {
      sumLatMin+= stationPoints[i].latMin;
      sumLonMin+= stationPoints[i].lonMin;
  }  
  *centreLatMin = sumLatMin/4;
  *centreLonMin = sumLonMin/4;
  
  Serial.print("Station keeping centre (minutes only): ");
  Serial.print(*centreLatMin);
  Serial.print(", ");
  Serial.println(*centreLonMin); 
}

void fillStationKeepingWaypoints(double centreLatMin, double centreLonMin, int windBearing){
  
  double deltaLat;
  double deltaLon;
  int i;
  
  //distance in meters from midpoint to each mark is in STATION_KEEPING_RADIUS; this is the hypotenuse of a lat/long right angled triangle  
  //the wind bearing is the angle from north to the direction the wind is coming from
  //it's also the direction we're putting the mark (want one mark directly upwind, 90 degrees to wind, downwind, -90 degrees)
  
  for (i = 0; i < 4; i++){
      deltaLat = STATION_KEEPING_RADIUS*cos(windBearing+90*i)/LATITUDE_TO_METER; //latitude is along the north vector
      deltaLon = STATION_KEEPING_RADIUS*sin(windBearing+90*i)/LONGITUDE_TO_METER; //longitude is perpendicular to the north vector
      floatingStationPoints[i].latMin = deltaLat + centreLatMin;
      floatingStationPoints[i].lonMin = deltaLon + centreLonMin;
      floatingStationPoints[i].latDeg = stationPoints[i].latDeg;
      floatingStationPoints[i].latMin = stationPoints[i].latMin;
  }   
}

//before calling this, need to set startTime global to millis() and timesUp global to false
int stationKeep(){
  //update the waypoints every bit to make sure we're compensating for the wind correctly
  //straightsail to the waypoints
  //ensure we've reached each waypoint before going to the next one
  
  // this function presently sails in a square with radius 15m from the centre-point; 
  //sailing between waypoints 1 and 3 will have the boat sailing in a beam reach (90 degrees to wind) always and may be more successful
  //this logic may fail (or at least take a long time to leave the box) in very light winds

//Tacking vs downwindCorridor:
//- for stationKeeping, sailtoWaypoint calls downwindCorridor, with the default 10m width;
//- if waypoints are set properly, it shouldnt ever be downwind, so dont need to worry about downwindCorridor
//- but if it calls it, this 10m width is too wide for a 5m barrier
//- can just call tack when we switch waypoints, assume that everything is fine :) instead of just turning, this will prevent failures but may lead to the boat leaving the box
//
//
//Future station-keeping strategy:
//- figure 8 at the top of the box (towards the middle to allow for tacking radius); check time before tacking to see if we should just leave the box
//- exit at bottom if theres time to kill before 5 minutes, if short time keep sailing straight to exit faster
//- sail down edge and check time, leave as 5 minutes hits

  // setup waypoints (takes first 4 waypoints frm the waypoints struct
  double centreLatMin, centreLonMin;
  int windDirn, waypointWindDirn;
  int distanceToWaypoint;//the boat's distance to the present waypoint  
  //Timer variables
  long elapsedTime, currentTime;
  
  //set up waypoints
  getStationKeepingCentre(&centreLatMin, &centreLonMin); //find the centre of the global stationkeeping corner variables maybe move this to menu? only needs to be done once
  windDirn = getWindDirn(); //find the wind direction so we can set out waypoints downwind from it
  waypointWindDirn = windDirn;
  fillStationKeepingWaypoints(centreLatMin, centreLonMin, windDirn);//set global station keeping waypoints  
  
  //sail between waypoints until 5 minute timer is up      
  if(timesUp == true){         //leave square; can either calculate the closest place to leave, or just head downwind as we do here:     
      windDirn = getWindDirn();
      sail(windDirn+90); //sail out of box in beam reach
      delay(100);//give rudder time to adjust? this might not be necessary 
      return 0;
  }
  else{
      stayPoint = floatingStationPoints[stationCounter];             
      distanceToWaypoint = GPSdistance(boatLocation, stayPoint);//returns in meters        
        //set rudder and sails          
      sailToWaypoint(stayPoint); //sets the rudder, stays in corridor if sailing upwind          
        //check timer
      currentTime = millis(); //get the Arduino clock time              
      elapsedTime = currentTime - startTime;//calculate elapsed miliseconds since the start of the 5 minute loop
      if(elapsedTime > StationKeepingTimeInBox){ // (5min) * (60s/min) * (1000ms/s)
          timesUp = true;
          distanceToWaypoint = GPSdistance(boatLocation, stayPoint);//returns in meters
      } //end go to waypoint
      if(distanceToWaypoint < MARK_DISTANCE){
          stationCounter+=2;        //make global
              if(stationCounter == 5)       
                  stationCounter = 0;
              }    
               //loop the whole go to waypoint, check sensors and go to next waypoint until the time is up
      }   
      return 0;
   }
   
//need to set same timesUp and startTime as above and also stayPoint   
void stationKeepSinglePoint(){
  double centreLatMin, centreLonMin;
  static struct points stayPoint;
  int windDirn;
  
  getStationKeepingCentre(&centreLatMin, &centreLonMin); //find the centre of the global stationkeeping corner variables
  stayPoint.latDeg = 44;
  stayPoint.latMin = centreLatMin;
  stayPoint.lonDeg = -76;
  stayPoint.lonMin = centreLonMin;
  long currentTime = millis();
  long elapsedTime = currentTime - startTime;
  if (elapsedTime > StationKeepingTimeInBox) // if the specified time has passed (4.5 minutes by default), start to exit
  {
      timesUp = true;
  }
  
  if(timesUp == true){         //leave square; can either calculate the closest place to leave, or just head in beam reach as we do here:      
      windDirn = getWindDirn();
      sail(windDirn+90); //sail out of box in beam reach 
  }
  else{        
        //set rudder and sails       
      sailToWaypoint(stayPoint); //sets the rudder, stays in corridor if sailing upwind            
        //check timer
      currentTime = millis(); //get the Arduino clock time            
  } //end go to waypoint             
}
   
