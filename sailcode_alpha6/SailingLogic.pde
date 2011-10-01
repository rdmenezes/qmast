/** Alternate sailcourse code by laz. 
 *
 * Works the same but does not use long loops for waypoint selection, less 
 * responsive but allows for menu usage while sailing. 
 * Instead of looping globals keep track of current waypoint, code updates 
 * that waypoint when reached and sets boat in the direction of the next one, 
 * this will be slightly less responsive as the time between each adjustment 
 * will include checking the menu but it should still be fast enough. Needs to 
 * be tested and compared to existing sailcourse function. Original in sailcode5
 */


/** Sail the race course.
 * Declare things static so that they persist after each call, 
 * eliminate globals
 */
void sailCourse() {
    static int distanceToWaypoint; //!< the boat's distance to the present waypoint
	
	//returns in meters
    distanceToWaypoint = GPSdistance(boatLocation, coursePoints[currentPoint]);
	//sets the rudder, stays in corridor if sailing upwind
    sailToWaypoint(coursePoints[currentPoint]); 

    if (distanceToWaypoint < MARK_DISTANCE) {
        currentPoint++;
    }
    if (currentPoint > points) {
        currentPoint--;
        return;
    }
}

/** Checks to see if the boat should sail or tack, thats it.
 * This is a newer version of the original function with the same name.
 */
void sailToWaypoint(struct points waypoint) {
    static int waypointDirn;
    static int distance = 0;
	
    // called to keep the gui up to date
    distance = GPSdistance(boatLocation, waypoint);
	// get the next waypoint's compass bearing; must be positive 0-360 heading;
    waypointDirn = getWaypointDirn(waypoint); 

	//checks if it is already tacking, saves having to run checktack
    if(tacking == true) {                     
        tack();
	//checks if outside corridor and sailing into the wind
    } else if(checkTack(10, waypoint) == true) {       
        tack();
	//not facing upwind or inside corridor
    } else {                     
		//get the next waypoint's compass bearing, must be positive 0-360 heading
        sail(waypointDirn); 
    }
}

/** Sails towards the waypointDirn passed, in which case it sails closehauled.
 * The other funtcion sailToWaypoint will take care of when tacking is necessary
 * This function replaces straightsail which originally only controlled the rudder
 */
void sail(int waypointDirn) {
    int directionError = 0;
    static int windDirn;

    windDirn = getWindDirn();

	// check if the waypoint's direction is between the wind and closehauled on 
	// either side (ie are we downwind?)
    if(between(waypointDirn, windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) { 
		//*should* prevent boat from ever trying to sail upwind
        directionError = getCloseHauledDirn() - headingc;      
    } else {
        directionError = waypointDirn - headingc;
    }

    rudderControl(directionError);
    delay(10);     //wait to allow rudder signal to be sent to pololu
    sailControl();
}

/** Check to see if tacking is necessary.
 *
 * Looks to see if the boat is in the downwind corridor and if its angle to the wind
 * is close-hauled then it will tack. This results in better turning and will allow for
 * the safety of getOutOfIrons being called during any turn into the wind. 
 *
 * @param[in] corridorHalfWidth Not sure what this is yet
 * @param[in] points Something to do with a waypoint?
 */
boolean checkTack(int corridorHalfWidth, struct points waypoint) {
    static int currentHeading;
    static int windDirn;
    int waypointDirn;
    int theta;
    float distance, hypotenuse;
    int difference;

    windDirn = getWindDirn();
    currentHeading = headingc;

	// Checks if closehauled first. Done with trig. It's a right-angled triangle, where 
	// opp is the distance perpendicular to the wind angle (the number we're looking for) 
	// and theta is the angle between the wind and the waypoint directions; positive 
	// when windDirn > waypointDirn
    if(between(currentHeading,windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) {
        waypointDirn = getWaypointDirn(waypoint);
        theta = waypointDirn - windDirn;

        // the hypotenuse is as long as the distance between the boat and the waypoint, in meters
        hypotenuse = GPSdistance(boatLocation, waypoint); // latitude is Y, longitude X for waypoints
        distance = hypotenuse * sin(degreesToRadians(theta));
        Serial.println("Distance from corridor:  ");
        Serial.println(distance);

		// check the direction of the wind so we only try to tack towards the mark
        if ( (distance  < 0 && wind_angl > 180) || (distance > 0 && wind_angl < 180) ) { 

			//we're outside corridor
            if (abs(distance) > corridorHalfWidth) { 
                Serial.println("Outside corridor");
                return true;
			//if we're past the layline
            } else if(!between(waypointDirn, windDirn + TACKING_ANGLE, windDirn - TACKING_ANGLE)) { 
                Serial.println("Past the layline");
                return true;
            }
        }
    }
    return false;
}

/** This function controls the sails, proportional to the wind direction with no consideration for wind strength.
 */
void sailControl() {
    int windAngle;

    if (wind_angl > 180)           // wind is from port side, but we dont care
    windAngle = 360 - wind_angl;   // set to 180 scale, dont care if it's on port or starboard right now,
    else
    windAngle = wind_angl;
	
	//  If not in irons
    if (windAngle > TACKING_ANGLE) { 
		// scale the range of winds from 40->180 (140 degree range) onto 0 to 100 controls; 
		// 0 means all the way in
        setSails( (windAngle-TACKING_ANGLE)*100/(180 - TACKING_ANGLE) );
	} else {
        setSails(ALL_IN);// set sails all the way in, in irons
	}
	
	// if heeled over a lot (experimentally found that 40 was appropriate according to cory)
    if (abs(roll) > 40) { 
        setMain(ALL_OUT); // set sails all the way out, keep jibaX
	}
	delay(20);        // delay to stop pololu crashing
}

/** Controls the rudder movement, used to be part of sail.
 * but is moved to a seperate function so it is easier to modify
 *
 * @param[in] directionError This needs explanation.
 */
int rudderControl(int directionError) {
    if (directionError < 0) {
        directionError += 360;
	}

	// rudder deadzone to avoid constant adjustments and oscillating, only change the rudder 
	// if there's a big error
    if  (directionError > 10 && directionError < 350) { 
		//turn left, so send a negative to setrudder function
		if (directionError > 180) { 
			//adjust rudder proportional;
			setrudder((directionError-360)/5);  
		} else {
			// adjust rudder proportional; setrudder accepts -30 to +30
			setrudder(directionError/5); 
		}
    } else {
        setrudder(0);//set to neutral position
	}
    delay(20);
}
