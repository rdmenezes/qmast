void displayMenu()
{
	boolean stayInMenu = true; 					
	boolean hasSelection = false;
	boolean hasRudderAngle = false;
	byte selection;
	boolean someVal = false;
	boolean hasTackVal = false;
        boolean compassData = false;
        boolean windData = false;
        boolean speedData = false;
	boolean hasX = false;
        boolean hasY = false;
        boolean badGPS = false;
        double gpsDigit = 0;
        int power = 3;
        
        
	byte rudderAngle;
	byte tackVal;
	
	float temp;
	
	//GAELFORCE!
		
	
	Serial.println("");
	
	//this loops through the menu until the user has selected the "exit menu" function 
	while(stayInMenu == true)
	{
		//menu options
		Serial.println("");
		Serial.println("___________________  MENU  ______________________");
		Serial.println("");
		Serial.println("");
		Serial.println("1.	Input Waypoints");
		Serial.println("2.	Begin automated sailing");
		Serial.println("3.	Set rudder angle");
		Serial.println("4.	Sailside");
		Serial.println("5.	Tack");
		Serial.println("6.	Get Wind Sensor Data");
		Serial.println("7.      Get Compass Data");
                Serial.println("8.      Get Speed Data");
		Serial.println("9.	Exit Menu");
		Serial.println("");
		Serial.println("Select option:");
		
		//clears values from previous menu selection
		hasSelection = false;
		Serial.flush();
		
		//waits for user input to come from serial port
		while(hasSelection == false)
		{
			if(Serial.available() > 0)
			{ 
				selection = Serial.read() - '0';     //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)			
				hasSelection = true;
			}	
		}
		
		
		//calls appropriate function, and returns to the menu after function execution
		//Serial.println(selection,BYTE);    this prints the input, but the serial input is stored as its ASCII value, (ie 1 = 49, 2 = 50, etc)
		switch(selection)
		{
			//call input waypoints function
                        //assuming that waypoints are of the form XXXX.XXXX....X
			case 1:
				Serial.println("Selected 1");

                                prevGPSX = GPSX; //Storing current GPS values and then reseting them too zero
                                prevGPSY = GPSY;
                                GPSY = 0;
                                GPSX = 0;
                                hasX = false;
                                hasY = false;	
                                power = 3;
                                
                                /*
                                BASIC LOGIC TO PARSE COORDONITES
                                
                                The Serial input can only take 1 character at a time, so you have to read each character from the input co-ordoninte (eg. 1234.5678) 
                                and then rebuild the co-ordonite inside the arduino.  The way this program does it is to keep a running "power" variable.  Each time 
                                a new character is read, it is mulitplied by 10^power, then added to the final value.  Power is then deceremented by one and the
                                process is repeated until there are no more characters to be read.
                                */
                              
                                Serial.println("Enter GPS X Co-ordonite:  ");
                                while(!hasX){
                                  if(Serial.available() > 0){
                                    //Code to get serial data from the buffer and put it into GPSX
                          
                                    while(gpsDigit != (46-'0')){
                                      gpsDigit = Serial.read() - '0';
                                      
                                      /*if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      }   
                                       */  
                                      GPSX = GPSX + (gpsDigit*pow(10,power));
                                      
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                           
                                    }
                                   // if(badGPS = true)
                                   //   break;
                                    gpsDigit = Serial.read(); //Just reading the '.' to get rid of it and get too the stuff after the decimal
                                    //power--;
                                    while(Serial.available() > 0){
                                      gpsDigit = Serial.read() - '0';
                                      GPSX = GPSX + (gpsDigit * pow(10,power));
                                      
                                     /* if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      } 
                                      */
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--; 

                                    }
                                    
                                    hasX = true;
                                    Serial.println(GPSX);
                                  }
                                  
                                  
                                }
                                
                                power = 3;
                                
                                Serial.println("Enter GPS Y Co-ordonite:  ");
                                while(!hasY){
                                  if(Serial.available() > 0){
                                    //Code to get serial data from the buffer and put it into GPSX
                          
                                    while(gpsDigit != (46-'0')){
                                      gpsDigit = Serial.read() - '0';
                                      
                                      /*if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      }   
                                       */  
                                      GPSY = GPSY + (gpsDigit*pow(10,power));
                                      
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--;                           
                                    }
                                   // if(badGPS = true)
                                   //   break;
                                    gpsDigit = Serial.read(); //Just reading the '.' to get rid of it and get too the stuff after the decimal
                                    //power--;
                                    while(Serial.available() > 0){
                                      gpsDigit = Serial.read() - '0';
                                      GPSY = GPSY + (gpsDigit * pow(10,power));
                                      
                                     /* if(gpsDigit < 0 || gpsDigit > 9){ //checking for invalid gps data
                                         badGPS = true;
                                         Serial.flush();
                                         break; 
                                      } 
                                      */
                                      Serial.println(power);
                                      Serial.println(gpsDigit*pow(10,power));
                                      power--; 

                                    }
                                    
                                    hasY = true;
                                    Serial.println(GPSY);
                                  }
                                  
                                  
                                }
                                
                                
                                
                                Serial.print("Entered waypoints:  X = ");
                                Serial.print(GPSX);
                                Serial.print(" ,Y = ");
                                Serial.println(GPSY);
				break;
				
				//start automated sailing	
			case 2:
				Serial.println("Selected 2");
				//Sail();      calls functions to begin automated sailing
				break;
				
				//call rudder angle set function
			case 3:
				Serial.println("Enter Rudder angle, from 0 to 360: ");
				while(hasRudderAngle == false)
				{
					if(Serial.available() > 0)
					{ 
						//this will have to be changed to use Serial.readln function
						rudderAngle = Serial.read() - '0';     //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)	
						if(rudderAngle >= 0 && rudderAngle <= 360)	//check for valid rudder angle input
						{
							hasRudderAngle = true;
							//setRudder(float(rudderAngle)); 
							Serial.print("Rudder Angle set to: ");
							temp = float(rudderAngle);
							Serial.println(temp);
						}
						else
						{
							Serial.println("Invalid Angle");
						}
					}	
				}
				hasRudderAngle = false;
				break;
				
				//call sailside function
				case 4:
					Serial.println("Selected SailSide");	
					//Sailside();       
					break;
					
					//call tack function
				case 5:
					Serial.println("Enter Tack direction: ");
					while(hasTackVal == false)
					{
						if(Serial.available() > 0)
						{ 
							//this will have to be changed to use Serial.readln function
							tackVal = Serial.read() - '0';     //the " - '0' " converts the ASCII char to its actaul integer value (ex: without this, if the user entered '1' it would store as 49)	
							if(tackVal >= 0 && tackVal <= 9)	//check for valid tackVal input
							{
								hasTackVal = true; 
								Serial.print("Tack chosen is: ");
								Serial.println(tackVal);
							}
							else
							{
								Serial.println("Invalid Tack Direction");
							}
						}	
					}
					
					break;
					
					//call wind function	
					case 6:
						Serial.println("Selected Wind");
						windData = Wind();

                                                if(windData = false){
                                                  Serial.println("Wind Sensor Data: ");
                                                  Serial.print("  Wind Angle:  ");
                                                  Serial.println(wind_angl);
                                                  Serial.print("  Wind Velocity (knots):   ");
                                                  Serial.println(wind_velocity);
                                                  
                                                }

						break;
						//exits the menu
					case 7:
						Serial.println("Selected Compass");
						compassData = Compass();
        						
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
                                                

						break;

                                        case 8:
						Serial.println("Selected Speed");
        						                         
                                                  Serial.println("Speed Data: ");
                                                  Serial.print("  Boat's speed (km/h):  ");
                                                  Serial.println(bspeed);
                                                  Serial.print("  Boat's speed(knots):   ");
                                                  Serial.println(bspeedk);
                                                
						break;
						
					case 9:
						Serial.println("Exiting Menu");
						stayInMenu = false;
						//does nothing

                                        case 32: //If you press z it clears the serial buffer
                                                Serial.flush();
                                                Serial.println("Serial Buffer Cleared");
                                                break;
                                        
					default:
						break;
			}	
			
			
			
	}
}	
