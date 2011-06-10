//Andrew Brannan wrote the skeleton of this during 2010-2011
//returns the value of the menu item so loop knows what to do.
//returns 0 when all updating happened in the menu (e.g. setting RC mode) and code should continue with previous selection
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
   report data; 
   probably some other things that we'll think of as we parking-lot test
   adjust for compass declination
   Neat ideas:
   - verbose mode
   */  
  
	boolean stayInMenu = true; 					
	boolean hasSelection = false;
	boolean hasSailDirection = false;
	char selection;
	boolean someVal = false;
	boolean hasTackVal = false;
        boolean compassData = false;
        boolean windData = false;
        boolean speedData = false;
	boolean hasX = false;
        boolean hasY = false;
        boolean badGPS = false;
        boolean hasRudderRCvalue = false;
        boolean hasSailsRCvalue = false;
        float gpsDigit = 0;
        float power = 3;
        int coornum = 0;
        int i;            //counter
        char cont;          //check for adding more waypoints
        boolean donePoints;  //check for waypoint input completion  
        char wayNum;        
        char select;        //select for clearing data
        boolean hasVal = false;
        
	char sailDirection;
        byte rudderRCvalue;
        byte sailsRCvalue;
	byte tackVal;
        boolean hasCourse;
        int pointNum;
	
        boolean hasPoint;
        int negateX = 1;
        int negateY = 1;
	float temp;
        boolean validData;
        
        char gpsData;
        
        //rc mode values
        
       boolean hasQ;
       int rudderVal;
       int sailsVal;
       char rcVal; 
	//GAELFORCE!
		
	
	Serial.println("");
	
	//Val: not anymore, now return stuff based on inputs, 0 for unchanged //this loops through the menu until the user has selected the "exit menu" function 
	while(true)//stayInMenu == true)
	{
		//menu options
		Serial.println("|");
		Serial.println("___________________  MENU  ______________________");
		Serial.println("");
		Serial.println("");
		Serial.println("a.	Input Waypoints");
		Serial.println("b.	Begin course sailing");
		Serial.println("c.     *Straight sail");
		Serial.println("d.	Sail to waypoint");
		Serial.println("e.	Tack");
		Serial.println("f.	*Get Wind Sensor Data");
		Serial.println("g.      *Get Compass Data");
                Serial.println("h.      Get Speed Data");
                Serial.println("i.     *Toggle RC");
		Serial.println("j.     *Exit Menu");
                Serial.println("k.      Stationkeeping");
                Serial.println("l.     *View Current waypoints");
                Serial.println("m.     *Clear all waypoints");
                Serial.println("n.     *Toggle Rudder direction");
                Serial.println("o.     *perform diagnostics");
                Serial.println("p.      get gps coordinate");
                Serial.println("r.      super Zigbee RC mode");
                Serial.println("s.      keyboard Zigbee RC mode");
                Serial.println("z.     *Clear serial buffer");
		Serial.println("|");
		Serial.println("Select option:");
		
		//clears values from previous menu selection
		hasSelection = false;
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
		//Serial.println(selection,BYTE);    this prints the input, but the serial input is stored as its ASCII value, (ie 1 = 49, 2 = 50, etc)
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
                               }while((coornum < 0) || (coornum > 9));
                                waypoints[coornum] = clearPoints;
                                /*
                                BASIC LOGIC TO PARSE COORDINATES
                                
                                The Serial input can only take 1 character at a time, so you have to read each character from the input co-ordinate (eg. 1234.5678) 
                                and then rebuild the co-ordinate inside the arduino.  The way this program does it is to keep a running "power" variable.  Each time 
                                a new character is read, it is mulitplied by 10^power, then added to the final value.  Power is then deceremented by one and the
                                process is repeated until there are no more characters to be read.
                                Values are stored in the waypoints struct under latDeg, latMin, lonDeg, lonMin, Multiple values can now be entered. 
                                what about negative numbers???
                                */
                              
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
                                       waypoints[coornum].latDeg =  waypoints[coornum].latDeg + (gpsDigit*pow(10,power));
                                            
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                
                                        }      
                                      }
                                      waypoints[coornum].latDeg *= negateX;
                                      power = 1;
                                 do{     
                                       while(Serial.available() == 0);    //wait until serial data is available
                                      gpsDigit = Serial.read() - '0';
                                      if(gpsDigit >=0){
                                      waypoints[coornum].latMin =  waypoints[coornum].latMin + (gpsDigit*pow(10,power));
                                            
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                
                                      }    
                                 }while(gpsDigit != (46-'0'));  
                               
                                   // if(badGPS = true)
                                   //   break;
                              //     gpsDigit = Serial.read() ; //Just reading the '.' to get rid of it and get too the stuff after the decimal
                                    //power--;                  
                                    while(power > -5){
                                      gpsDigit = Serial.read() - '0';  
                                     waypoints[coornum].latMin =  waypoints[coornum].latMin + gpsDigit*pow(10.0,power);
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
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

                                     else{ waypoints[coornum].lonDeg =  waypoints[coornum].lonDeg + (gpsDigit*pow(10,power));
                                            
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                
                                        }      
                                      }
                                      waypoints[coornum].lonDeg *= negateY;
                                      power = 1;
                      do{     
                                       while(Serial.available() == 0);    //wait until serial data is available
                                      gpsDigit = Serial.read() - '0';
                                      if(gpsDigit >=0){
                                      waypoints[coornum].lonMin =  waypoints[coornum].lonMin + (gpsDigit*pow(10,power));                                         
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                
                                      }    
                                 }while(gpsDigit != (46-'0'));  
                               
                                   // if(badGPS = true)
                                   //   break;
                              //     gpsDigit = Serial.read() ; //Just reading the '.' to get rid of it and get too the stuff after the decimal
                                    //power--;                  
                                    while(power > -5){
                                      gpsDigit = Serial.read() - '0';  
                                     waypoints[coornum].lonMin =  waypoints[coornum].lonMin + gpsDigit*pow(10.0,power);
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
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
                              }while(donePoints == true);
                                donePoints = false;
                              //  return 0; //function set waypoints but then still need to tell boat what to do commenting out the return forces back to menu
				break;
				
				//start automated sailing	
			case 'b':
				Serial.println("Selected course sailing. Currently testing in menu.");
				//Sail();      calls functions to begin automated sailing currently calls sailCourse, but cannot break out of loop
                                Serial.println("Enter number of waypoints");
                                hasCourse = false;
                                while(hasCourse == false){
                                  while(Serial.available() ==false);
                                  points = Serial.read() - '0';
                                  for(i = 0; i < points; i++){
                                    Serial.print("Select waypoint for waypoint ");
                                    Serial.println(i);
                                    while(Serial.available() == false);
                                     pointNum = Serial.read();
                                     coursePoints[i] = waypoints[i];
                                     Serial.println("added waypoint to course");
                                    }
                                  
                                  hasCourse = true;
                                }
                                return 2;//update this when it does something :)
				break;
				
				//call rudder angle set function
			case 'c':
				Serial.println("Enter desired compass direction (n, s, e, w): ");
                                //april 8th 2011 in process of being hacked from set rudder angle to set sail angle, Valerie is being really lazy and keeping the name rudderAngle for now
				while(hasSailDirection == false)
				{
					if(Serial.available() > 0)
					{ 
						//this will have to be changed to use Serial.readln function
						sailDirection = Serial.read(); //- '0'; now reading a char    //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)	
//						if(rudderAngle >= 0 && rudderAngle <= 360)	//check for valid rudder angle input
//						{
//							hasRudderAngle = true;
//							//setRudder(float(rudderAngle)); 
//                                                        StraightSailDirection = rudderAngle;
//							Serial.print("Compass bearing set to: ");
//							temp = float(rudderAngle);
//							Serial.println(temp);
//						}
//						else
//						{
//							Serial.println("Invalid Angle");
//						}

                                                switch(sailDirection)
                                              {  //the input char sailDirection
                                                case 'n':
                                                  StraightSailDirection = 0;
                                                  hasSailDirection = true;
                                                break;
                                                case 's':
                                                  StraightSailDirection = 180;
                                                  hasSailDirection = true;
                                                break;
                                                case 'e':
                                                  StraightSailDirection = 90;
                                                  hasSailDirection = true;
                                                break;
                                                case 'w':
                                                  StraightSailDirection = 270;
                                                  hasSailDirection = true;
                                                break;
                                                default:
                                                  Serial.println("Invalid entry, please enter n,s,e or w");
                                                break;
                                              }
                                                
					}
      
				}
                                return 3;	
				//hasSailDirection = false; // Val: why set this local variable back to false? Can probably delete this.
				break;
				
				//call sailside function
				case 'd':
					Serial.println("Selected Sail To Waypoint. Please choose a waypoint.");	
                                        
                                        hasPoint = false;
                                        while(hasPoint == false){
                                          while(Serial.available() == false);
                                          point = Serial.read() - '0'; 
                                          hasPoint = true;                                         
                                        }                                    
                                        return 4;
  					break;
					
					//call tack function
				case 'e':
                                        Serial.println("Please point boat against the wind.");
					Serial.println("Enter any value to begin");
					while(hasTackVal == false)
					{
						if(Serial.available() > 0)
						{ 
							//this will have to be changed to use Serial.readln function							
							hasTackVal = true;							
						}	
					}
					tack();
                                        Serial.println("Tack Complete");
                                        return 0;
					break;
					
					//call wind function	
					case 'f':
						Serial.println("Selected Wind");
						windData = sensorData(BUFF_MAX,'w');

                                                if(windData == false){
                                                  Serial.println("Wind Sensor Data: ");
                                                  Serial.print("  Wind Angle:  ");
                                                  Serial.println(wind_angl);
                                                  Serial.print("  Wind Velocity (knots):   ");
                                                  Serial.println(wind_velocity);  
                                                  Serial.println("TEMPORARY wind sensor heading");
                                                  Serial.println(heading);                                               
                                                }
						break;
						//exits the menu
					case 'g':
						Serial.println("Selected Compass");
						compassData = sensorData(BUFF_MAX,'c');
        						
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
                                                
                                            //    return 0;
						break;

                                        case 'h':
						Serial.println("Selected Speed");        						                         
                                                  Serial.println("Speed Data: ");
                                                  Serial.print("  Boat's speed (km/h):  ");
                                                  Serial.println(bspeed);
                                                  Serial.print("  Boat's speed(knots):   ");
                                                  Serial.println(bspeedk);
                                                return 0;
						break;
					
                                        case 'i':
                                            Serial.println("Selected Toggle RC");
                                            Serial.println("Enter desired RUDDER control value (1 for RC, 0 for autonomous)");
                                            hasRudderRCvalue = false; 
                                            while (!hasRudderRCvalue) {
                                              if(Serial.available())
                                              {
                                                rudderRCvalue = Serial.read() - '0';
                                                if(rudderRCvalue == 0 || rudderRCvalue == 1)
                                                {
                                                 hasRudderRCvalue = true;
                                                }
                                                else
                                                {
                                                  Serial.print("read value: ");
                                                  Serial.println(rudderRCvalue, DEC);
                                                  Serial.println("Invalid value, please enter 0 or 1");
                                                  
                                                }
                                              }
                                              
                                            }//end rudder rc value
                                            Serial.println("Enter desired SAILS control value (1 for RC, 0 for autonomous)");
                                            hasSailsRCvalue = false;
                                            while (!hasSailsRCvalue) {
                                               if(Serial.available())
                                              {
                                                sailsRCvalue = Serial.read() - '0';
                                                if(sailsRCvalue == 0 || sailsRCvalue == 1)
                                                {
                                                  hasSailsRCvalue = true;
                                                  
                                                }
                                                else
                                                {
                                                  Serial.println("Invalid value, please enter 0 or 1");
                                                }
                                              }
                                              
                                            }// end sails rc value
                                            
                                            RC(rudderRCvalue, sailsRCvalue);      
           
                                        break;
					case 'j':
						Serial.println("Exiting Menu");
                                                return 0;
					//	stayInMenu = false;
						//does nothing
                                        case 'k':
                                                Serial.println("StationKeeping");   //stationkeeping menu item, currently untested
                                                Serial.println("Using the first 4 coordinates as corners"); //cannot access menu when stationkeeping                                          
                                                for(i = 0; i < 4; i++){                                                  
                                                stationPoints[i] = waypoints[i];
                                                stationPoints[i] = waypoints[i];
                                                }
                                                stationCounter = 2;
                                                startTime = millis();//record the starting clock time
                                                return 1;
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
                                                break;   
                                        case 'm':
                                                Serial.println("Clear all waypoints? (y/n)");
                                                while(hasVal == false){
                                                if(Serial.available() > 0){
                                                select = Serial.read();
                                                if(select == 'y'){
                                                for(i = 0; i < 10; i++){
                                                   waypoints[i] = clearPoints;
                                                   hasVal = true;
                                                   Serial.println("Cleared");
                                                    }
                                                  }else if(select == 'n'){
                                                  Serial.println("no changes made");
                                                  hasVal = true;
                                                  break;
                                                  }  
                                                else{ 
                                                  Serial.println("invalid input");
                                                   }
                                                  }
                                                }
                                                return 0;
                                                break;
                                        case 'n':
                                                Serial.println("Toggle rudder direction");
                                                rudderDir = rudderDir*-1;
                                                return 0;
                                                break;
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
                                                delay(7000);
                                                Serial.println("Setting Jib all in");
                                                setJib(ALL_IN);
                                                delay(7000);                                           
                                                Serial.println("Setting main all out");
                                                setMain(ALL_OUT);       
                                                delay(5000);                                        
                                                Serial.println("Setting main all in");
                                                setMain(ALL_IN);
                                                delay(5000);                                               
                                                Serial.println("testing compass");
                                                   compassData = sensorData(BUFF_MAX,'c');        						
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
						windData = sensorData(BUFF_MAX,'w');
                                                if(windData == false){
                                                  Serial.println("Wind Sensor Data: ");
                                                  Serial.print("  Wind Angle:  ");
                                                  Serial.println(wind_angl);
                                                  Serial.print("  Wind Velocity (knots):   ");
                                                  Serial.println(wind_velocity);                                                  
                                                }
                                                Serial.println("testing complete");
                                                break;
                                        case 'p':  //returns your current position
                                                Serial3.flush();
                                                delay(1100);
                                                windData = sensorData(BUFF_MAX,'w');
                                                delay(100);
                                                Serial.print(boatLocation.latDeg,0);
                                                Serial.print(boatLocation.latMin,4);
                                                Serial.print(" ");
                                                Serial.print(boatLocation.lonDeg,0);
                                                Serial.println(boatLocation.lonMin,4);
                                                Serial.println("");
                                                hasVal = false;
                                                Serial.println("Would you like to save point? (y/n)");
                                                while(hasVal == false){
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
                                                       hasVal = true;
                                                   }
                                                }
                                                else if(select == 'n'){
                                                  Serial.println("no changes made");
                                                  hasVal = true;
                                                  break;
                                                  }  
                                                else{ 
                                                  Serial.println("invalid input");
                                                     }
                                                  }
                                                }                                                
                                                break;
                                                
                                        case 'r':  //Direct rudder and sail control
                                        
                                                Serial.println("RC mode, receives inputs from other arduino and hacked old transmitter");
                                                Serial.println(" 'q' exits back to menu, you might need to press it up to 3 times.");
                                                Serial.println("~");
                                                hasQ = false;
                                                sailsVal = 0;
                                                rudderVal = 0;
                                                char temprudder;
                                                char tempsails;
                                                while (hasQ == false){
                                                  while(Serial.available() == false);
                                                  rcVal = Serial.read();
                                                      switch(rcVal)
                                                      {  
                                                        case '1'://rudder values are from 120 to 180, ignore the 1 then subtract 50 to get actual -30 to 30 value
                                                          while(!Serial.available());
                                                          rudderVal = Serial.read() - '0';
                                                          while(!Serial.available());
                                                          rudderVal = rudderVal*10 + Serial.read() - '0';
                                                          rudderVal -= 50;
                                                       //   Serial.print("rudder set to : ");
                                                       //   Serial.println(rudderVal);
                                                          setrudder(rudderVal);
                                                        break; 
                                                        case '2'://sails values are from 220 to 280, ignore the 2 then subtract 50 to get actual -30 to 30 value
                                                          while(!Serial.available());
                                                           sailsVal = Serial.read() - '0';
                                                          while(!Serial.available());
                                                          sailsVal = sailsVal*10 + Serial.read() - '0';
                                                          sailsVal -= 25;
                                                          sailsVal *= 2; 
                                                        //  Serial.print("Sails set to : ");
                                                       //   Serial.println(sailsVal);
                                                          setSails(sailsVal);
                                                          
                                                        break;
                                                       
                                                        case 'q':
                                                          hasQ = true;
                                                          Serial.println("exiting RC mode");
                                                          delay(2000);
                                                          Serial.println("||||||||||||||||||||||||||||||||||||||||||||||");
                                                          Serial.println("||||||||||||||||||||||||||||||||||||||||||||||");
                                                        break;
                                                      }
                                                      
                                                      
                                                } 
                                                break;
                                        
                                      
                                        
                                        case 's':
                                        int rudcount;
                                                Serial.println("RC mode, use a/d for rudder control, w/s for sails");
                                                Serial.println(" 'y' exist back to menu");
                                                hasQ = false;
                                                sailsVal = 0;
                                                rudderVal = 0;
                                                while (hasQ == false){
                                                  while(Serial.available() == false);
                                                  rcVal = Serial.read();
                                                      switch(rcVal)
                                                      {  //the input char sailDirection
                                                        
                                                        case 'a':
                                                          rudcount =0;
                                                          if(rudderVal < 30){
                                                          rudderVal += 2;
                                                          }
                                                          else{
                                                            rudderVal = 30;
                                                          }
                                                   
                                                          Serial.print("rudder Set to : ");
                                                          Serial.println(rudderVal);
                                                        break;
                                                        case 'd':
                                                          rudcount = 0;
                                                          if(rudderVal > -30){
                                                            rudderVal -= 2;
                                                          }
                                                          else{
                                                            rudderVal = -30;
                                                          }
                                                       
                                                          Serial.print("rudder Set to : ");
                                                          Serial.println(rudderVal);
                                                        break;
                                                        case 's':
                                                            rudderVal = 0;\
                                                            break;
                                                        case 'w':                                           
                                                            if(sailsVal < 100){
                                                             sailsVal += 5;
                                                            }
                                                            else{
                                                              sailsVal = 100;
                                                            }
                                                          Serial.print("Sails Set to : ");
                                                          Serial.println(sailsVal);
                                                        break;
                                                        case 'e':
                                                          if(sailsVal > 0){
                                                             sailsVal -= 5;
                                                            }
                                                            else{
                                                              sailsVal = 0;
                                                            }
                                                            Serial.print("Sails Set to : ");
                                                          Serial.println(sailsVal);
                                                        break;
                                                         case 'q':                                           
                                                            if(sailsVal < 100){
                                                             sailsVal += 20;
                                                            }
                                                            else{
                                                              sailsVal = 100;
                                                            }
                                                            Serial.print("Sails Set to : ");
                                                          Serial.println(sailsVal);
                                                         break;
                                                         case 'r':
                                                         if(sailsVal > 0){
                                                             sailsVal -= 20;
                                                            }
                                                            else{
                                                              sailsVal = 0;
                                                            }
                                                          Serial.print("Sails Set to : ");
                                                          Serial.println(sailsVal);
                                                        break;
                                                        case 'y':
                                                          hasQ = true;
                                                          Serial.println("exiting RC mode");
                                                        break;
                                                      }
                                                      rudcount++;            //loop for resetting rudder to 0
                                                      if(rudcount > 10){
                                                       rudderVal = 0; 
                                                      }
                                                      setrudder(rudderVal);
                                                      setSails(sailsVal);
                                                } 
                                                break;
                                        case 'z': //If you press z it clears the serial buffer
                                                Serial.flush();
                                                Serial.println("Serial Buffer Cleared");
                                                break;
                                        
					default:
						break;
			}	
			
	}
}	
