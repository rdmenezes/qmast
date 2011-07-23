//This program is run on the main program startup. It will write waypoints to the EEPROM and terminate when the index 999 is sent to it.



//char *token;
char *search = ",";
char *brkb, *pEnd;
static byte unlock = 1; //some kind of event flag
static byte counter = 0; //general counter
const char head_WLOAD[]="WLOAD";

char *LAT;
char *LNG;

//**PARAMETER EDITING
const char head_RUDDER[]="RUDDER";   // $RUDDER,rP,rmax*   Set the rudder gain rP and the max deflection
                                     // RUDDER PID: $RUDDER,Kp,Ki,Kd*
                                     // 0.0 < Kp,Ki,Kd < 25.6      for memory writing purposes
const char head_HEADING[]="HEADING"; // $HEADING,heading* Sail in a constant direction, set heading < 0 for boat NAV
const char head_WIND[]="WIND";       // $WIND,WT,vbthetaBR,vbthetaT*  Type WT to put boat into wind test mode
                                     // WT = A      mode 1, lock both vars                                    $WIND,A,212,121*
                                     // WT = B      mode 2, lock bow_relative wind for testing sail          $WIND,B,333*
                                     // WT = C      mode 3, lock true wind for testing navigation            $WIND,C,111*
const char head_GO[]="GO";  

const char head_POS[]="POS";         // $POS,0*   Set wing_pos to zero
const char head_AOA[]="AOA";         // $AOA,AoAUP,AoADOWN*
const char head_STNKEEP[]="STNKEEP"; // $STNKEEP,ON=1,MINS*

 //representation of GPS corrdinate DDMM.mmmm using only integers
//typedef struct {
//	short int deg;
//	short int min;
//	short int decimin1;
//	short int decimin2;
//} gps_int_t;

//EXAMPLES
//$WLOAD,1,1234.5678,9876.5432*    Write a waypoint to index 1
//$WLOAD,1,R*                      Read a waypoint to index 1
//$WLOAD,1,N*                      //number of waypoints to follow is one
//*$WLOAD,999*                    Start the program
// $RUDDER,rP,rmax*
// $RUDDER,Kp,Ki,Kd* *** for PID mode
// $HEADING,heading*
// $WIND,WT,vbthetaBR,vbthetaT*
// $POS,wing_pos*
// $AOA,AoAUP,AoADOWN*
// $STNKEEP,ON=1,MINS*
// $GO*


//typedef struct gps_int_t_struct gps_int_t;
struct gps_int_t WPT[2];

// WPT index  memory location 28+(N-1)*8;

void gps_str_to_int(char*, gps_int_t* );



void get_WPTS(void)
{
  Serial.println("Waiting to Load GPS Waypoints. Input: $WLOAD,wpti,Lat,Lng*. wpti =999 when done");
  while(WPTi != 999)
  {
    while(Serial.available() > 0)
    {
      if(unlock == 0)
      {
        comm_buffer[0] = Serial.read();//puts a byte in the buffer


        if(comm_buffer[0]=='$')//Verify if is the preamble $
        {
          counter 	= 0;
          //            checksum 	= 0;
          unlock	= 1;
          //Serial.print(comm_buffer[0]);
        }
      } 
      else {
        comm_buffer[counter] = Serial.read();
        //Serial.print(comm_buffer[counter]);     //*******PRINT EVERYTHING~

        if(comm_buffer[counter] == '*')//Looks for *
        {
          unlock = 0;

          // Parse ze data! ______________________________*******
          //------------------------RUDDER---------------------------
          if(strncmp (comm_buffer,head_RUDDER, 6) == 0)
          {
            token = strtok_r(comm_buffer, search, &brkb); //Got the header already.
            token = strtok_r(NULL, search, &brkb); // Get rudder gain
            rP=atof(token);//Rudder Proportaional gain.
            token = strtok_r(NULL, search, &brkb); // Get rudder gain
            rmax=atof(token);//Rudder Proportaional gain.

            //Apply new values
            //rudderPID.SetTunings(Kp, Ki, Kd);
            //Save new values to EEPROM I hope you remember what worked before
            EEPROM.write(11,(int)rP*10.);
            EEPROM.write(12,(int)rmax);
            //EEPROM.write(13,(int)Kd*10.);
            
            

//            token = strtok_r(NULL, search, &brkb); // Get rudder gain
//            rP=atof(token);//Rudder Proportaional gain.
//            token = strtok_r(NULL, search, &brkb); // Get rudder gain
//            rinter=atof(token);
//            token = strtok_r(NULL, search, &brkb); // Get rudder gain
//            rdead=atof(token);
//            token = strtok_r(NULL, search, &brkb); // Get rudder gain
//            rmaxerr=atof(token);
//            token = strtok_r(NULL, search, &brkb); // Get rudder gain
//            rmax=atof(token);
            
            Serial.print("Rudder P: ");Serial.println(rP,DEC);
           Serial.print("Rudder Max ");Serial.println(rmax,DEC);
           //Serial.print("Rudder D: ");Serial.println(Kd,DEC);
          }
          //------------------------HEADING---------------------------
          
          else if(strncmp (comm_buffer,head_HEADING, 7) == 0)
          {
            token = strtok_r(comm_buffer, search, &brkb); //Got the header already.
            token = strtok_r(NULL, search, &brkb); 
            heading=atof(token);//Heading  IF HEADING >0 use this to set a constant direction, if HEADING < 0 follow navigation. 
            Serial.print("Heading: ");Serial.println(heading,DEC);  
          }
          //------------------------AoA------------------------------
           else if(strncmp (comm_buffer,head_AOA, 3) == 0)
          {
            token = strtok_r(comm_buffer, search, &brkb); //Got the header already.
            token = strtok_r(NULL, search, &brkb); 
            AoAUP=atof(token);// Change the upwind AoA var
            Serial.print("AoAupwind: ");Serial.println(AoAUP,2);  
            token = strtok_r(NULL, search, &brkb); 
            AoADOWN=atof(token);// Change the upwind AoA var
            Serial.print("AoAdownwind: ");Serial.println(AoADOWN,2);
          }
          //------------------------WING_POS-------------------------
          
          else if(strncmp (comm_buffer,head_POS, 3) == 0)
          {
            token = strtok_r(comm_buffer, search, &brkb); //Got the header already.
            token = strtok_r(NULL, search, &brkb); 
            wing_pos=atof(token);//SET the wing position to zero before leaving
            motor = LOW;
            delta_wing_angle = 0;
            Serial.print("Wing_position: ");Serial.println(wing_pos,DEC);          
          }
          //-----------------------WIND-------------------------------
          else if(strncmp (comm_buffer,head_WIND, 4) == 0)
          {
            token = strtok_r(comm_buffer, search, &brkb); //Got the header already.
            token = strtok_r(NULL, search, &brkb);
            Serial.println(*token);
            if (*token == 'A')
            {
              WINDTEST = 1;

              token = strtok_r(NULL, search, &brkb);
              vwthetaBR=atof(token);     //Don't use moving average
              //vwthetaBRtmp =atof(token);   // Use moving average by filling the tmp var
              token = strtok_r(NULL, search, &brkb); 
              //vwthetaT=atof(token);
              vwthetaTtmp=atof(token);
              Serial.print("WindTest: ");Serial.println(WINDTEST,DEC);
              av_cnt_BR = 0;  //reset the MA counters
              av_cnt_T = 0;
            }
            else if (*token == 'B')
            {
              WINDTEST = 2;

              token = strtok_r(NULL, search, &brkb);
              vwthetaBR=atof(token);     //Don't use moving average
              //vwthetaBRtmp =atof(token);   // Use moving average by filling the tmp var
              Serial.print("WindTest: ");Serial.println(WINDTEST,DEC);
              av_cnt_BR = 0;  //reset the MA counters
            } 
            else if (*token == 'C')
            {

              token = strtok_r(NULL, search, &brkb); 
              //vwthetaT=atof(token);
              vwthetaTtmp=atof(token);
              WINDTEST = 3;
              Serial.print("WindTest: ");Serial.println(WINDTEST,DEC);
              av_cnt_T = 0;
            }
            else if (*token == 'Z')
            {
              WINDTEST = 0; 
              Serial.print("WindTest: ");Serial.println(WINDTEST,DEC); 
            }
//            else 
//            {
//              WINDTEST = 0;
//            }

            Serial.print("vwthetaBR: ");Serial.println(vwthetaBR,DEC);  
            Serial.print("vwthetaTtmp: ");Serial.println(vwthetaTtmp,DEC);
          }
          //----------------------Program Start------------------------------------
          else if (strncmp (comm_buffer, head_GO, 2) == 0)
          {
            WPTi = 999;  //Start the program
          }
          //---------------------Station Keeping ON--------------------------------
          else if(strncmp (comm_buffer,head_STNKEEP, 7) == 0)
          {
            token = strtok_r(comm_buffer, search, &brkb); //Got the header already.
            token = strtok_r(NULL, search, &brkb); 
            stnkeepON=atof(token); // stnkeep=1, turn on station keeping
            token = strtok_r(NULL, search, &brkb); 
            stnkeepsec=atof(token); // how many seconds we want to do it for
            if (stnkeepON==1)
            {
            Serial.print("Station Keeping is ON for : ");Serial.print(stnkeepsec,DEC);
            Serial.println("seconds. Timer will start when wpt_ind=2");
            }  
          }
          
          
          //------------------------LOAD Waypoints WLOAD---------------------------
          else if (strncmp (comm_buffer, head_WLOAD, 5) == 0)
          {

            token = strtok_r(comm_buffer, search, &brkb);// WLOAD header, not used anymore
            token = strtok_r(NULL, search, &brkb);     //find the Waypoint index 
            WPTi = atoi (token);    
            token = strtok_r(NULL, search, &brkb);
            if (*token == 'R')   // you can type $WLOAD,wpti,R* and it will read you back that wpt!
            { 
              Serial.print("WAYPOINT #");Serial.print(WPTi,DEC);
              
              WPT[0].deg = EEPROM.read(28+(WPTi-1)*8+0);
              WPT[0].min = EEPROM.read(28+(WPTi-1)*8+1);
              WPT[0].decimin1 = EEPROM.read(28+(WPTi-1)*8+2);
              WPT[0].decimin2 = EEPROM.read(28+(WPTi-1)*8+3);
              
              Serial.print("   LAT:");Serial.print(WPT[0].deg);Serial.print(WPT[0].min);Serial.print(".");Serial.print(WPT[0].decimin1);Serial.print(WPT[0].decimin2);
              
              WPT[1].deg = EEPROM.read(28+(WPTi-1)*8+4);
              WPT[1].min = EEPROM.read(28+(WPTi-1)*8+5);
              WPT[1].decimin1 = EEPROM.read(28+(WPTi-1)*8+6);
              WPT[1].decimin2 = EEPROM.read(28+(WPTi-1)*8+7);
              
              Serial.print("____LONG:");Serial.print(WPT[1].deg);Serial.print(WPT[1].min);Serial.print(".");Serial.print(WPT[1].decimin1);Serial.println(WPT[1].decimin2);
              
            }
            
            else if (*token == 'N')   // you can type $WLOAD,wpti,N* and it will set the total number of waypoints in the eeprom to round
            {
              EEPROM.write(0,WPTi);
              Serial.print(WPTi,DEC);Serial.println(" Waypoints will be followed for navigation ");
            }
            else {  
              gps_str_to_int(token,&WPT[0]);
              //store the x coord
              EEPROM.write(28+(WPTi-1)*8+0,WPT[0].deg);
              EEPROM.write(28+(WPTi-1)*8+1,WPT[0].min);
              EEPROM.write(28+(WPTi-1)*8+2,WPT[0].decimin1);
              EEPROM.write(28+(WPTi-1)*8+3,WPT[0].decimin2);
              
              Serial.print(WPT[0].deg);
              Serial.print(WPT[0].min);
              Serial.print(WPT[0].decimin1);
              Serial.print(WPT[0].decimin2);
              
            
              token = strtok_r(NULL, search, &brkb);
             
              gps_str_to_int(token,&WPT[1]);
              //store the y coord
              Serial.print(WPT[1].deg);
              Serial.print(WPT[1].min);
              Serial.print(WPT[1].decimin1);
              Serial.print(WPT[1].decimin2);
            
              EEPROM.write(28+(WPTi-1)*8+4,WPT[1].deg);
              EEPROM.write(28+(WPTi-1)*8+5,WPT[1].min);
              EEPROM.write(28+(WPTi-1)*8+6,WPT[1].decimin1);
              EEPROM.write(28+(WPTi-1)*8+7,WPT[1].decimin2);
              Serial.println("Waypoint Accepted");
            }
            
            // 
            //              checksum = 0; //Restarting the checksum 
          }
          for(int a = 0; a<= counter; a++)//restarting the buffer
          {
            comm_buffer[a]= 0;
          }
          counter = 0; //Restarting the counter  
        }
        else 
        {
          counter++; //Incrementing counter
          if (counter >= 100)
          {
            //Serial.flush();
            counter = 0;
            //              checksum = 0;
            unlock = 0;
          }
        }
      }
    }
  }
  Serial.println("Finished Loading");
}

//void gps_str_to_int(char *gps_char, struct gps_int_t *gps_int)
//{
//int temp1, temp2;
//temp1 = atoi(&gps_char[0]);
//(*gps_int).deg = temp1/100;
//(*gps_int).min = temp1-(temp1/100)*100;
//temp2 = atoi(&gps_char[5]);
//(*gps_int).decimin1 = temp2/100;
//(*gps_int).decimin2 = temp2-(temp2/100)*100;
//}

void eeprom2arr(void)  //load the EEPROM Wpts into memory and convert them into XY
{
 wp_total = EEPROM.read(0);
             //Waypoints are stored over 8 bytes starting at byte 20 in the EEPROM
              home[0].deg = EEPROM.read(28+(-1)*8+0);
              home[0].min = EEPROM.read(28+(-1)*8+1);
              home[0].decimin1 = EEPROM.read(28+(-1)*8+2);
              home[0].decimin2 = EEPROM.read(28+(-1)*8+3);
              
              home[1].deg = EEPROM.read(28+(-1)*8+4);
              home[1].min = EEPROM.read(28+(-1)*8+5);
              home[1].decimin1 = EEPROM.read(28+(-1)*8+6);
              home[1].decimin2 = EEPROM.read(28+(-1)*8+7);
              gps_rel_pos(home, home, WPTXY[0]);
              
              Serial.print("Homebase,");
              Serial.print(WPTXY[0][0],DEC);
              Serial.print(",");
              Serial.println(WPTXY[0][1],DEC);
 
 for (int n=1;n<=wp_total;n++)
 {
              WPT[0].deg = EEPROM.read(28+(n-1)*8+0);
              WPT[0].min = EEPROM.read(28+(n-1)*8+1);
              WPT[0].decimin1 = EEPROM.read(28+(n-1)*8+2);
              WPT[0].decimin2 = EEPROM.read(28+(n-1)*8+3);
              
              WPT[1].deg = EEPROM.read(28+(n-1)*8+4);
              WPT[1].min = EEPROM.read(28+(n-1)*8+5);
              WPT[1].decimin1 = EEPROM.read(28+(n-1)*8+6);
              WPT[1].decimin2 = EEPROM.read(28+(n-1)*8+7);
              
              gps_rel_pos(home, WPT, WPTXY[n]);
              Serial.print("WPT#, ");
              Serial.print(n,DEC);
              Serial.print(",");
              Serial.print(WPTXY[n][0],DEC);
              Serial.print(",");
              Serial.println(WPTXY[n][1],DEC);
 }
}
void eeprom2rud(void)
{
  rP = EEPROM.read(11);
  rP = rP/10.;
  rmax = EEPROM.read(12);
  rmax = rmax;
  //Kd = EEPROM.read(13);
  //Kd = Kd/10.;
}

