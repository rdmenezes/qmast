int displayMenu()
{
  /*
  Menu tasks:
   change the time to exit station-keeping (ie 2 minutes before 5 minutes in very light wind, at 5 minute in strong wind, based on subjective idea of how long the boat might take to leave the square)
   switch rudder/sail control directions (ie different mechanical setups may reverse which direction is left/right, in/out);
   enable RC mode; 
   input GPS locations for a regular course and for station-keeping;
   *option to clear these waypoints without having to overwrite;
   tell the boat to start navigating a course; 
   tell the boat to start station-keeping; 
   */  					
	boolean hasSelection = false;
	char selection; // = 'r';
        boolean compassData = false;
        boolean windData = false;
        boolean speedData = false;
	boolean hasX = false;
        boolean hasY = false;
        boolean donePoints;  //check for waypoint input completion
        boolean hasValue = false;
        
        float gpsDigit = 0;
        float power = 3;
        int coornum = 0;
        int i;            //counter
        char cont;          //check for adding more waypoints  
        char wayNum;        
        char select;        //select for clearing data        
        char sailDirection;       
        int pointNum;	
        int negateX = 1;
        int negateY = 1;
	float temp;              
        char gpsData;
        
        //rc mode values

       int sailsVal;
       int rudVal;
       char rcVal; 
	//GAELFORCE!
	
	Serial.println("");
              //return stuff based on inputs, 0 for unchanged 
	while(true)
	{
		//menu options
		Serial.println("|");        //symbol for stopping RC mode
		Serial.println("___________________  MENU  ______________________");
		Serial.println("");
		Serial.println("");
		Serial.println("a.     *Input Waypoints");
		Serial.println("b.	Begin course sailing");
		Serial.println("c.     *Straight sail");
		Serial.println("d.	Sail to waypoint");
                Serial.println("i.      Fleet Racing mode");
		Serial.println("j.     *Exit Menu");
                Serial.println("k.      Stationkeeping");
                Serial.println("l.     *View Current waypoints");
                Serial.println("m.     *Clear all waypoints");
                Serial.println("n.     *Toggle Rudder direction");
                Serial.println("o.     *perform diagnostics");
                Serial.println("p.     *get gps coordinate");
                Serial.println("r.     *super Zigbee RC mode");
                Serial.println("s.     *keyboard Zigbee RC mode");
                Serial.println("t.      Single point stationkeeping");
                Serial.println("u.     *Change Station Keeping time before exit");
                Serial.println("z.     *Clear serial buffer");
		Serial.println("|");      // symbol for stopping RC mode 
		Serial.println("Select option:");
		
		//clears values from previous menu selection
		Serial.flush();
		
		//waits for user input to come from serial port
		while(hasSelection == false)
		{
			if(Serial.available() > 0)
			{ 
				selection = Serial.read(); //Val: switched to char values since out of single digits // - '0';     //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)			
				hasSelection = true;
			}	
		}		
		//calls appropriate function, and returns to the menu after function execution
		switch(selection)
		{
			//call input waypoints function
                        //assuming that waypoints are of the form XXXX.XXXX....X
			case 'a':
			      Serial.println("Selected a");
                              do{
                                hasX = false;
                                hasY = false;	
                                donePoints = false;
                                power = 1;
                                do{Serial.println("Enter Which coordinate to update:  ");
                                while(Serial.available() == 0);    //wait until serial data is available            
                                coornum = Serial.read() - '0';
                                if(coornum > 9){
                                 Serial.println("Invalid coordinate");
                                 Serial.println("Exiting waypoint update");
                                  return 0;
                                 break; 
                                }
                               }while((coornum < 0) || (coornum > 9));
                                  waypoints[coornum] = clearPoints;
                                /*
                                BASIC LOGIC TO PARSE COORDINATES
                                
                                The Serial input can only take 1 character at a time, so you have to read each character from the input co-ordinate (eg. 1234.5678) 
                                and then rebuild the co-ordinate inside the arduino.  The way this program does it is to keep a running "power" variable.  Each time 
                                a new character is read, it is mulitplied by 10^power, then added to the final value.  Power is then deceremented by one and the
                                process is repeated until there are no more characters to be read.
                                Values are stored in the waypoints struct under latDeg, latMin, lonDeg, lonMin, Multiple values can now be entered. 
                                */
                                Serial.println("Co-ordinate must be entered DDMMmmmm.");
                                Serial.println("Period must be at the end in order to parse correctly");
                                Serial.println("Enter GPS X Co-ordinate:  ");
                                while(!hasX){
                                  if(Serial.available() > 0){
                                    //Code to get serial data from the buffer and put it into GPSX
                                      for (i = 0; i < 2; i++){                                     
                                          while(Serial.available() == 0);    //wait until serial data is available
                                          gpsDigit = Serial.read() - '0';
                                          if(gpsDigit == -3){        //checks for negative
                                             negateX = -1;
                                             i--; 
                                          }
                                          else{
                                             waypoints[coornum].latDeg += (gpsDigit*pow(10,power));
                                             power--;                
                                          }      
                                      }
                                      waypoints[coornum].latDeg *= negateX;
                                      power = 1;
                                      do{     
                                          while(Serial.available() == 0);    //wait until serial data is available
                                          gpsDigit = Serial.read() - '0';
                                          if(gpsDigit >= 0){
                                             waypoints[coornum].latMin += (gpsDigit*pow(10,power));                                            
                                             power--;                
                                          }    
                                     }while(gpsDigit != (46-'0'));              
                                      while(power > -5){
                                          gpsDigit = Serial.read() - '0';  
                                          waypoints[coornum].latMin += gpsDigit*pow(10.0,power);
                                          power--;                                  
                                      }
                                      hasX = true;
                                      Serial.println(waypoints[coornum].latDeg,0);
                                      Serial.println(waypoints[coornum].latMin,4);
                                      waypoints[coornum].latMin *= negateX;
                                  }                                                                                                 
                                }
                                power = 1;
                                
                                Serial.println("Enter GPS Y Co-ordinate:  ");
                                while(!hasY){
                                    if(Serial.available() > 0){
                                    //Code to get serial data from the buffer and put it into GPSX
                                        for (i = 0; i < 2; i++){                                      
                                            while(Serial.available() == 0);    //wait until serial data is available
                                            gpsDigit = Serial.read() - '0';
                                            if(gpsDigit == -3){        //checks for negative
                                               negateY = -1;
                                               i--; 
                                            }
                                            else{ waypoints[coornum].lonDeg += (gpsDigit*pow(10,power));
                                               power--;                
                                            }      
                                       }
                                      waypoints[coornum].lonDeg *= negateY;
                                      power = 1;
                                      do{     
                                          while(Serial.available() == 0);    //wait until serial data is available
                                          gpsDigit = Serial.read() - '0';
                                          if(gpsDigit >= 0){
                                          waypoints[coornum].lonMin += (gpsDigit*pow(10,power));                                         
                                          power--;                
                                          }    
                                     }while(gpsDigit != (46-'0'));               
                                      while(power > - 5){
                                          gpsDigit = Serial.read() - '0';  
                                          waypoints[coornum].lonMin += gpsDigit*pow(10.0,power);
                                          power--;                                  
                                      }
                                      hasY = true;
                                      Serial.println(waypoints[coornum].lonDeg,0);
                                      Serial.println(waypoints[coornum].lonMin,4);
                                      waypoints[coornum].lonMin *= negateY; 
                                    }                                                                                                 
                                }                                                                                              
                                Serial.print("Entered waypoints:  X = ");
                                Serial.print(waypoints[coornum].latDeg,0);
                                Serial.print(waypoints[coornum].latMin,4);
                                Serial.print(" ,Y = ");
                                Serial.print(waypoints[coornum].lonDeg,0);
                                Serial.println(waypoints[coornum].lonMin,4);
                                Serial.println("Enter Another? (y/n)");
                                while(Serial.available() == 0); 
                                cont = Serial.read();
                                if(cont == 'y'){
                                   donePoints = true; 
                                }  
                              } while(donePoints == true);
                                donePoints = false;
                                return 0; //function set waypoints but then still need to tell boat what to do commenting out the return forces back to menu
				break;
				
				//start automated sailing	
			case 'b':
                                //      calls functions to begin automated sailing currently calls sailCourse, 
                                //      asks how many waypoints you need and allows you to select the waypoint you want for each location
				Serial.println("Selected course sailing. Currently testing in menu.");				
                                Serial.println("Enter number of waypoints");
                                hasValue = false;
                                while(hasValue == false){
                                    while(Serial.available() == false);
                                    points = Serial.read() - '0';
                                    for(i = 0; i < points; i++){
                                        Serial.print("Select waypoint for waypoint ");
                                        Serial.println(i);
                                        while(Serial.available() == false);
                                        pointNum = Serial.read() - '0';
                                        if (pointNum > 9){
                                          Serial.println("Error, not a valid point, exiting course sailing");
                                          return 0;
                                          break;
                                        }
                                        coursePoints[i] = waypoints[pointNum];                                        
                                        Serial.println("added waypoint to course");
                                    }                                  
                                    hasValue = true;
                                }
                                Serial.println("sailing course");
                                currentPoint = 0;
                                return 2;
				break;				
				//sets sails and rudder to go in a direction
                                 //if upwind the boat will try to sail closehauled direction
			case 'c':
				Serial.println("Enter desired compass direction (n, s, e, w): ");
             
				while(hasValue == false)
				{
					if(Serial.available() > 0)
					{ 
						sailDirection = Serial.read();    //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)	
                                                switch(sailDirection)
                                              {  //the input char sailDirection
                                                case 'n':
                                                  StraightSailDirection = 0;
                                                  hasValue = true;
                                                break;
                                                case 's':
                                                  StraightSailDirection = 180;
                                                  hasValue = true;
                                                break;
                                                case 'e':
                                                  StraightSailDirection = 90;
                                                  hasValue = true;
                                                break;
                                                case 'w':
                                                  StraightSailDirection = 270;
                                                  hasValue = true;
                                                break;
                                                default:
                                                  Serial.println("Invalid entry, please enter n,s,e or w");
                                                break;
                                              }                                                
					}      
				}
                                Serial.print("Sailing towards: ");
                                Serial.print(StraightSailDirection, DEC);
                                Serial.println(" degrees.");
                                return 3;		
				break;
				
				//call sail to waypoint from the waypoint of your choosing
				case 'd':
					Serial.println("Selected Sail To Waypoint. Please choose a waypoint.");	                      
                                        hasValue = false;
                                        while(hasValue == false){
                                            while(Serial.available() == false);
                                            point = Serial.read() - '0'; 
                                            if(point > 9){
                                             Serial.println("Error, not a valid point, exiting waypoint sailing");
                                            }
                                            hasValue = true;                                         
                                        }       
                                        Serial.println("sail to Waypoint");                             
                                        return 4;
  					break;	

					//puts boat in fleet racing mode, where rudder is manual but sails are autonomous
                                case 'i':
                                        Serial.println("Selected Fleet Racing Mode (autonomous sails, RC rudder.");
                                        Serial.println("Press q to return to menu.");
                                        rudderDir *= -1;
                                        Serial.println("~");
                                        hasValue = false;
                                        sailsVal = 0;
                                        rudVal = 0;                                       
                                        while (hasValue == false){
                                             while(Serial.available() == false);
                                             rcVal = Serial.read();
                                             switch(rcVal)
                                                 {                                                          
                                                 case '1'://rudder values are from 120 to 180, ignore the 1 then subtract 50 to get actual -30 to 30 value
                                                         while(!Serial.available());
                                                         rudVal = Serial.read() - '0';
                                                         while(!Serial.available());
                                                         rudVal = rudVal*10 + Serial.read() - '0';
                                                         rudVal -= 50;
                                                         setrudder(rudVal);
                                                         break;                                                        
                                                 case 'q':
                                                         hasValue = true;
                                                         Serial.println("exiting RC mode");
                                                         delay(2000);
                                                         Serial.flush();
                                                         Serial.println("||||||||||||||||||||||||||||||||||||||||||||||");                  //ending symbol, lots so that the boat does not miss it
                                                         rudderDir *= -1;
                                                         break;
                                                 }
                                                 sailControl();     //calling this will cause a spamming of the Serial port, will have lag exiting                                                      
                                                 if (Serial.available() > 20)
                                                 Serial.flush();   
                                        } 
                                        return 0;
                                        break;                                                                                      
                                        
			        case 'j':
				        Serial.println("Exiting Menu");
                                        return 0;
                                        break;
                                                //attempts to stationkeep by creating a box within the stationkeeping box and sailing on a bream reach between 2
                                case 'k':
                                        Serial.println("StationKeeping");   //stationkeeping menu item, currently untested
                                        Serial.println("Using the first 4 coordinates as corners"); //cannot access menu when stationkeeping                                          
                                        for(i = 0; i < 4; i++){                                                  
                                            stationPoints[i] = waypoints[i];                                          
                                        }
                                        stationCounter = 2;
                                        timesUp = false;
                                        startTime = millis();//record the starting clock time
                                        Serial.println("StationKeeping");
                                        return 1;
                                        break;
                                                //shows all the waypoints currently entered
                                case 'l':
                                        Serial.println("View Waypoints"); //shows all waypoints that have been entered
                                        for(i = 0; i < 10; i++){
                                            Serial.print( i );
                                            Serial.print(" ");
                                            Serial.print(waypoints[i].latDeg,0);
                                            Serial.print(waypoints[i].latMin,4);
                                            Serial.print(" ");
                                            Serial.print(waypoints[i].lonDeg,0);
                                            Serial.println(waypoints[i].lonMin,4);
                                        }
                                        Serial.println("View Course");
                                        for(i = 0; i < 10; i++){
                                            Serial.print( i );
                                            Serial.print(" ");
                                            Serial.print(coursePoints[i].latDeg,0);
                                            Serial.print(coursePoints[i].latMin,4);
                                            Serial.print(" ");
                                            Serial.print(coursePoints[i].lonDeg,0);
                                            Serial.println(coursePoints[i].lonMin,4);
                                        }
                                        Serial.println("View Stationkeeping Points");
                                        for(i = 0; i < 4; i++){
                                            Serial.print( i );
                                            Serial.print(" ");
                                            Serial.print(stationPoints[i].latDeg,0);
                                            Serial.print(stationPoints[i].latMin,4);
                                            Serial.print(" ");
                                            Serial.print(stationPoints[i].lonDeg,0);
                                            Serial.println(stationPoints[i].lonMin,4);
                                        }    
                                        Serial.println("View boat location");
                                        Serial.print(boatLocation.latDeg,0);
                                        Serial.print(boatLocation.latMin,4);
                                        Serial.print(" ");
                                        Serial.print(boatLocation.lonDeg,0);
                                        Serial.println(boatLocation.lonMin,4);
                                        return 0;
                                        break;   
                                                //clears all wayooints in the waypoints array
                                case 'm':
                                        Serial.println("Clear all waypoints? (y/n)");
                                        while(hasValue == false){
                                            if(Serial.available() > 0){
                                                select = Serial.read();
                                                if(select == 'y'){
                                                    for(i = 0; i < 10; i++){
                                                        waypoints[i] = clearPoints;
                                                        hasValue = true;
                                                        Serial.println("Cleared");
                                                    }
                                                 }else if(select == 'n'){
                                                      Serial.println("no changes made");
                                                      hasValue = true;
                                                      break;
                                                 }  
                                                  else{ 
                                                      Serial.println("invalid input");
                                                 }
                                            }
                                        }
                                        return 0;
                                        break;
                                        //changes rudder direction
                                case 'n':
                                        Serial.println("Toggle rudder direction");
                                        rudderDir *= -1;
                                        return 0;
                                        break;
                                        //basic diagnostic to see if everything is turning properly and all sensors are working
                                case 'o':
                                        Serial.println("Performing Diagnostic and calibration tests");
                                        Serial.println("Turning Rudder right 30");
                                        setrudder(-30);
                                        delay(1000);
                                        Serial.println("Turning Rudder left 30");
                                        setrudder(30);
                                        delay(1000);
                                        Serial.println("Centering rudder");
                                        setrudder(0);
                                        delay(1000);
                                        Serial.println("Setting Jib all out");
                                        setJib(ALL_OUT);
                                        delay(6000);
                                        Serial.println("Setting Jib all in");
                                        setJib(ALL_IN);
                                        delay(6000);                                           
                                        Serial.println("Setting main all out");
                                        setMain(ALL_OUT);       
                                        delay(5000);                                        
                                        Serial.println("Setting main all in");
                                        setMain(ALL_IN);
                                        delay(5000);                                               
                                        Serial.println("testing compass");
                                         sensorData(BUFF_MAX,'c');        						
                                        if(compassData == false){
                                            Serial.println("Compass Data: ");
                                            Serial.print("  Heading:  ");
                                            Serial.println(headingc);
                                            Serial.print("  Pitch:   ");
                                            Serial.println(pitch);
                                            Serial.print("  Roll   ");
                                            Serial.println(roll);                                                  
                                        }
                                        else{
                                            Serial.println("Error fetching compass data");
                                        }
                                        Serial.println("testing wind sensor");                                                
					sensorData(BUFF_MAX,'w');                                   
                                        Serial.println("Wind Sensor Data: ");
                                        Serial.print("  Wind Angle:  ");
                                        Serial.println(wind_angl);
                                        Serial.print("  Wind Velocity (knots):   ");
                                        Serial.println(wind_velocity);                                                                                          
                                        Serial.println("testing complete");
                                        return 0;
                                        break;
                                case 'p':  //returns your current position
                                        Serial3.flush();
                                        delay(500);
                                        sensorData(BUFF_MAX,'w');
                                        Serial.print(boatLocation.latDeg,0);
                                        Serial.print(boatLocation.latMin,4);
                                        Serial.print(" ");
                                        Serial.print(boatLocation.lonDeg,0);
                                        Serial.println(boatLocation.lonMin,4);
                                        Serial.println("");
                                        hasValue = false;
                                        Serial.println("Would you like to save point? (y/n)");
                                        while(hasValue == false){
                                            if(Serial.available() > 0){
                                                select = Serial.read();
                                                if(select == 'y'){                                                
                                                    Serial.println("enter a number for the point"); 
                                                    gpsData = false;
                                                    while(gpsData == false){                                              
                                                        while(Serial.available() == false);
                                                        pointNum = Serial.read()-'0';
                                                        waypoints[pointNum] = boatLocation;
                                                        Serial.println("added waypoint");
                                                        Serial.println(pointNum);
                                                        gpsData = true;
                                                        hasValue = true;
                                                    }
                                                }
                                                else if(select == 'n'){
                                                    Serial.println("no changes made");
                                                    hasValue = true;
                                                    break;
                                                }  
                                                else{ 
                                                    Serial.println("invalid input");
                                                }
                                            }
                                        }  
                                        return 0;                                        
                                        break;
                                        
                                case 'r':  //Direct rudder and sail control

                                        Serial.println("RC mode, receives inputs from other arduino and hacked old transmitter");
                                        Serial.println(" 'q' exits back to menu, you might need to press it up to 3 times.");
                                        Serial.println("~");
                                        rudderDir *= -1;
                                        hasValue = false;
                                        sailsVal = 0;
                                        rudVal = 0;
                                        while (hasValue == false){
                                            while(Serial.available() == false);
                                            rcVal = Serial.read();
                                            switch(rcVal)
                                            {  
                                            case '1'://rudder values are from 120 to 180, ignore the 1 then subtract 50 to get actual -30 to 30 value
                                                    while(!Serial.available());
                                                    rudVal = Serial.read() - '0';
                                                    while(!Serial.available());
                                                    rudVal = rudVal*10 + Serial.read() - '0';
                                                    rudVal -= 50;
                                                    setrudder(rudVal);
                                                    break; 
                                            case '2'://sails values are from 220 to 280, ignore the 2 then subtract 50 to get actual -30 to 30 value
                                                    while(!Serial.available());
                                                    sailsVal = Serial.read() - '0';
                                                    while(!Serial.available());
                                                    sailsVal = sailsVal*10 + Serial.read() - '0';
                                                    sailsVal -= 25;
                                                    sailsVal *= 2; 
                                                    setSails(sailsVal);                                                          
                                                    break;                                                       
                                            case 'q':
                                                    hasValue = true;
                                                    Serial.println("exiting RC mode");
                                                    delay(2000);
                                                    Serial.println("||||||||||||||||||||||||||||||||||||||||||||||");            //ending symbol, lots so that it is not missed
                                                    rudderDir *= -1;
                                                    break;
                                            }                                                                                                            
                                        }
               //                         sensorData(BUFF_MAX, 'c');
               //                         sensorData(BUFF_MAX, 'w'); 
              //                          transmit(); 
                                        return 0;                                               
                                        break;
                                                               //keyboard based RC mode,                 
                                case 's':
                                        rudderDir *= -1;
                                        static int rudcount;
                                        Serial.println("RC mode, use a/d for rudder control with s to center, w/e for fine sails, q/r for coarse sails");
                                        Serial.println(" 'y' exist back to menu");
                                        hasValue = false;
                                        sailsVal = 0;
                                        rudVal = 0;
                                        while (hasValue == false){
                                            while(Serial.available() == false);
                                            rcVal = Serial.read();
                                            switch(rcVal){  //the input char sailDirection                                                        
                                                case 'a':
                                                        rudcount = 0;
                                                        if(rudVal < 28){
                                                            rudVal += 2;
                                                        }
                                                        else{
                                                            rudVal = 30;
                                                        }                                                      
                                                        break;
                                                case 'd':
                                                        rudcount = 0;
                                                        if(rudVal > -28){
                                                            rudVal -= 2;
                                                        }
                                                        else{
                                                            rudVal = -30;
                                                        }                                                                                                              
                                                        break;
                                                case 's':
                                                        rudVal = 0;
                                                        break;
                                                case 'w':                                           
                                                        if(sailsVal < 95){
                                                            sailsVal += 5;
                                                        }
                                                        else{
                                                            sailsVal = 100;
                                                            }                                                        
                                                        break;
                                                case 'e':
                                                        if(sailsVal > 4){
                                                            sailsVal -= 5;
                                                        }
                                                        else{
                                                            sailsVal = 0;
                                                        }                                                          
                                                        break;
                                                case 'q':                                           
                                                        if(sailsVal < 100){
                                                            sailsVal += 20;
                                                        }
                                                        else{
                                                            sailsVal = 100;
                                                        }                                                           
                                                        break;
                                                case 'r':
                                                        if(sailsVal > 0){
                                                            sailsVal -= 20;
                                                        }
                                                        else{
                                                            sailsVal = 0;
                                                        }                                                         
                                                        break;
                                                case 'y':
                                                        hasValue = true;
                                                        Serial.println("exiting RC mode");
                                                        rudderDir *= -1;
                                                        break;
                                            }
                                            rudcount++;            //loop for resetting rudder to 0
                                            if(rudcount > 30){
                                                rudVal = 0; 
                                            }
                                            sensorData(BUFF_MAX, 'w');
                                            sensorData(BUFF_MAX, 'c');
                                            setrudder(rudVal);
                                            setSails(sailsVal);
                                            transmit();
                                        }
                                        return 0;
                                        break;
                                                //station keeping makes a single point inthe centre of the box and tries to stay there
                                case 't': 
                                        Serial.println("StationKeeping");   //stationkeeping menu item, currently untested
                                        Serial.println("Using the first 4 coordinates as corners");                                         
                                        for(i = 0; i < 4; i++){                                                  
                                            stationPoints[i] = waypoints[i];                                          
                                        }                                                
                                        timesUp = false;
                                        startTime = millis();//record the starting clock time
                                        Serial.println("StationKeeping");
                                        return 5;        
                                        break;
                                        //changes how long to stay in box
                                case 'u':
                                        Serial.println("Change station keeping time in box.");
                                        Serial.println("Please enter time in seconds (must have 3 digits)");
                                        int timeFudge;
                                        while(!Serial.available());
                                        timeFudge = Serial.read() - '0';
                                        while(!Serial.available());
                                        timeFudge = timeFudge*10 + Serial.read() - '0';
                                        while(!Serial.available());
                                        timeFudge = timeFudge*10 + Serial.read() - '0';
                                        Serial.print("entered:    ");
                                        Serial.println(timeFudge);
                                        StationKeepingTimeInBox = timeFudge;
                                        return 0;                                        
                                        break;                                       
                                case 'z': //If you press z it clears the serial buffer
                                        Serial.flush();
                                        Serial.println("Serial Buffer Cleared");
                                        return 0;
                                        break;
                                 default:
                                        return 0;
				        break;
			}			
	}
}	
