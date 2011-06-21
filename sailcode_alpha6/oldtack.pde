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
        newData = sensorData(BUFF_MAX, 'w');  
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
        newData = sensorData(BUFF_MAX, 'w');
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
      newData = sensorData(BUFF_MAX, 'w');
      if(wind_angl < 180){
        tackComplete = 1;
        }  
      }
    }
    
  
  }     
