//**Alternate sailcourse code by laz, works the same but does not use long loops for waypoint selection, less responsive but allows for menu usage while sailing
//Instead of looping globals keep track of current waypoint, code updates that waypoint when reached and sets boat in the direction of the next one, this will be slightly less responsive as
//the time between each adjustment will include checking the menu but it should still be fast enough. Needs to be tested and compared to existing sailcourse function. Original in sailcode5
void sailCourse(){
  //sail the race course   
  //**declare things static so that they persist after each call, eliminate globals
  static int error; 
  static int distanceToWaypoint;//the boat's distance to the present waypoint
      
  error = sensorData(BUFF_MAX,'c');  
  error = sensorData(BUFF_MAX,'w');     
  distanceToWaypoint = GPSdistance(boatLocation, coursePoints[currentPoint]);//returns in meters
  Serial.println(distanceToWaypoint);
  //set rudder and sails    
  error = sailToWaypoint(coursePoints[currentPoint]); //sets the rudder, stays in corridor if sailing upwind         
  distanceToWaypoint = GPSdistance(boatLocation, coursePoints[currentPoint]);//returns in meters
  if (distanceToWaypoint < MARK_DISTANCE){
      currentPoint++;
  }
  if (currentPoint > points){
      currentPoint = points;
  return;
  }     
} 
/* old description of Straightsail (deprecated)
         //this should be the generic straight sailing function; getWaypointDirn should return a desired compass direction, 
         //taking into account wind direction (not necc just the wayoint dirn); (or make another function to do this)
          //needs to set rudder to not try and head directly into the wind
   */
int sail(int waypointDirn){
  //sails towards the waypointDirn passed in, unless this is upwind, in which case it sails closehauled.
  //sailToWaypoint will take care of when tacking is necessary   
  //This function replaces straightsail which originally only controlled rudder
  
  static int error = 0; //error flag
  int directionError = 0;
  int angle = 0; 
  static int windDirn;
  
  windDirn = getWindDirn(); 
  error = sensorData(BUFF_MAX, 'c'); //updates heading_newest
  if (error){
      return (error);
  }         
  if(between(waypointDirn, windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)){ //check if the waypoint's direction is between the wind and closehauled on either side (ie are we downwind?)
      directionError = getCloseHauledDirn() - headingc;      //*should* prevent boat from ever trying to sail upwind 
  }
  else{
      directionError = waypointDirn - headingc;
  }
  if (directionError < 0)
      directionError += 360;
  if  (directionError > 10 && directionError < 350) { //rudder deadzone to avoid constant adjustments and oscillating, only change the rudder if there's a big error
      if (directionError > 180) //turn left, so send a negative to setrudder function
          setrudder((directionError-360)/4);  //adjust rudder proportional; setrudder accepts -45 to +45
      else
          setrudder(directionError/4); // adjust rudder proportional; setrudder accepts -30 to +30     
  }   
  else
      setrudder(0);//set to neutral position      
  delay(10);     //wait to allow rudder signal to be sent to pololu
  directionError = sailControl();
  return 0;
}

//new version of sailToWaypoint, this version checks if boat should tack or 'sail', thats it
int sailToWaypoint(struct points waypoint){
    static int waypointDirn;
    static int error = 0;
    
    waypointDirn = getWaypointDirn(waypoint); //get the next waypoint's compass bearing; must be positive 0-360 heading;
    Serial.println(waypointDirn);
    if(tacking == true){                      //checks if it is already tacking, saves having to run checktack
        tack();
    }
    else if(checkTack(10, waypoint) == true){          //checks if outside corridor and sailing into the wind 
        tack(); 
    }
    else{                        //not facing upwind or inside corridor
        sail(waypointDirn); //get the next waypoint's compass bearing; must be positive 0-360 heading; 
    }
    delay(300);
    return error;
}

//Checks if tacking is neccessary,returns true if it is false if not.
//looks to see if boat is in the downwind corridor and if its angle to the wind is closehauled.
//if the boat is pout the corridor and sailing closehauled then it will tack. This results in better turning and 
//will allow for the safety of the getOutOfIrons being called during any turn into the wind
boolean checkTack(int corridorHalfWidth, struct points waypoint){
   static int currentHeading;
   static int windDirn; 
   int waypointDirn; 
   int theta;
   float distance, hypotenuse;
   int difference;
   
   windDirn = getWindDirn();
   currentHeading = headingc;
   //difference = currentHeading - windDirn;          //call between fix later
   if(currentHeading > windDirn){ 
       difference = currentHeading - windDirn;
       if(difference > 360 - TACKING_ANGLE){
           difference -= 360;
       } 
   }
   else{
       difference = windDirn- currentHeading;
       if(difference > 360 - TACKING_ANGLE){
           difference -= 360; 
       }
   }
  if(abs(difference) < TACKING_ANGLE +5){            //checks if closehauled first, +5 for good measure
  //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for); 
  // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
      waypointDirn = getWaypointDirn(waypoint);
      theta = waypointDirn - windDirn;    
  // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
      hypotenuse = GPSdistance(boatLocation, waypoint);//latitude is Y, longitude X for waypoints  
   //opp = hyp * sin(theta)
      distance = hypotenuse * sin(degreesToRadians(theta));
      Serial.println("The distance from the corridor is:  ");
      Serial.println(distance);
      if ( (distance  < 0 && wind_angl> 180) || (distance > 0 && wind_angl < 180) ) // check the direction of the wind so we only try to tack towards the mark
      {
          if (abs(distance) > corridorHalfWidth){ //we're outside corridor
              Serial.println("I want to tack because I'm outside the 10m corridor");
              return true; 
          } 
          else if(!between(waypointDirn, windDirn + TACKING_ANGLE, windDirn - TACKING_ANGLE)) { //if we're past the layline
              Serial.println("I want to tack because I'm past the layline");
              return true;
          }      
     }     
  }
  return false;
}

//this functin controls the sails, proportional to the wind direction with no consideration for wind strength (yet)
int sailControl(){
  int error =0;
  int windAngle;
  
  if (abs(roll) > 40){ //if heeled over a lot (experimentally found that 40 was appropriate according to cory)
      setMain(ALL_OUT); //set sails all the way out, keep jibaX 
      return (1); //return 1 to indicate heel
  }
  error = sensorData(BUFF_MAX, 'w'); //updates wind_angl_newest
  if (wind_angl > 180) //wind is from port side, but we dont care
      windAngle = 360 - wind_angl; //set to 180 scale, dont care if it's on port or starboard right now, 
  else
      windAngle = wind_angl;    
  if (windAngle > TACKING_ANGLE) //not in irons
      setSails( (windAngle-TACKING_ANGLE)*100/(180 - TACKING_ANGLE) );//scale the range of winds from 30->180 (150 degree range) onto 0 to 100 controls (60 degree range); 0 means all the way in
  else
      setSails(ALL_IN);// set sails all the way in, in irons     
  return error;
}

