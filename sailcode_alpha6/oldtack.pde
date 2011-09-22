//early tacking code, simpler than the unimplemented version for testing 
//Jib has to be let out at the beginning of turning, this exert a moment on the boat allowing for faster turning, 
//after truned halfway, pull jib in and let main out, again faster turning, speed should not be an issue, not much required in order to turn
//should still check if in iron, if so let main out, turn rudder to one side, when angle is no longer closehauled
//try sailing again, 
void oldtack(){    
    
  boolean tackComplete = false;      
  float startingWind_angl = wind_angl;
  int newData = 0;
  int dirn = 0;
  int ironTime =0;
  while(tackComplete == false){      //tacks depending on the side the wind is aproaching from
  if(Serial.available())
  return;
    if(wind_angl < 180){
      Serial.println("trying to tack towards starboard, adjusting sails");
      setMain(ALL_IN);
      setJib(ALL_OUT);                    //sets main and jib to allows better turning
      setrudder(-30);                //rudder angle cannot be to steep, this would stall the boat, rather than turn it
      while(wind_angl < 180){
        if(Serial.available())
        return;
        delay(100);
        sensorData(BUFF_MAX, 'w');  
        ironTime++;                  //checks to see if turned far enough
        if(ironTime == 100){           //waits about 10 seconds to before assuming in irons
        Serial.println("It has been 10 seconds and I haven't crossed over, so I am trying to get out of irons)");
        
        getOutofIrons(1);
        ironTime = 0;
          }
        }
        setJib(ALL_IN);
        setMain(ALL_OUT);
      delay(1000);                        //delay to complete turning \
      newData = sensorData(BUFF_MAX, 'w');
      dirn = getCloseHauledDirn();
     sail(dirn);                //straighten out, sail closehauled
     Serial.println("I am now trying to sail closehauled");
     //setSails(ALL_IN);
      if(wind_angl >180){            //exits when turned far enough
        tackComplete = 1;
        }  
      }
      else if(wind_angl > 180){        //mirror for other side
      Serial.println("trying to tack towards port");
      setMain(ALL_IN);
      setJib(ALL_OUT);
      setrudder(30);
      while(wind_angl > 180){
        if(Serial.available())
        return;
        delay(100);
        sensorData(BUFF_MAX, 'w');
        if(ironTime == 100){            //waits about 10 seconds to before assuming in irons
        Serial.println("It has been 10 seconds and I haven't crossed over, so I am trying to get out of irons)");
        
          getOutofIrons(-1);
          ironTime = 0;
          }
        }
        setJib(ALL_IN);
        setMain(ALL_OUT);
      delay(1000);
      dirn = getCloseHauledDirn();
      sail(dirn);
      Serial.println("I am now trying to sail closehauled");
      //setSails(ALL_IN);
      sensorData(BUFF_MAX, 'w');
      if(wind_angl < 180){
        tackComplete = 1;
        }  
      }
    }
    
  
  }     
  
  
  ///newer revision
  
  
  void oldtack2(){    
      
  boolean tackComplete = false;      
  float startingWind_angl = wind_angl;
  int newData = 0;
  int dirn = 0;
  int ironTime =0;
  int turnTo;
  while(tackComplete == false){      //tacks depending on the side the wind is aproaching from
  if(Serial.available())
  return;
    if(wind_angl < 180){
      Serial.println("trying to tack towards starboard, adjusting sails");
      setMain(ALL_IN);
      setJib(ALL_OUT);                    //sets main and jib to allows better turning
      setrudder(-30);                //rudder angle cannot be to steep, this would stall the boat, rather than turn it
      while(wind_angl < 180){
        setMain(ALL_IN);
      setJib(ALL_OUT);                    //sets main and jib to allows better turning
      setrudder(-30); 
       Serial.println("main in, jib out, rudder -30");
        
        if(Serial.available())
        return;
        delay(100);
        sensorData(BUFF_MAX, 'w');  
        ironTime++;                  //checks to see if turned far enough
        if(ironTime == 100){           //waits about 10 seconds to before assuming in irons
        Serial.println("It has been 10 seconds and I haven't crossed over, so I am trying to get out of irons)");
        
        getOutofIrons(1);
        ironTime = 0;
          }
        }
        Serial.println("main out, jib in");
        setJib(ALL_IN);
        setMain(ALL_OUT);
      delay(1000);                        //delay to complete turning \
      newData = sensorData(BUFF_MAX, 'w');
      Serial.println("sail closehauled");
      dirn = getCloseHauledDirn();
      delay(100);
     sail(dirn);                //straighten out, sail closehauled
     //setSails(ALL_IN);
      if(wind_angl >180){            //exits when turned far enough
        tackComplete = 1;
        Serial.println("tack incomplete");
        }  
      }
      else if(wind_angl > 180){        //mirror for other side
      Serial.println("trying to tack towards port");
      
      while(wind_angl > 180){
        Serial.println("main in, jib out, rudder +30");
        setMain(ALL_IN);
      setJib(ALL_OUT);
      setrudder(30);
      
        if(Serial.available())
        return;
        delay(100);
        sensorData(BUFF_MAX, 'w');
        if(ironTime == 100){            //waits about 10 seconds to before assuming in irons
        Serial.println("It has been 10 seconds and I haven't crossed over, so I am trying to get out of irons)");
        
          getOutofIrons(-1);
          ironTime = 0;
          }
        }
        Serial.println("main out, jib in");
        setJib(ALL_IN);
        setMain(ALL_OUT);
      delay(1000);
      Serial.println("trying to sail closehauled");
      dirn = getCloseHauledDirn();
      sail(dirn);
      delay(1000);
      //setSails(ALL_IN);
      sensorData(BUFF_MAX, 'w');
      if(wind_angl < 180){
        tackComplete = 1;
        Serial.println("tack complete");
        }  
      }
    }
  
  }        //boat should continue closed hauled until it hits the other side of the corridor

//code to get out of irons if boat is stuck
void getOutofIronsOld(int tackside){
  Serial.println("trying to get out of irons. Main out, jib in, rudder cranked");
  int dirn;
  setMain(ALL_OUT);
  setJib(ALL_IN);
  setrudder(30*tackside);        //arbitrary might want to base on direction of travel
  while(wind_angl < TACKING_ANGLE || wind_angl > 360 -TACKING_ANGLE){
    if(Serial.available())
    return;
  sensorData(BUFF_MAX, 'w');
  delay(100);
  Serial.println("hanging out until I am out of irons");
  }
  Serial.println("I think I am out of irons, pulling sails all in");
  //setSails(ALL_IN);
  //setrudder(0);
  sail(getCloseHauledDirn());
  delay(1000); //some time to build up speed
}

