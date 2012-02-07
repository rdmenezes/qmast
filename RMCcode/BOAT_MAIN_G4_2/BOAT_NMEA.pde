#define BUF_LEN 200

// GPS Pointers
//char *token;
//char *search = ",";
//char *brkb, *pEnd;
char gps_buffer[BUF_LEN]; //The traditional buffer.
char *tokentemp;

//HEADERS
const char head_HCHDT[]="HCHDT"; // COMPASS
const char head_HCHDG[]="HCHDG"; // Compass
const char head_GPRMC[]="GPRMC"; //GPS NMEA header to look for
const char head_WIMWV[]="WIMWV"; //WIND
const char head_WIMWD[]="WIMWD"; //WIND
//const char head_WIVWR[]="WIVWR"; //WIND



const float t7				= 10000000.0;	// used to scale GPS values for EEPROM storage
static unsigned long GPS_timer = 0; //used to turn off the LED if no data is received. 

//static byte unlock = 1; //some kind of event flag
static byte checksum = 0; //the checksum generated
static byte checksum_received = 0; //Checksum received
//static byte counter = 0; //general counter

//Temporary variables for some tasks, specially used in the GPS parsing part (Look at the NMEA_Parser tab)
unsigned long temp = 0;
unsigned long temp2 = 0;
unsigned long temp3 = 0;
float tempTR = 0;



void init_AIRMAR(void)
{

  Serial.println("Program Start");

  Serial1.println("$PAMTC,EN,ALL,0");
 // Serial1.println("$PAMTC,BAUD,38400"); // This has worked once
  //Serial1.begin(38400); 
  delay(200);
  Serial1.println("$PAMTC,EN,RMC,1"); // Turn on RMC
  delay(200);
  //Serial1.println("$PAMTC,EN,VWR,1");
  //delay(200);
  Serial1.println("$PAMTC,EN,MWVT,1");
  delay(200);
  Serial1.println("$PAMTC,EN,MWVR,1,2"); // relative wind at 0.2s refresh
  delay(200);
  Serial1.println("$PAMTC,EN,MWD,1");
  delay(200);
  //Serial1.println("$PAMTC,EN,HDG,1");
  //delay(200);
  Serial1.println("$PAMTC,EN,HDT,1,2"); // true heading a 0.2s refresh
  delay(200);
  Serial1.println("$PAMTC,EN,S");
  delay(200);


}
void get_AIRMAR(void)
{

  while(Serial1.available() > 0)
  {
    if(unlock == 0)
    {
      gps_buffer[0] = Serial1.read();//puts a byte in the buffer


      if(gps_buffer[0]=='$')//Verify if is the preamble $
      {
        counter 	= 0;
        checksum 	= 0;
        unlock		= 1;
        //Serial.print(gps_buffer[0]);
      }
    } 
    else {
      gps_buffer[counter] = Serial1.read();
      //Serial.print(gps_buffer[counter]);     //*******PRINT EVERYTHING~

      if(gps_buffer[counter] == 0x0A)//Looks for \F
      {
        unlock = 0;


        // **********HDT - Heading************

        if (strncmp (gps_buffer, head_HCHDT, 5) == 0)//now looking for HDG head....
        {
          //Serial.println("***Found HDT***"); //* MOVE THIS SERIAL PRINT LINE, IT SHOULD BE INSIDE BRACKET IT WONT FIND IT THOUGH.. THIS WAY I
          //TAKES THE FIRST COMMA FROM EVRY ST


          /*Generating and parsing received checksum, */
          for(int x = 0; x<100; x++)
          {
            if(gps_buffer[x]=='*')
            { 
              checksum_received = strtol(&gps_buffer[x + 1], NULL, 16);//Parsing received checksum...
              break; 
            }
            else
            {
              checksum^= gps_buffer[x]; //XOR the received data... 
            }
          }

          //Serial.println(checksum_received,DEC);
          //Serial.println(checksum,DEC);

          if(checksum_received== checksum)//Checking checksum
          {

            //strcpy(gps_GGA,gps_buffer);

            token = strtok_r(gps_buffer, search, &brkb);// HCHDT header, not used anymore
            token = strtok_r(NULL, search, &brkb);// heading HDT
            vbthetaT=atof(token);
            token = strtok_r(NULL, search, &brkb);

          }
          checksum = 0; //Restarting the checksum 
        } // END OF HDT parsing


        if (strncmp (gps_buffer, head_HCHDG, 5) == 0)//now looking for HDG head....
        {
          //Serial.println("***Found HDT***"); //* MOVE THIS SERIAL PRINT LINE, IT SHOULD BE INSIDE BRACKET IT WONT FIND IT THOUGH.. THIS WAY I
          //TAKES THE FIRST COMMA FROM EVRY ST


          /*Generating and parsing received checksum, */
          for(int x = 0; x<100; x++)
          {
            if(gps_buffer[x]=='*')
            { 
              checksum_received = strtol(&gps_buffer[x + 1], NULL, 16);//Parsing received checksum...
              break; 
            }
            else
            {
              checksum^= gps_buffer[x]; //XOR the received data... 
            }
          }

          //Serial.println(checksum_received,DEC);
          //Serial.println(checksum,DEC);

          if(checksum_received== checksum)//Checking checksum
          {

            //strcpy(gps_GGA,gps_buffer);

            token = strtok_r(gps_buffer, search, &brkb);// HCHDG header, not used anymore
            token = strtok_r(NULL, search, &brkb);// heading HDG magnetic
            vbthetaM=atof(token);
            token = strtok_r(NULL, search, &brkb); //mag dev
            token = strtok_r(NULL, search, &brkb); // mag dev EW
            token = strtok_r(NULL, search, &brkb); // mag var
            magvar = atof(token);
            token = strtok_r(NULL, search, &brkb); //mag var EW
            magvarEW = *token;

          }
          checksum = 0; //Restarting the checksum 
        } // END OF HDG parsing



        //*********RMC************

        if (strncmp (gps_buffer, head_GPRMC, 5) == 0)//looking for rmc head....
        {

          /*Generating and parsing received checksum, */
          for(int x=0; x<100; x++)
          {
            if(gps_buffer[x]=='*')
            { 
              checksum_received = strtol(&gps_buffer[x + 1], NULL, 16);//Parsing received checksum...
              break; 
            }
            else
            {
              checksum ^= gps_buffer[x]; //XOR the received data... 
            }
          }

          if(checksum_received == checksum)//Checking checksum
          {
            /* Token will point to the data between comma "'", returns the data in the order received */
            /*THE GPRMC order is: UTC, UTC status , Lat, N/S indicator, Lon, E/W indicator, speed, course, date, mode, checksum*/
            token = strtok_r(gps_buffer, search, &brkb); //Contains the header GPRMC, not used

            token = strtok_r(NULL, search, &brkb); //UTC Time, not used
            //time=	atol (token);
            token = strtok_r(NULL, search, &brkb); //Valid UTC data? maybe not used... 
            if (*token == 'A') {
              GPSLOCK = 1;
            }
            else if (*token == 'V'){
              GPSLOCK = 0;
            }


            //Longitude in degrees, decimal minutes. (ej. 4750.1234 degrees decimal minutes = 47.835390 decimal degrees)
            //Where 47 are degrees and 50 the minutes and .1234 the decimals of the minutes.
            //To convert to decimal degrees, devide the minutes by 60 (including decimals), 
            //Example: "50.1234/60=.835390", then add the degrees, ex: "47+.835390 = 47.835390" decimal degrees
            token = strtok_r(NULL, search, &brkb); //Contains Latitude in degrees decimal minutes... 
           /*
            Serial.print("Lat Token: ");
            Serial.println(token);
           */
            gps_str_to_int(token,&current_loc_deg[0]);           

            /*
            Serial.print("Lat deg: ");Serial.println(current_loc_deg[0].deg);
            Serial.print("Lat min: ");Serial.println(current_loc_deg[0].min);
            Serial.print("Lat decimin1: ");Serial.println(current_loc_deg[0].decimin1);
            Serial.print("Lat decimin2: ");Serial.println(current_loc_deg[0].decimin2);
            */
            //taking only degrees, and minutes without decimals, 
            //strtol stop parsing till reach the decimal point "."	result example 4750, eliminates .1234
            temp = strtol (token, &pEnd, 10);

            //takes only the decimals of the minutes
            //result example 1234. 
            temp2 = strtol (pEnd + 1, NULL, 10);

            //joining degrees, minutes, and the decimals of minute, now without the point...
            //Before was 4750.1234, now the result example is 47501234...
            temp3 = (temp * 10000) + (temp2);
            //Before was 47501234, the result example is 501234.
            temp3 = temp3 % 1000000;


            //Dividing to obtain only the de degrees, before was 4750 
            //The result example is 47 (4750/100 = 47)
            temp /= 100;

            //Joining everything and converting to float variable... 
            //First i convert the decimal minutes to degrees decimals stored in "temp3", example: 501234/600000 =.835390
            //Then i add the degrees stored in "temp" and add the result from the first step, example 47+.835390 = 47.835390 
            //The result is stored in "lat" variable... 
            //lat = temp + ((float)temp3 / 600000);
            current_loc.lat		= (temp * t7) + ((temp3 *100) / 6);
            
            
            token = strtok_r(NULL, search, &brkb); //lat, north or south?
            //If the char is equal to S (south), multiply the result by -1.. 
            if(*token == 'S'){  //    Assume we are always NW
              current_loc.lat *= -1;
            }

            //This the same procedure use in lat, but now for Lon....
            token = strtok_r(NULL, search, &brkb);
            //Serial.print("Long Token: ");
           // Serial.println(token);
            gps_str_to_int(token,&current_loc_deg[1]);
            
            /*
            Serial.print("Long deg: ");Serial.println(current_loc_deg[1].deg);
            Serial.print("Long min: ");Serial.println(current_loc_deg[1].min);
            Serial.print("Long decimin1: ");Serial.println(current_loc_deg[1].decimin1);
            Serial.print("Long decimin2: ");Serial.println(current_loc_deg[1].decimin2);            
            */
            temp = strtol (token,&pEnd, 10); 
            temp2 = strtol (pEnd + 1, NULL, 10); 
            temp3 = (temp * 10000) + (temp2);
            temp3 = temp3%1000000; 
            temp/= 100;
            //lon = temp+((float)temp3/600000);
            current_loc.lng		= (temp * t7) + ((temp3 * 100) / 6);
            
            gps_rel_pos(home, current_loc_deg, BXY);
            
              //Serial.println(brng,DEC);   //Check that our conversion from lat-lng to XY works
              //Serial.print("BXY:,");
              //Serial.print(BXY[0],DEC);
              //Serial.print(",");
              //Serial.println(BXY[1],DEC);

            token = strtok_r(NULL, search, &brkb); //lon, east or west?
            if(*token == 'W'){
              current_loc.lng *= -1;
            }

            token = strtok_r(NULL, search, &brkb); //Speed overground?
            ground_speed = atoi(token) * 100;

            token = strtok_r(NULL, search, &brkb); //Course?
            ground_course = atoi(token) * 100;

            //GPS_update |= GPS_POSITION; //Update the flag to indicate the new data has arrived. 

          }
          checksum = 0;
        }//End of the GPRMC parsing


        // *********WIMWV***********

        if (strncmp (gps_buffer, head_WIMWV, 5) == 0)//now looking for GPGGA head....
        {
          /*Generating and parsing received checksum, */
          for(int x = 0; x<100; x++)
          {
            if(gps_buffer[x]=='*')
            { 
              checksum_received = strtol(&gps_buffer[x + 1], NULL, 16);//Parsing received checksum...
              break; 
            }
            else
            {
              checksum^= gps_buffer[x]; //XOR the received data... 
            }
          }

          //Serial.println(checksum_received,DEC);
          //Serial.println(checksum,DEC);

          if(checksum_received== checksum)//Checking checksum
          {

            //strcpy(gps_GGA,gps_buffer);

            token = strtok_r(gps_buffer, search, &brkb);//GPGGA header, not used anymore
            token = strtok_r(NULL, search, &brkb);// Wind angle!
            tempTR=atof(token);
            //if (tempTR != 0) {
            //vwthetaBR = tempTR;
            token = strtok_r(NULL, search, &brkb);// Relative R or Theoretical, T
            tokentemp = token;
            if (*token == 'R'){
              if ((WINDTEST == 0) || (WINDTEST == 3))
              {
                vwthetaBR = tempTR;
                //vwthetaBRtmp = tempTR;
              }
              else
              {
                vwthetaBR = vwthetaBR;
              }
            }
            else if (*token == 'T'){
              vwthetaBT = tempTR;
            }
            //else {
             // vwthetaBR = 0;
             // vwthetaBT = 0; 
            //}  
            token = strtok_r(NULL, search, &brkb); // Wind Speed in knots
            if (*tokentemp == 'R') {
              vwR=atof(token);
            }
            else if (*tokentemp == 'T') {
             vwT =atof(token);
            }
          }
          checksum = 0; //Restarting the checksum 
        } // END OF MWV parsing




        // *********WIMWD***********

        if (strncmp (gps_buffer, head_WIMWD, 5) == 0)//now looking for GPGGA head....
        {
          /*Generating and parsing received checksum, */
          for(int x = 0; x<100; x++)
          {
            if(gps_buffer[x]=='*')
            { 
              checksum_received = strtol(&gps_buffer[x + 1], NULL, 16);//Parsing received checksum...
              break; 
            }
            else
            {
              checksum^= gps_buffer[x]; //XOR the received data... 
            }
          }

          //Serial.println(checksum_received,DEC);
          //Serial.println(checksum,DEC);

          if(checksum_received== checksum)//Checking checksum
          {

            //strcpy(gps_GGA,gps_buffer);

            token = strtok_r(gps_buffer, search, &brkb);//GPGGA header, not used anymore
            token = strtok_r(NULL, search, &brkb);// Wind angle True!
            if ((WINDTEST == 0) || (WINDTEST == 2))
            {
              vwthetaTtmp = atof(token);
            }
            else
            {
              vwthetaTtmp = vwthetaTtmp;
            }
            token = strtok_r(NULL, search, &brkb);// True
            token = strtok_r(NULL, search, &brkb); // Wind angle Mag
            vwthetaM = atof(token);
            token = strtok_r(NULL, search, &brkb);  //wind speed knots
            vw = atof(token);


          }
          checksum = 0; //Restarting the checksum 
        } // END OF MWV parsing




        for(int a = 0; a<= counter; a++)//restarting the buffer
        {
          gps_buffer[a]= 0;
        }
        counter = 0; //Restarting the counter  
      }
      else 
      {
        counter++; //Incrementing counter
        if (counter >= 200)
        {
          //Serial.flush();
          counter = 0;
          checksum = 0;
          unlock = 0;
        }
      }
    }
  }
  //Serial.print("Heading TRU:  ");Serial.println(vbthetaT,DEC);
  //Serial.print("Heading MAG:  ");Serial.println(vbthetaM,DEC);
  //Serial.print("Lat/Long:  ");Serial.print(current_loc.lat);Serial.print("___");Serial.println(current_loc.lng);
  //Serial.print("Wind dir BR:  ");Serial.println(vwthetaBR,DEC);
  //Serial.print("Wind spd R:  ");Serial.println(vwR,DEC);
  //Serial.print("GPSLOCK:   ");Serial.println(GPSLOCK,BIN);
  //delay(1000);
}


void wind_average(void)
{
//  //------------------Bow-Relative Moving Average----------------------   Wait it doesn't make sense to do this. What if the boat turns. Need this calculated from the average wind
////  if(WINDTEST != 1 || WINDTEST != 2)   // UNCOMMENT these IFs if you don't want MA with WINDTEST
////  {
//    av_cnt_BR ++;
//    
//    if (av_cnt_BR > L_BR-1) {
//      av_cnt_BR = L_BR-1;    // at 1Hz this is a 2 minute moving average
//    }
//    
//    for (int i=0;i<av_cnt_BR-1;i++)
//    {
//      vwthetaBRarr[i] = vwthetaBRarr[i+1]; 
//    }
//    vwthetaBRarr[av_cnt_BR]  = vwthetaBRtmp;
//    
//    vwthetaBR = 0;
//    for (int i=0;i<av_cnt_BR;i++)
//    {
//      vwthetaBR += vwthetaBRarr[i];
//    }
////    Serial.println("vwthetaBR");
////    Serial.println(vwthetaBRtmp,DEC);
////    Serial.println(vwthetaBR,DEC);
////    Serial.println(av_cnt_BR,DEC);
//    vwthetaBR = vwthetaBR/(av_cnt_BR);
////  }
////    Serial.println(vwthetaBR,DEC);
////    Serial.println(' ');
    
    
  //------------------True Wind Moving Average------------------------
  if((WINDTEST == 0) || (WINDTEST == 2))
  {
    av_cnt_T ++;
    
    if (av_cnt_T > L_T-1) {
      av_cnt_T = L_T-1;    // at 1Hz this is a 2 minute moving average
    }
    
    for (int i=0;i<av_cnt_T-1;i++)
    {
      vwthetaTarr[i] = vwthetaTarr[i+1]; 
    }
    vwthetaTarr[av_cnt_T]  = vwthetaTtmp;
    
    vwthetaT = 0;
    for (int i=0;i<av_cnt_T;i++)
    {
      vwthetaT += vwthetaTarr[i];
    }
    //Serial.println("vwthetaT");
    //Serial.println(vwthetaTtmp,DEC);
    //Serial.println(vwthetaT,DEC);
   // Serial.println(av_cnt_T,DEC);
    vwthetaT = vwthetaT/(av_cnt_T);
    // Serial.println(vwthetaT,DEC);
    //Serial.println(' ');
  }
  else if((WINDTEST == 1) || (WINDTEST ==0))
  {
    vwthetaT = vwthetaTtmp;
  }
}







