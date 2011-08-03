double GPSdistance(struct points location1, struct points location2){
  //finds the distance between two latitude, longitude gps coordinates, in meters
    double deltaLat, deltaLong; //distance in x and y directions
    double distance;
    
    deltaLong = (location2.lonDeg - location1.lonDeg)*DEGREE_TO_MINUTE + (location2.lonMin - location1.lonMin); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
    deltaLat = (location2.latDeg - location1.latDeg)*DEGREE_TO_MINUTE + (location2.latMin - location1.latMin); //y is the east/west coordinate, + in the east direction    
    //convert to meters, based on the number of meters in a minute, looked up for the given latitude
    deltaLat = deltaLat*LATITUDE_TO_METER; 
    deltaLong = deltaLong*LONGITUDE_TO_METER;   
    distance = sqrt (deltaLat*deltaLat + deltaLong*deltaLong);      
    distanceVal = distance;   
    return distance;
}

int getWaypointDirn(struct points waypoint){
// computes the compass heading to the waypoint based on the latest known position of the boat and the present waypoint, both in global variables
// first converting minutes to meters
    float waypointHeading;//the heading to the waypoint from where we are
    float deltaX, deltaY; //the difference between the boats location and the waypoint in x and y
    int integerHeading;
  
  // there are (approximately) 1855 meters in a minute of latitude; this isn't true for longitude, as it depends on the latitude
  //there are approximately 1314 m in a minute of longitude at 45 degrees north; this difference will mean that if we just use deltax over deltay in minutes to find an angle it will be wrong
    deltaX = (waypoint.latDeg - boatLocation.latDeg)*DEGREE_TO_MINUTE + (waypoint.latMin - boatLocation.latMin); //x (rather than y) is the north/south coordinate, +'ve in the north direction, because that will rotate the final angle to be the compass bearing
    deltaY = (waypoint.lonDeg - boatLocation.lonDeg)*DEGREE_TO_MINUTE + (waypoint.lonMin - boatLocation.lonMin); //y is the east/west coordinate, + in the east direction  
    deltaX *= LATITUDE_TO_METER;
    deltaY *= LONGITUDE_TO_METER;
    waypointHeading = radiansToDegrees(atan2(deltaY, deltaX)); // atan2 returns -pi to pi, taking account of which variables are positive to put in proper quadrant 
        
  //normalize direction
    if (waypointHeading < 0)
        waypointHeading += 360;
    else if (waypointHeading > 360){
        waypointHeading -= 360;
    }
    integerHeading = waypointHeading;
    headingVal = integerHeading;
    return integerHeading;
}

int getCloseHauledDirn(){
  //find the compass heading that is close-hauled on the present tack
  
  int desiredDirection = 0; //closehauled direction
  int windHeading = 0; //compass bearing that the wind is coming from
  
  windHeading = getWindDirn(); //compass bearing for the wind
  //determine which tack we're on 
  if (wind_angl > 180){ //wind from left side of boat first
      desiredDirection = windHeading + TACKING_ANGLE; //bear off to the right
  }
  else
      desiredDirection = windHeading - TACKING_ANGLE; //bear off to the left 
     if(desiredDirection < 0)
        desiredDirection += 360;
     if(desiredDirection > 360)
        desiredDirection -= 360; 
//  if (desiredDirection < 0){
//      desiredDirection *= -1;
//    }
//    if(desiredDirection > 360){
//     desiredDirection = desiredDirection + (-desiredDirection +360);  
//    }
//  return desiredDirection;
}

int getOppositeCloseHauledDirn(){
  //find the compass heading that is close-hauled on the present tack
  
  int desiredDirection=0; //closehauled direction
  int windHeading = 0; //compass bearing that the wind is coming from
  
  windHeading = getWindDirn(); //compass bearing for the wind

  //determine which tack we're on 
  if (wind_angl > 180){ //wind from left side of boat first
      desiredDirection = windHeading - TACKING_ANGLE; //bear off to the right
  }
  else
    desiredDirection = windHeading + TACKING_ANGLE; //bear off to the left  
  if (desiredDirection < 0){
      desiredDirection = -desiredDirection;
    }
    if(desiredDirection > 360){
     desiredDirection = desiredDirection + (-desiredDirection +360);  
    }
  return desiredDirection;
}

int getWindDirn(){
  //ensure that BOTH sensorData(w) AND sensorData(c) are called before calling this, or the bearing will be off since the data was collected at different times  
  //find the compass bearing the wind is coming from (ie if we were pointing this way, we'd be in irons)
  //be careful that we dont update the wind direction bearing based on new compass data and old wind data
  int windHeading = 0; //compass bearing that the wind is coming from
  
  windHeading = wind_angl + headingc; //calculate the compass heading that the wind is coming from; wind_angle_newest is relative to the boat's bow  

  if (windHeading < 0) //normalize to 360
    windHeading += 360;
  else if (windHeading > 360)
    windHeading -= 360;   
  trueWind = windHeading;
  return windHeading;
}


//int stayInDownwindCorridor(int corridorHalfWidth, struct points waypoint){
////calculate whether we're still inside the downwind corridor of the mark; if not, tacks if necessary
//// corridorHalfWidth is in meters
//no longer used as most functionaity has been moved into checktack, here for reference
//  
//  int theta;
//  float distance, hypotenuse;
//  
//  //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for);
// 
//  // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
//  theta = getWaypointDirn(waypoint) - getWindDirn();  
//  
//  // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
//  hypotenuse = GPSdistance(boatLocation, waypoint);//latitude is Y, longitude X for waypoints
//  
//   //opp = hyp * sin(theta)
//  distance = hypotenuse * sin(degreesToRadians(theta));
//  
//  if (abs(distance) > corridorHalfWidth){ //we're outside
//    //can use the sign of distance to determine if we should be on the left or right tack; this works because when we do sin, it takes care of wrapping around 0/360
//    //a negative distance means that we are to the right of the corridor, waypoint is less than wind
//    if ( (distance  < 0 && wind_angl_newest > 180) || (distance > 0 && wind_angl_newest < 180) ){
//      //want newest_wind_angle < 180, ie wind coming from the right to left (starboard to port?) side of the boat when distance is negative; opposite when distance positive
//         tack();     //tack function should not return until successful tack
//         Serial.println("Outside corridor, tacking");
//    }
//   
//    return distance - corridorHalfWidth*(distance/abs(distance)); //this should be positive or negative... depending on left or right side of corridor.
//   // We want this to be how far the boat is outside ie 0 if we're inside and -5 if we're 5 meters to the left, +5 if we're 5 meters to the right
//   //If distance is positive, distance/abs(distance) is +1, therefore we subtract the corridor halfwidth from a positive number, giving 0 at the boundary and +'ve number outside
//   //If distance is negative, distance/abs(distance) is -1, therefore we add the corridor halfwidth to a negative number, giving 0 at the boundary and -'ve number outside
//  }
//  else return 0;
//}

