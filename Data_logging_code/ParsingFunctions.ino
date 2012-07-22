/////////////////////////////////////////////////////
// Parsing Functions
////////////////////////////////////////////////////

int DataValid(char *val) {
    if (val[0] != '$') {
        //Serial.println("wrong data\n");
        return 1;
    }
    return 0;
    //Check the end of the string
}

void ParseGPGLL(char *GPGLL_string, double *degree, double *minute) {
    //these are because Arduino float doesnt have enough precision, so have to parse twice to get end digits
    //ParseGPGLL(lat_deg_nmea_string, &latitudeDeg, &latitudeMin);
    //convert the ddmm.mmmm string into dd, mm.mmmm (because there isnt enough precision in an arduino float, we split it into 2)

//this will only work if strings are terminated by a recognizable null token by strtok, as described here: http://www.acm.uiuc.edu/webmonkeys/book/c_guide/2.14.html
//the idea is to copy all the data beyond the first 3 characters over to a new string, before converting to a float
// Then convert these saved numbers as higher precision points for the float
    float smallFraction; //the smaller fractional part of the string, in float
    char smallFractionString[10]; //the smaller fractional part of the string
    float lowPrecisionGPS; //result of using atof on a high-precision GPS variable (drops the end precision)
    double intMinute; //the integer portion of minutes (ie mm of mm.mmmm)
    float fractionalMinute; // the fractional portion of minutes (ie 0.mmmm of mm.mmmm)
    int i; //counter
    double temp; //garbage

    //find degrees and low precision minutes
    lowPrecisionGPS = atof(GPGLL_string);
    //get the degrees part, and the integer minutes part
    // this wont work if somehow there are more than 2 digits of minutes (ie ddmmm.mmmm wll give ddm and mm.mmmm); this shouldnt happen
    // this should work for 3 digit degrees though (ie dddmm.mmmm -> ddd and mm.mmmm)
    *minute = 100*modf(lowPrecisionGPS / 100.0, degree); //processes ddmm.mm into dd (latDegrees) and mm.mm (latMinutes), low precision minute
    //degree stores the integer, minute the fractional part (with low accuracy, ie mm.mm)
    //Serial.println(*minute);
    //now find high precision minutes

    //find the precise decimal portion (ie the 0.mmmm part), store in fractionalMinute
    //drop a few high digits (ddmm.mmmm -> m.mmmm) to make it fit in the precision of a float
    i = 0;
    while (GPGLL_string[i+4]) {
        smallFractionString[i] = GPGLL_string[i+4];
        i++;
    }
    smallFractionString[i]='\0';//append end of string character

    //now there should be 4 decimal points, and 2 integers; this should fit in a float
    smallFraction = atof(smallFractionString);
    //Serial.println(smallFraction);

    //drop the integer part (m.mmmm -> m and 0.mmmm), save the high precision fraction
    fractionalMinute = modf(smallFraction, &temp); //0.mmmm
    //Serial.println(fractionalMinute);

    //drop the fraction from the low precision minute variable, save the integer part
    temp = modf(*minute, &intMinute);//drop the decimal part, we already have it; save the integer part into intMinute

    //combine the fraction and integer parts to get a high precision minute variable
    *minute = intMinute + fractionalMinute;//combine the decimal and integer halfs of the minutes into one number
}

int Parser(char *val) {
//parses a string of NMEA wind sensor data
// this also changes the global variables depending on the data; this would be much better split into separate functions

// This parser breaks when there are blanks in the data ie $PTNTHTM,,N,-2.4,N,10.7,N,59.1,3844*27

    char *str; //dummy string to absorb the type of data, as %5s, value not used; I guess strtok automatically calls realloc?
    char cp[100]; //temporary array for parsing, a copy of val

    //GPSGLL gps latitude and longitude data
//new method variables
    char lat_dir, lon_dir; //N,S,E,W direction character
    int hms; //the time stamp on GPS strings; hours minutes seconds
    char valid;//checks for the 'V' in GPS data strings (it's A if its invalid)
    char *lat_deg_nmea_string, *lon_deg_nmea_string, *hms_string; //strings to use during tokenizing

    //HCHDG compass data
    float head_deg, dev_deg, var_deg;
    char dev_dir, var_dir;
    char *head_deg_string, *dev_deg_string, *var_deg_string;//strings to use during tokenizing

    //WIMWV wind data
    float wind_ang, wind_vel;
    char wind_ref, speed_unit; //wind_ref R = relative to boats direction; speed_unit N = knots
    char *wind_ang_string, *wind_vel_string;//strings to use during tokenizing

    //GPVTG boat speed data
    float cov_true, cov_meg, sov_knot, sov_kmh; //cov_true is the actual course the boat has been travelling in, relative to true north;
    //cov_meg is relative to magnetic north;
    //sov_knot is speed in knots;
//  sov_kmh is speed in kmh;
    char ref_true, ref_meg, ref_knot, ref_kmh;
    //ref_meg = M this is relative to magnetic north;
    //ref_true = T this is relative to true north; ref_knot is always N to indicate knots;
    //ref_kmh is always K to indicate kilometers
    char *cov_true_string, *cov_meg_string, *sov_knot_string, *sov_kmh_string; // strings to use during tokenizing

    //PTNTHTM data for heading and tilt
    float head2_deg, pitch_deg, roll_deg; //head2_deg is the true heading; pitch_deg the pitch referenced to.. ?; roll_deg the roll referenced to...?
    char head_st, pitch_st, roll_st; //these are a status indicator; see compass manual on dropbox
    char *head2_string; //sscanf, strtok doesnt support directly scanning into floats; hence we are scanning into strings and then using atof to convert to float
    char *roll_string;
    char *pitch_string;
    if (DataValid(val) != 0) { //check if the data is valid - ideally we'd do this by checking the checksum
        setErrorBit(twoCommasBit);
    } // if data isnt valid, dont try to parse it and throw error code

// Serial.println(val);//echo what we're about to parse

    strcpy(cp, val); //make a backup copy of the data to parse; if not copied val gets corrupted when tokenized
    str = strtok(cp, ","); //find location of first ',', and copy everything before it into str1; returns a pointer to a character array. this will be the type of command, should return $xxxxx identifier
//  Serial.print("command portion from cp strtok is: ");
//  Serial.println(str);

    //now we know what type of command we're dealing with and can parse it - wooooo

    //GPS String
    if (strcmp(str, "$GPGLL") == 0) {
        lat_deg_nmea_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
        lat_dir = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok.
        // strtok s a point to a character array; we only want the value at the pointer's address (first value)
        lon_deg_nmea_string = strtok(NULL, ",");
        lon_dir = (char) * strtok(NULL, ",");
        hms_string = strtok(NULL, ",");

        hms = atoi(hms_string); //hms is converted to integer, not float

        ParseGPGLL(lat_deg_nmea_string, &boatLocation.latDeg, &boatLocation.latMin); //convert the ddmm.mmmm string into dd, mm.mmmm (because there isnt enough precision in an arduino float, we split it into 2)
        ParseGPGLL(lon_deg_nmea_string, &boatLocation.lonDeg, &boatLocation.lonMin);

        if (lat_dir == 'S') {
            boatLocation.latDeg *= -1; // change the sign of latitude based on if it's north/south
            boatLocation.latMin *= -1;
        }
        if (lon_dir == 'W') {
            boatLocation.lonDeg *= -1;
            boatLocation.lonMin *= -1;
        }
    }

    //Wind sensor compass
    if (strcmp(str, "$HCHDG") == 0) {

        //parse
        head_deg_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
        dev_deg_string = strtok(NULL, ",");
        dev_dir = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok.
        // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
        var_deg_string = strtok(NULL, ",");
        var_dir = (char) * strtok(NULL, ",");

        //convert to floats from strings
        head_deg = atof(head_deg_string);
        dev_deg = atof(dev_deg_string);
        var_deg = atof(var_deg_string);

        //process
        heading = (head_deg + 25); // using external compass, may want to average the two
        if (heading > 360)
            heading -= 360;
        deviation = dev_deg; //what is this in compass terminology? I think we should be taking dev_dir into account
        variance = var_deg; //what is this in compass terminology? I think we should be taking var_dir into account
    }

    //Wind speed and wind direction
    //when parsing this, need to verify that wind is strong enough to give a reading on the sensor
    if (strcmp(str, "$WIMWV") == 0) {
        //sscanf(val, "$%5s,%f,%c,%f,%c,%c,", str, &wind_ang, &wind_ref,&wind_vel, &speed_unit, &valid);
        //    printf("Wing angle: %f\n", wind_ang);

        wind_ang_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
        wind_ref = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok.
        // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
        wind_vel_string = strtok(NULL, ",");
        speed_unit = (char) * strtok(NULL, ",");

        //convert to floats from strings
        wind_ang = atof(wind_ang_string);
        wind_vel = atof(wind_vel_string);

        //wind_ref for the PB100 is always R? (relative to boat)
        //speed unit for the PB100 is always N? (knots)
        if((wind_ang != 270.0) && (wind_ang !=360.0) && (wind_ang != 90.0) && (wind_ang !=180.0) &&(wind_ang != 0.0)) { //these are known to occur during an error willthrow off sail logic
            clearErrorBit(badWindData);
            wind_velocity = wind_vel;
            wind_angl_newest = wind_ang; //for testing purposes, save the newest wind angle
            if(wind_angl_newest - wind_angl > 180) {
                wind_angl += 360;
            }
            if(wind_angl - wind_angl_newest > 180) {
                wind_angl_newest += 360;
            }
            wind_angl += wind_angl_newest;
            wind_angl /= 2;
            while (wind_angl < 0) {
                wind_angl += 360;
            }
            while (wind_angl > 360) {
                wind_angl -= 360;
            }
        } else {
            setErrorBit(badWindData);
        }
    }

    //Boat's speed
    if (strcmp(str, "$GPVTG") == 0) {
        //Add sscanf
        //  sscanf(val, "$%5s,%f,%c,%f,%c,%f,%c,%f,%c", str, &cov_true, &ref_true,&cov_meg, &ref_meg, &sov_knot, &ref_knot, &sov_kmh, &ref_kmh,&valid);
        //    printf("True course made good over ground: %f\n", sov_kmh);


        //parse
        cov_true_string = strtok(NULL, ","); // this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
        ref_true = (char) * strtok(NULL, ","); // only a (char) not a array of chars. Hence, = typecast(char) dereferenced strtok.
        // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
        cov_meg_string = strtok(NULL, ",");
        ref_meg = (char) * strtok(NULL, ",");
        sov_knot_string = strtok(NULL, ",");
        ref_knot = (char) * strtok(NULL, ",");
        sov_kmh_string = strtok(NULL, ",");
        ref_kmh = (char) * strtok(NULL, ",");

        //convert to floats from strings
        cov_true = atof(cov_true_string);
        cov_meg = atof(cov_meg_string);
        sov_knot = atof(sov_knot_string);
        sov_kmh = atof(sov_kmh_string);

        //cov_true is the actual course the boat has been travelling in; ref_true = T this is relative to true north
        //meg_true is the actual course the boat has been travelling in; ref_true = M this is relative to magnetic north
        //ref_knot is always N to indicate knots
        //ref_kmh is always K to indicate kilometers

        bspeed = sov_kmh; //actual speed not the average
        bspeedk = sov_knot;
    }

    //Compass
    if (strcmp(str, "$PTNTHTM") == 0) {
        //"$PTNTHTM,285.2,N,-2.4,N,10.7,N,59.1,3844*27" is actual data
        // sscanf(val, "$%7s,%s,%c,%s,%c,%s,%c,%c", str1, &head2_string, &head_st, &pitch_string, &pitch_st, &roll_string, &roll_st, &valid);
        /*printf("Heading is : %f\n", head2_deg);
         printf("String is : %s\n", str);
         "The %s format in sscanf is defined to read a string until it encounters white space.  If you want it to stop on a comma, you should use the %[^,] format." - some forum
         */
        clearErrorBit(badCompassDataBit);
        head2_string = strtok(NULL, ","); // should return 285.2; this will use the cp copied string, since strtok magically remembers which string it was initially referenced to if NULL if used instead of a string
        head_st = (char) * strtok(NULL, ","); //head_st is only a (char) not a array of chars. It's value is only N or S. Hence, head_st = typecast(char) dereferenced strtok.
        // strtok returns a point to a character array; we only want the value at the pointer's address (first value)
        pitch_string = strtok(NULL, ",");
        pitch_st = (char) * strtok(NULL, ",");
        roll_string = strtok(NULL, ",");
        roll_st = (char) * strtok(NULL, ",");
        head2_deg = atof(head2_string);
        roll_deg = atof(roll_string);
        pitch_deg = atof(pitch_string);

// Diagnostic printing

        /*  Serial.print("Str command portion strtok1 from cp: ");
          Serial.println(str);
          Serial.print("Heading portion strtok2from cp: ");
          Serial.println(head2_string);
          Serial.print("Direction of heading: ");
          Serial.println(head_st);
          Serial.println(pitch_string);
          Serial.println(pitch_st);
          Serial.println(roll_string);
          Serial.println(roll_st);
         // Serial.println(valid);

          //... and print their decimal conversions!
          Serial.println("\n");
          Serial.println(head2_deg);
          Serial.println(pitch_deg);
          Serial.println(roll_deg);
          Serial.println("\n");
          */
        //   end diagnostic printing

        if (head2_deg < 0)
            head2_deg += 360;
        else if (head2_deg > 360)
            head2_deg -= 360;

        //data isnt valid if the boat is heeled over too much, so discard it if pitch is more than 45 degrees <- parser breaks before this, as the compass doesnt return a heading when its tipped
        if (abs(roll_deg) > 40) {
            setErrorBit(tooMuchRollBit);
        } else {
            clearErrorBit(tooMuchRollBit);
        }

        if(head2_deg != 0.0) {
            if(head2_deg - headingc > 180) {
                headingc += 360;
            }
            if(headingc - head2_deg > 180) {
                head2_deg += 360;
            }
            headingc += head2_deg;
            headingc /= 2;
            while (headingc < 0) {
                headingc += 360;
            }
            while (headingc > 360) {
                headingc -= 360;
            }
        }
        pitch = pitch_deg;
        roll = roll_deg;
        heading_newest = head2_deg;//also track the newest heading
    }
    return 0;
}
