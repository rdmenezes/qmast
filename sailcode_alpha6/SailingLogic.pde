//**Alternate sailcourse code by laz, works the same but does not use long loops for waypoint selection, less responsive but allows for menu usage while sailing
//Instead of looping globals keep track of current waypoint, code updates that waypoint when reached and sets boat in the direction of the next one, this will be slightly less responsive as
//the time between each adjustment will include checking the menu but it should still be fast enough. Needs to be tested and compared to existing sailcourse function. Original in sailcode5
void sailCourse() {
    //sail the race course
    //**declare things static so that they persist after each call, eliminate globals
    static int distanceToWaypoint;//the boat's distance to the present waypoint

    distanceToWaypoint = GPSdistance(boatLocation, coursePoints[currentPoint]);//returns in meters
    sailToWaypoint(coursePoints[currentPoint]); //sets the rudder, stays in corridor if sailing upwind
    if (distanceToWaypoint < MARK_DISTANCE) {
        currentPoint++;
    }
    if (currentPoint > points) {
        currentPoint--;
        return;
    }
}

//new version of sailToWaypoint, this version checks if boat should tack or 'sail', thats it
void sailToWaypoint(struct points waypoint) {
    static int waypointDirn;
    static int distance = 0;
    //called to keep the gui up to date
    distance = GPSdistance(boatLocation, waypoint);
    waypointDirn = getWaypointDirn(waypoint); //get the next waypoint's compass bearing; must be positive 0-360 heading;
    if(tacking == true) {                     //checks if it is already tacking, saves having to run checktack
        tack();
    } else if(checkTack(10, waypoint) == true) {       //checks if outside corridor and sailing into the wind
        tack();
    } else {                     //not facing upwind or inside corridor
        sail(waypointDirn); //get the next waypoint's compass bearing; must be positive 0-360 heading;
    }
}
/* old description of Straightsail (deprecated)
         //this should be the generic straight sailing function; getWaypointDirn should return a desired compass direction,
         //taking into account wind direction (not necc just the wayoint dirn); (or make another function to do this)
          //needs to set rudder to not try and head directly into the wind
   */
void sail(int waypointDirn) {
    //sails towards the waypointDirn passed in, unless this is upwind, in which case it sails closehauled.
    //sailToWaypoint will take care of when tacking is necessary
    //This function replaces straightsail which originally only controlled rudder

    int directionError = 0;
    static int windDirn;

    windDirn = getWindDirn();
    if(between(waypointDirn, windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) { //check if the waypoint's direction is between the wind and closehauled on either side (ie are we downwind?)
        directionError = getCloseHauledDirn() - headingc;      //*should* prevent boat from ever trying to sail upwind
    } else {
        directionError = waypointDirn - headingc;
    }
    rudderControl(directionError);
    delay(10);     //wait to allow rudder signal to be sent to pololu
    sailControl();
}

//Checks if tacking is neccessary,returns true if it is false if not.
//looks to see if boat is in the downwind corridor and if its angle to the wind is closehauled.
//if the boat is out of the corridor and sailing closehauled then it will tack. This results in better turning and
//will allow for the safety of the getOutOfIrons being called during any turn into the wind
boolean checkTack(int corridorHalfWidth, struct points waypoint) {
    static int currentHeading;
    static int windDirn;
    int waypointDirn;
    int theta;
    float distance, hypotenuse;
    int difference;

    windDirn = getWindDirn();
    currentHeading = headingc;

    if(between(currentHeading,windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) {
        //checks if closehauled first,
        //do this with trig. It's a right-angled triangle, where opp is the distance perpendicular to the wind angle (the number we're looking for);
        // and theta is the angle between the wind and the waypoint directions; positive when windDirn > waypointDirn
        waypointDirn = getWaypointDirn(waypoint);
        theta = waypointDirn - windDirn;
        // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
        hypotenuse = GPSdistance(boatLocation, waypoint);//latitude is Y, longitude X for waypoints
        distance = hypotenuse * sin(degreesToRadians(theta));
        Serial.println("Distance from corridor:  ");
        Serial.println(distance);
        if ( (distance  < 0 && wind_angl > 180) || (distance > 0 && wind_angl < 180) ) { // check the direction of the wind so we only try to tack towards the mark
            if (abs(distance) > corridorHalfWidth) { //we're outside corridor
                Serial.println("Outside corridor");
                return true;
            } else if(!between(waypointDirn, windDirn + TACKING_ANGLE, windDirn - TACKING_ANGLE)) { //if we're past the layline
                Serial.println("Past the layline");
                return true;
            }
        }
    }
    return false;
}

//this functin controls the sails, proportional to the wind direction with no consideration for wind strength (yet)
void sailControl() {
    int windAngle;

    if (wind_angl > 180) //wind is from port side, but we dont care
        windAngle = 360 - wind_angl; //set to 180 scale, dont care if it's on port or starboard right now,
    else
        windAngle = wind_angl;
    if (windAngle > TACKING_ANGLE) //not in irons
        setSails( (windAngle-TACKING_ANGLE)*100/(180 - TACKING_ANGLE) );//scale the range of winds from 40->180 (140 degree range) onto 0 to 100 controls; 0 means all the way in
    else
        setSails(ALL_IN);// set sails all the way in, in irons
    if (abs(roll) > 40) { //if heeled over a lot (experimentally found that 40 was appropriate according to cory)
        setMain(ALL_OUT); //set sails all the way out, keep jibaX
    }
    delay(20);     //delay to stop pololu crashing
}

//controls the rudder movement, used to be part of sail, but is moved to a seperate function so it is easier to modify
int rudderControl(int directionError) {
    if (directionError < 0)
        directionError += 360;
    if  (directionError > 10 && directionError < 350) { //rudder deadzone to avoid constant adjustments and oscillating, only change the rudder if there's a big error
        if (directionError > 180) //turn left, so send a negative to setrudder function
            setrudder((directionError-360)/5);  //adjust rudder proportional;
        else
            setrudder(directionError/5); // adjust rudder proportional; setrudder accepts -30 to +30
    } else
        setrudder(0);//set to neutral position
    delay(20);
}
