/* Use File->Load C Prog to
   load a different Program
*/

#include <String.h>

float latitude; //Curent latitude
float longitude; //Current longitude
float GPSX; //Target X coordinate
float GPSY; //Target Y coordinate
float prevGPSX; //previous Target X coordinate
float prevGPSY; //previous Target Y coordinate
//Heading angle using wind sensor
float heading;//heading relative to true north
float deviation;//deviation relative to true north; do we use this in our calculations?
float variance;//variance relative to true north; do we use this in our calculations?
//Boat's speed
float bspeed; //Boat's speed in km/h
float bspeedk; //Boat's speed in knots
//Wind data
float wind_angl;//wind angle, (relative to boat or north?)
float wind_velocity;//wind velocity in knots
//Compass data
float headingc;//heading relative to true north
float pitch;//pitch relative to ??
float roll;//roll relative to ??

//Counters (Used for averaging)
int PTNTHTM;
int GPGLL;
int HCHDG;
int WIMWV;
int GPVTG;

void setup()
{
	Serial.begin(9600);
}

void loop()
{
        int error = Parser("$PTNTHTM,285.2,N,-2.4,N,10.7,N,59.1,3844*27");
	delay(100);
}

int DataValid(char *val) {
    //Check if the string is a command or not
	if (val[0] != '$') {
		Serial.print("wrong data\n");
		return 0;
	}
	return 1;
	//Check the end of the string
}

int Parser(char *val) 
{
	//cb! make this a moving average... remember the oldest data and subtract it. http://en.wikipedia.org/wiki/Queue_(data_structure)#Example_C_Program  maybe this?
        //to get one, we want a FIFO structure (say of 10 values) that we keep bumping the oldest out, subtracting it from our average, adding the new value to the queue and our average
        
	//look into extending TinyGPS to include the other data fields needed here; dont quite understand how it goes to the next _term
	//http://www.windmill.co.uk/nmea.html all about NMEA strings

	char str[8]; //dummy string to absorb the type of data, as %5s, value not used
	char *str1; //cb! no size set here; might be making problems cb! would make sense if this was 6chars long; I guess strtok automatically calls realloc?
	char cp[100]; //temporary array for parsing, a copy of val
	
        //GPSGLL gps latitude and longitude data
	double grades, frac; //the integer and fractional part of Degrees.minutes
	float lat_deg_nmea, lon_deg_nmea; // latitude and longitude in ddmm.mmmm degrees minutes format
	float lat; //latitude read from the string converted to decimal dd.mmmm
	float lon; //longitude read from the string converted to decimal dd.mmmm
	char lat_dir, lon_dir; //N,S,E,W direction character
	int hms; //the time stamp on GPS strings; hours minutes seconds
	char valid;//checks for the 'V' in GPS data strings (it's A if its invalid)

        //HCHDG compass data
        float head_deg, dev_deg, var_deg;
	char dev_dir, var_dir;
        
        //WIMWV wind data
	float wind_ang, wind_vel;
	char wind_ref, speed_unit; //wind_ref R = relative to boats direction; speed_unit N = knots

        //GPVTG boat speed data
        float cov_true, cov_meg, sov_knot, sov_kmh; //cov_true is the actual course the boat has been travelling in, relative to true north; cov_meg is relative to magnetic north; sov_knot is speed in knots; sov_kmh is speed in kmh;
	char ref_true, ref_meg, ref_knot, ref_kmh;  //ref_meg = M this is relative to magnetic north; ref_true = T this is relative to true north; ref_knot is always N to indicate knots; ref_kmh is always K to indicate kilometers

        //PTNTHTM data for heading and tilt
	float head2_deg, pitch_deg, roll_deg; //head2_deg is the true heading; pitch_deg the pitch referenced to.. ?; roll_deg the roll referenced to...?
	char head_st, pitch_st, roll_st; //these are always N? what does this indicate?
	
	
	if (DataValid(val) == 1){ //check if the data is valid - ideally we'd do this by checking the checksum
		Serial.print("valid string\n");
	}
	else return 1; // if data isnt valid, dont try to parse it and throw error code
	
	Serial.print(val);//echo what we're about to parse
	
	strcpy(cp, val); //make a backup copy of the data to parse
	str1 = strtok(cp, ","); //find location of first ',', and copy everything before it into str1; this will be the type of command
	
	Serial.print("command is: ");
	Serial.print(str1);
	
	//GPS String
	if (strcmp(str1, "$GPGLL") == 0) 
	{
		//     ,3354.4970,N,11759.5354,W,025604,V,S*52 lat/lon; V(a=valid, v=invalid)
		//     0 1 2 3 4 5 6 7
		
		sscanf(val, "$%5s,%f,%c,%f,%c,%d,%c,", str, &lat_deg_nmea, &lat_dir,
		&lon_deg_nmea, &lon_dir, &hms, &valid);

                 //check 'valid' before continuing; throw error code if not valid
                if (valid == 'V')
                   return 1; 
                   
		//     lat_deg is in the format ddmm.mmmm 

                //this first moves the decimal so that the latitude degrees is the whole part of the number
                //then modf returns the integer portion to 'grades' and the fractional (minutes) to 'frac'.
		frac = modf(lat_deg_nmea / 100.0, &grades); 
		// Frac is out of 60, not 100, since it's in minutes; so convert to a normal decimal
                lat = (double) (grades + frac * 100.0 / 60.0) * (lat_dir == 'S' ? -1.0	: 1.0); // change the sign of latitude based on if it's north/south

                //do the same for longitude
		frac = modf(lon_deg_nmea / 100.0, &grades);
		lon = (double) (grades + frac * 100.0 / 60.0) * (lon_dir == 'W' ? -1.0 : 1.0);

                /*print("The string: %s\n", str);
		printf("Lat_dir nmea: %f\n", lat_deg_nmea);
		printf("Lat: %f\n", lon1);
		printf("Lat_dir: %c\n", lon_dir);*/
		
		latitude = latitude + lat; //cb! dont we want a moving average? 
		longitude = longitude + lon;		
		GPGLL++;
	}
	
	//Wind sensor compass
	if (strcmp(str1, "$HCHDG") == 0) 
	{
		sscanf(val, "$%5s,%f,%f,%c,%f,%c,", str, &head_deg, &dev_deg, &dev_dir, &var_deg, &var_dir);
		
/*                printf("The string: %s\n", str);
		printf("Heading: %f\n", head_deg);
		printf("Dev: %f\n", dev_deg);
		printf("Dev dir: %c\n", dev_dir);
		printf("Var: %f\n", var_deg);
		printf("Var dir: %c\n", var_dir);*/

		heading = heading + head_deg; //cb! dont we want a moving average?
		deviation = deviation + dev_deg; //what is this in compass terminology? I think we should be taking dev_dir into account
		variance = variance + var_deg; //what is this in compass terminology? I think we should be taking var_dir into account
		HCHDG++;
	}
	
	//Wind speed and wind direction
	if (strcmp(str1, "$WIMWV") == 0) 
	{
		sscanf(val, "$%5s,%f,%c,%f,%c,%c,", str, &wind_ang, &wind_ref,&wind_vel, &speed_unit, &valid);
		//    printf("Wing angle: %f\n", wind_ang);
               
                //check 'valid' before continuing; throw error code if not valid
                if (valid == 'V')
                   return 1; 

                //wind_ref for the PB100 is always R? (relative to boat)
                //speed unit for the PB100 is always N? (knots)
		wind_angl = wind_angl + wind_ang; //cb! dont we want a moving average?
		wind_velocity = wind_velocity + wind_vel;
		WIMWV++;
	}
	
	//Boat's speed
	if (strcmp(str1, "$GPVTG") == 0) 
	{
		//Add sscanf
		sscanf(val, "$%5s,%f,%c,%f,%c,%f,%c,%f,%c", str, &cov_true, &ref_true,&cov_meg, &ref_meg, &sov_knot, &ref_knot, &sov_kmh, &ref_kmh,&valid);
		//    printf("True course made good over ground: %f\n", sov_kmh);

                //check 'valid' before continuing; throw error code if not valid
                if (valid == 'V')
                   return 1; 
                   
                //cov_true is the actual course the boat has been travelling in; ref_true = T this is relative to true north
                //meg_true is the actual course the boat has been travelling in; ref_true = M this is relative to magnetic north
                //ref_knot is always N to indicate knots
                //ref_kmh is always K to indicate kilometers
                
		bspeed += sov_kmh; //cb! dont we want a moving average?
		bspeedk += sov_knot;
		GPVTG++;
	}
	
	//Compass
	if (strcmp(str1, "$PTNTHTM") == 0) 
	{
		sscanf(val, "$%7s,%f,%c,%f,%c,%f,%c,%c", str, &head2_deg, &head_st, &pitch_deg, &pitch_st, &roll_deg, &roll_st, &valid);
		/*printf("Heading is : %f\n", head2_deg);
		printf("String is : %s\n", str);
		*/

                //check 'valid' before continuing; throw error code if not valid
                if (valid == 'V')
                   return 1; 
                
                //head_st is always N? what does this indicate?
                //pitch_st is always N? what does this indicate?
                //roll_st is always N? what does this indicate?
                
		if (head2_deg < 0)
			head2_deg += 360;
		else if (head2_deg > 360)
			head2_deg -= 360;

                //data isnt valid if the boat is heeled over too much, so discard it if pitch is more than 45 degrees
		if (abs(pitch_deg) > 45) 
		{
			head2_deg = 0;
			pitch_deg = 0;
			roll_deg = 0;
		}
		headingc = headingc + head2_deg; //cb! dont we want a moving average?
		pitch = pitch + pitch_deg;
		roll = roll + roll_deg;
		PTNTHTM++;
	}
	
	return 0;
}
