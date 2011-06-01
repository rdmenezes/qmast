  //all testing code from last sailcode here
  //not guarenteed to work, has not been changed for new sailcode
  
  
  //April 2 sailcode:
//  sailCourse();
//  
//  while(1){
//    Serial.println("Program over.");
//    delay(1000);
//  } //end program


/*
//Testing code below here
*/
   
////compass sample mode testing code, parsed
//      error = sensorData(BUFF_MAX, 'c'); //updates heading_newest
//      Serial.println(heading_newest);
//      delay(5000);


//compass sample mode testing code, unparsed        
//  while (Serial2.available()>0)
//   {
//     input = Serial2.read();
//     Serial.print(input);
//   }
//   Serial2.println("$PTNT,HTM*63");
//   delay(1000);
  

//////compass run mode testing code, unparsed
////  while (Serial2.available()>0)
////   {
////     input = Serial2.read();
////     Serial.print(input);
////   }
////  delay(20);
//     
//////wind run mode testing code, unparsed (note* this doesnt need the arduino to be switched to xbee and the onboard power, works with arduino USB powered)
//  while (Serial3.available()>0)
//   {
//     input = Serial3.read();
//     Serial.print(input);
//   }        
//   delay(250);
     
  
//wind sensor attempted sample mode testing code, parsed; this is working for the wing angle and speed (tested by blowing on it)
//      error = sensorData(BUFF_MAX, 'w'); //updates heading_newest
//      Serial.println("Wind angle is: ");
//      Serial.println(wind_angl_newest);
//      Serial3.println("$PAMTC,EN,ALL,0*1D"); //disable all commands; this doesnt seem to have worked
//      Serial3.println("$PAMTX*50");//temporarily disable commands until power cycles; not working
//      delay(1000);  


////wind based sail control testing code
//  RC(0,0);// autonomous sail control
//  
//  for(i = 0; i < 10; i++)
//  {
//      Serial.println("Wind angle is: ");
//      Serial.println(wind_angl_newest);
//      error = setSails();
//      delay(100);  
//  }

  
//MUX with motor testing  ; with present hardware setup, this makes rudder turn from Pololu and then jitter (no RC controller turned on)
// the sails just trill and occasionally seems to mirror rudder with rudder plugged in; with rudder unplugged they jitter and low-pitched jittery-beep
// this is likely due to the fact that the sail pin (11) seems to be broken (or that MUX channel is broken on the other side), it ranges .8to3.2V)
// full back, middle, front with this code -> front=sails in = negative, back=sails out = positive;
// if motor range is small, battery is probably dead (7.2V non-regulated)
// this MUX switching code is working - > mux working now to switch RC to autonomous; RC mode very noisy, perhaps need to replace antenna/transmitter
//
// RC(0,0);//total autonomous
// digitalWrite(noDataLED,LOW);
// Serial.println("0 degrees");
// setrudder(-15);
// setSails(-15);
//  Serial.println("-15 degrees");
// delay(1000);
//  Serial.println("-15 degrees");
// setSails(15);
// setrudder(15);
//  Serial.println("15 degrees");
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
//  Serial.println("-45 degrees");
//  setrudder(-45);
// setSails(-45);
//  Serial.println("-45 degrees");
// delay(1000);
//  Serial.println("45 degrees");
// setSails(45);
// setrudder(45);
// Serial.println("45 degrees");
// delay(1000);
//  Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
// Serial.println("0 degrees");
//  
// RC(1,1);//RC steering 
// digitalWrite(noDataLED,HIGH);
//  Serial.println("0 degrees");
// setrudder(-15);
// setSails(-15);
//  Serial.println("-15 degrees");
// delay(1000);
//  Serial.println("-15 degrees");
// setSails(15);
// setrudder(15);
//  Serial.println("15 degrees");
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
// delay(1000);
// Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
//  Serial.println("-45 degrees");
//  setrudder(-45);
// setSails(-45);
//  Serial.println("-45 degrees");
// delay(1000);
//  Serial.println("45 degrees");
// setSails(45);
// setrudder(45);
// Serial.println("45 degrees");
// delay(1000);
//  Serial.println("0 degrees");
// setrudder(0);
// setSails(0);
//  Serial.println("0 degrees");
// delay(1000);
// Serial.println("0 degrees");
//  
  
// simple compass, rudder control testing code
//    if (heading_newest < 180)//the roller-skate-boat turns opposite to it's angle
//        setrudder(-180);  //adjust rudder proportional; setrudder accepts -45 to +45
//    else
//        setrudder(180); //adjust rudder proportional; setrudder accepts -45 to +45     
//
//    delay(100);


//  Serial2.print("$PAMTC,");
     //this doesnt seem to be reacting to the serial data as expected - I believe the problem is largely due to how we're parsing and the lack of error checking
     //problem seemed to be the compass data; compass seems to be broken, see the chart taped to the whiteboard
  //Serial.print("\nNew heading");   
 // setrudder(heading_newest);
  //relayData();
 // delay(5000);
  //seems more responsive with 50 delay than 10 (perhaps servo doesnt have tim eto move, or serial data is being garbled with 10?)

//note: output is even MORE garbled over zigbee; interference? or buffers full?


//the below worked for about 10 iterations and then pololu started blinking red light - error?
//we need to monitor pololu's feedback to detect these error codes
//resetting the arduino fixed the problem

//Polulu Test Code
//Serial.print("\n 320 degrees");   
//setrudder(320);
//setSails(15);
////  arduinoServo(30);
//delay(2000); 
//  Serial.print("\n10 degrees");   
//setrudder(10);
//setSails(-15);
//
//delay(2000);



//error-checking navigation code:  

//  //set present latitude and longitude to the middle tree
//  error = Parser("$GPGLL,4413.6939,N,07629.5335,W,230544,A,A*5C"); 
//    
//  //set the waypoint to the corner of the dirt pit
//  //latitude
//  waypointLatDeg = 44;
//  waypointLatMin = 13.7067;
//  //longitude
//  waypointLongDeg = -76;
//  waypointLongMin = -29.4847;
//  
//  //set wind direction
//  error = Parser("$WIMWV,40.0,R,0.5,N,A*26");
//   
//  //leave compass direction at it's 0 default
//  heading_newest=0;//heading relative to true north, newest
//  
//  //find the distance to the waypoint
//  distanceToWaypoint = GPSdistance(latitudeDeg, latitudeMin, longitudeDeg, longitudeMin, waypointLatDeg, waypointLatMin, waypointLongDeg, waypointLongMin);
//  Serial.print("Waypoint distance: ");
//  Serial.println(distanceToWaypoint);
//  
//  //find the direction to the waypoint
//  waypointDirn = getWaypointDirn(); //get the next waypoint's compass bearing; must be positive 0-360 heading
//  Serial.print("Waypoint dirn: ");
//  Serial.println(waypointDirn);
//  
//  //find the wind direction
//  windDirn = getWindDirn();
//  Serial.print("Wind dirn: ");
//  Serial.println(windDirn);
//  
//  //closehauled dirn
//  closeHauledDirection = getCloseHauledDirn();
//  Serial.print("Closehauled dirn: ");
//  Serial.println(closeHauledDirection);
//  
//  //check if we're downwind
//  if(between(waypointDirn, windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) //check if the waypoint's direction is between the wind and closehauled on either side
//    Serial.println("Downwind");
//  else  
//    Serial.println("not downwind");
//  
//  //check downwind corridor  
//  distanceOutsideCorridor = stayInDownwindCorridor(10);
//  Serial.print("Corridor distance: ");
//  Serial.println(distanceOutsideCorridor);    
//  int windData;
//       if(windData == false){
//                                                  Serial.println("Wind Sensor Data: ");
//                                                  Serial.print("  Wind Angle:  ");
//                                                  Serial.println(wind_angl);
//                                                  Serial.print("  Wind Velocity (knots):   ");
//                                                  Serial.println(wind_velocity);  
//                                                  Serial.println("TEMPORARY wind sensor heading");
//                                                  Serial.println(heading);                                               
//                                                }
//  Serial.println("Selected Wind");
//	windData = sensorData(BUFF_MAX,'w');
//        error = getCloseHauledDirn();
//        Serial.println("Testing closehaul");
//        Serial.println(error);
//        delay(1000);
//    
