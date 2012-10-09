/**
 * The transmit function is used to communicate with LabView.
 * through a series of preset strings, which are represented by
 * the graphical gauges?
 *
 * Prints directly to the serial and takes input from global values
 */

void transmit(void) {
    long boatLat;
    long boatLon;
    time_t t;
    boatLat = boatLocation.latDeg*1000000+boatLocation.latMin*10000/0.6;
    boatLon = boatLocation.lonDeg*1000000+boatLocation.lonMin*10000/0.6;
    
    Serial.print("###");
    // GPS
    Serial.print("LAT:");
    Serial.print(boatLat,DEC);
    Serial.print("LON:");
    Serial.print(boatLon,DEC); //wp_current_lat
    Serial.print("SPD:");
    Serial.print(bspeed,2);
    // Wind Direction and Velocity
    Serial.print("vwthetaBR:");
    Serial.print(wind_angl,2);
    Serial.print("vwthetaT:");
    Serial.print(trueWind,2);
    Serial.print("vwR:");
    Serial.print(wind_velocity,2);
    // Accelerometer
    Serial.print("ROL:");
    Serial.print(roll);
    // Navigation Control
    Serial.print("MAIN:");
    Serial.print(mainVal,DEC);
    Serial.print("RUD:");
    Serial.print(rudderVal,DEC);
    // What we are doing
    Serial.print("vbthetaT:");
    Serial.print(headingc,2);
    Serial.print("setPoint:");
    Serial.print(headingVal,2);

    // Tacking
    //Serial.print("SID:");
    //Serial.print(tackingSide,DEC);
    //Serial.print("IRON:");
   // Serial.print(ironTime,DEC);
    //Serial.print(",DMD:");
    //Serial.print(distanceVal);  // current distance
    
     // Hall Effect Sensor
    Serial.print("ANG:");
    Serial.print(angle,DEC);
    
    // Time stamp -- dd/mm/yyyy HH:MM:SS (24 hr clk)
    t = now();
    Serial.print("DATE: ");
    Serial.print(month(t));
    Serial.print("/");
    Serial.print(day(t));
    Serial.print("/");
    Serial.print(year(t));
    Serial.print(" ");
    Serial.print(hour(t));
    Serial.print(":");
    Serial.print(minute(t));
    Serial.print(":");
    Serial.print(second(t));
    
    Serial.print(",ERR:");
    Serial.print(errorCode);
    Serial.print("***");
    
   
}

/**
 * Similar to the transmit function except the output contains information
 * which is not read by LabView, so codes are not needed?
 */
void relayData() { //sends data to shore
    Serial.println(millis());
    // Send data to zigbee
    Serial.println();
    Serial.print(boatLocation.latDeg);
    Serial.print(",");
    Serial.print(boatLocation.latMin);
    Serial.print(",");
    Serial.print(boatLocation.lonDeg);
    /// Latitude and longitude of boat's location, split into more precise
    /// degrees and minutes, to fit into a float
    Serial.print(",");
    Serial.print(boatLocation.lonMin);
    Serial.print(",");
    Serial.print(bspeed);        // boat speed
    Serial.print(",");
    Serial.print(heading);       // boat direction
    Serial.print(",");
    Serial.print(wind_angl);     // wind angle, (relative to boat or north?)
    Serial.print(",");
    Serial.print(wind_velocity); // wind velocity in knots
    Serial.print(",");
    Serial.println(headingc);    // compass
}

