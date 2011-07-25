void tack(){    

  static int newData = 0;
  int dirn;
  boolean inIrons = false;

  if(tacking == false){
    if(wind_angl > 180){
      tackingSide = 1; 
    }
    else
      tackingSide = -1;
  } 
  tacking = true;
  ironTime++;                  //checks to see if turned far enough
  if(ironTime > 100){           //waits about 10 seconds to before assuming in irons        
    getOutofIrons(tackingSide);    
    inIrons = true;      
  }
  if(((wind_angl > 180) && (wind_angl < 360-TACKING_ANGLE))||((wind_angl < 180) && (wind_angl > TACKING_ANGLE))) {         //check to see if still trying to tack
    tacking = false;        //resets variables 
    newData = sensorData(BUFF_MAX, 'w');  
    dirn = getCloseHauledDirn();
    ironTime = 0;
    inIrons = false;
    sail(dirn);    //straighten out, sail closehauled
    delay(200);
  }  
  else if(tacking == true && inIrons == false){      //tacks depending on the side the wind is aproaching from
    if(tackingSide == 1){        //nested if statements
      if(wind_angl < 180){
        setJib(ALL_IN);
        setMain(ALL_OUT);
        setrudder(-20);
      }
      else{
        setMain(ALL_IN);
        setJib(ALL_OUT);                    //sets main and jib to allows better turning
        setrudder(-20);
      }      //rudder angle cannot be to steep, this would stall the boat, rather than turn it
      delay(100);
      newData = sensorData(BUFF_MAX, 'w');     
      delay(100);                
    } 

    //mirror for other side
    if(tackingSide == -1){
      if(wind_angl > 180){
        setJib(ALL_IN);
        setMain(ALL_OUT);
        setrudder(20);
      }
      else{
        setMain(ALL_IN);
        setJib(ALL_OUT);                    //sets main and jib to allows better turning
        setrudder(20);
      }      //rudder angle cannot be to steep, this would stall the boat, rather than turn it
      delay(100);
      newData = sensorData(BUFF_MAX, 'w');      
      delay(100);                
    }
  }
}

//code to get out of irons if boat is stuck
void getOutofIrons(int tackside){
  int dirn;
  setMain(ALL_OUT);
  setJib(ALL_IN);
  setrudder(30*tackside);        //arbitrary might want to base on direction of travel
  dirn = sensorData(BUFF_MAX, 'w');
  delay(100);
}


