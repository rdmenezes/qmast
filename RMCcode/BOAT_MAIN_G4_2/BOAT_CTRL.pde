

void control(void)
{  
  if(heading>=0)
    setPoint=comp2pol(heading);  //SetPoint is in Polar!
  else
    setPoint=vbtheta; 
    
  if ((GPSLOCK==1) || (WINDTEST !=0))  // Run the servos if we have a GPS lock or we are testing wind response
  {
    rudder_ctrl();
    tail_ctrl();
    camber_ctrl();
//----------WORM-----------
    worm_ctrl();
//---------ENDWORM---------

  }
  else  // All controls go neutral if no GPS lock
  {
    rudder_out=0;
    camber_out=91;
    tail_out=100;
    worm_out=91;
  }
  servo_out();
}

void rudder_ctrl(void)
{

  //Should we be holding a heading or autowaypoint mode. 
  
  err = vbthetaTP - setPoint; // if'+' we are sailing right of course, turn left]
//  Serial.print("vbthetaTP:");Serial.println(vbthetaTP,2);
//  Serial.print("setPoint:");Serial.println(setPoint,2);
//  Serial.print("err:");Serial.println(err,2);

    if (err >= 180)
    err = err - 360;
  else if (err < -180)
    err = err + 360;
    
    
    rudder_out = err*rP;
    
    if(err >20)
    rudder_out = rmax;
    if(err <-20)
    rudder_out = -rmax;

  // ON OFF Rudder Control with +- 2deg deadband Max Deflection at 15deg err of ~26servo deg
//  if ((err > rdead) && (err < rmaxerr))
//  rudder_out = rP*err + rinter + 91;
//  else if(err >= rmaxerr)
//  rudder_out = rmax +91;  //Turn Right
//  else if ((err <-rdead) && (err >-rmaxerr))
//  rudder_out = rP*err - rinter + 91;
//  else if (err <= -rmaxerr)
//  rudder_out = rmax-91;   //Turn Left
//  else if ((err >=-rdead) & (err <=rdead))
//  rudder_out = 91;
//  else
//  rudder_out = 91;   //Sail Straight  
  //rudderPID.Compute();
  //Proportional
  //rudder = rP*err*10; // rudder output [-1800,1800]
  //rudder_out = rudder/1800.*40. + 90.;

}

void tail_ctrl(void)
{
  float tail;
  float err;


  if (vwthetaBR > 0 && vwthetaBR < 180) {
    tP = 1; 
  }
  else {
    tP = -1; 
  }

  tPt = 1 - abs(compass.a.x/1024.);
  tPw = 1;//1 -(vwR/20);      //tail proportional to wind


  tail = tP*tPt*tPw*1000.;

  tail_out = tail/1000.*35. + 90.;
  //tail_out = map(tail*tailrev,-1000,1000,65+10,115+10);  //the map function sucks. use your own formula with floating point math

}


//---------------WORM--------------------
void worm_ctrl(void)
{
  float wind_direction_RelativeToBoat = vwthetaBR;        // This variable gives the direction of the wind and the value should be coming from the SENSOR

  float AoA1;                                             // Will give - AoA or + AoA, depending on which side the wing is
  float pos2;
  
  int correction_pulse_factor = 20;                       // After telling the motor to stop, the motor will still run for ~30 pulses because of the delay
                                                          // For this reason we tell the motor to stop 30 pulses earlier to stop at the right spot.
  
  int SFS = 120;                                          // SFS = Slow Foward Speed
  int FFS = 180;                                          // FFS = Full Foward Speed
  int SRS = 60;                                           // SRS = Slow Reversed Speed
  int FRS = 0;                                            // FRS = Full Reversed Speed
  
  int CSNOP = 500;                                        // CSNOP = Change Speed Number Of Pulses

//____________________
//-- This next 6 lines is just to make sure that Wing_Pos is between 0 and 360 degrees --

  if(wing_pos >= 360.00){
    wing_pos = wing_pos - 360.00;
  }
  if(wing_pos < 0.00){
    wing_pos = wing_pos + 360.00;
  }
//_____________________

//
//-- motor = LOW indicates that the motor is not moving at that moment. the program is made that the wing will move only after the completion of the precedent move --
  if(motor == LOW){
    
    pulse_counter = 0;                                                    // Each time that we re-start a move, the pulse_counter needs to start again from zero

    if(wind_direction_RelativeToBoat >=0 & wind_direction_RelativeToBoat <45 || wind_direction_RelativeToBoat >315 & wind_direction_RelativeToBoat <360)
    {
      AoA = AoAUP;
    }
    if(wind_direction_RelativeToBoat >= 45 & wind_direction_RelativeToBoat <=315)
    {
      AoA = AoADOWN;
    }
    
    
    if(wind_direction_RelativeToBoat >= 0 & wind_direction_RelativeToBoat <= 140){
      AoA1 = - AoA;
    }
  
    if(wind_direction_RelativeToBoat >= 220 & wind_direction_RelativeToBoat < 360){
      AoA1 = + AoA;      
    }

//    if(wind_direction_RelativeToBoat == 0.0){
//      AoA1 = 0.0;                                                 
//    }
//____________________
    pos2 = wind_direction_RelativeToBoat + AoA1;
//____________________    
    if(wind_direction_RelativeToBoat > 140 & wind_direction_RelativeToBoat < 220){
      if(wing_pos >= 0 & wing_pos < 180){
        pos2 = 90.0;
      }
      if(wing_pos >= 180 & wing_pos < 360){
        pos2 = 270.0;
      }
    }
//______________________
    
    delta_wing_angle = (pos2) - wing_pos;                                   // Delta_wing_angle indicates the angle that the wing needs to rotate 
                                                                            // from its precedent position (delta_angle = pos2 - pos1)
      
    if(delta_wing_angle > 180.00){                                          // Those 6 next lines are making sure that the wing take the shortest way to get to its new position
      delta_wing_angle = delta_wing_angle - 360.00;
    }
    if(delta_wing_angle < -180.00){
      delta_wing_angle = delta_wing_angle + 360.00;
    }    
              
//___________________________________________________
//-- If we don't wanna move the DC motor: --

    if(abs(delta_wing_angle) >= 0.00 & abs(delta_wing_angle) <3.00){
      n_pulses = 0;           // We don't wanna move the motor if Delta_angle si smaller than 2 degrees. This would bring a bug 'cause of the correction_pulse_factor
                              // and also, we don't want the motor to be too sensible.
      
//      if(delta_wing_angle != 0){
//        Serial.println("Angle is too small!");
//        Serial.print("Delta Wing Angle = ");
//        Serial.println(delta_wing_angle);
//      }
//      Serial.println("No intention of Moving!");
//      Serial.print("\n");
//      delay(3000);
    }
        

    if(abs(delta_wing_angle) >= 3.00){            // If delta_wing_angle is bigger or equal to 2 degrees, the motor will start rotation so motor = HIGH
      motor = HIGH;
    }
  
  }

//
//-- WHEN THE MOTOR IS RUNNING, WE DON'T WANT THE DELTA_WING_ANGLE TO CHANGE!!!! It would be hard to count the pulses! --
  
  if(motor == HIGH){
    n_pulses1 = (9360./360.)*delta_wing_angle;                          // The use of the float brings more precision with the n_pulses
    n_pulses = (int)n_pulses1;                                          //The number of pulses to reach is a function of the mast angle we want to move. we are using an "int"!
          
        
//___________________________________________________
//-- If we want to move the DC Motor : --
          
    if(pulse_counter < (abs(n_pulses)-correction_pulse_factor)){
      if(pulse_counter == 0){                                           //Used to start the motor
            
        if(n_pulses > 0){                                               //If we wanna go in the foward direction
          worm_out = SFS;                                               //Slow Foward Speed
          Worm_Servo.write(worm_out);                                         
        }
            
        if(n_pulses < 0){                                               //If we wanna go in the reversed direction
          worm_out = SRS;                                               //Slow Reverse Speed
          Worm_Servo.write(worm_out);                                        
        }
      }
          
      if(pulse_counter != 0){                                           //After the start of the motor, Nothing happens when we are counting the pulses
//        Serial.println(pulse_counter);

          if(n_pulses > 0){
            if(pulse_counter > CSNOP){
              worm_out = FFS;                                           //Full Foward Speed
              Worm_Servo.write(worm_out);
            }
            if(pulse_counter >= (abs(n_pulses)-correction_pulse_factor-CSNOP)){
              worm_out = SFS;                                           //Slow Foward Speed
              Worm_Servo.write(worm_out);
            }
          }
          
          if(n_pulses < 0){
            if(pulse_counter > CSNOP){
              worm_out = FRS;                                             //Full Reverse Speed
              Worm_Servo.write(worm_out);
            }
            if(pulse_counter >= (abs(n_pulses)-correction_pulse_factor-CSNOP)){
              worm_out = SRS;                                            //Slow Reverse Speed
              Worm_Servo.write(worm_out);
            }
          }
        
      }
    }        
//___________________________________________________
//--If we want to STOP the DC Motor : -- 
  
    if(pulse_counter >= (abs(n_pulses)-correction_pulse_factor) & n_pulses != 0){
      
      worm_out = 91;    
      Worm_Servo.write(worm_out);                                   //'90' is about No Speed     
                                                                    // You need couple miliseconds between the time that you tell the motor to 
                                                                    // stop and the time that you read the actual position of the wing   
          
      motor = LOW;
        
//      delta_wing_angle = 0.00;                                        // Nom that we reached our delta_wing_angle we need to bring it back to zero 
                                                                      // to make sure we stay in position
      
      delay(100);
        
//-- Now that the motor is stopped, the Serial will print all the following information: --
  
//-- First we start with the difference of where we wanted to go and where we actually went. --

//      Serial.print("The number of pulses we WANTED to reach =  ");
//      Serial.println(n_pulses);
//  
//          
//      Serial.print("The number of pulses we DID reached =  ");
//      Serial.println(pulse_counter);    
          
      if(n_pulses > 0){
        wing_pos = wing_pos + (360./9360.)*(float)pulse_counter;      //(If went Clock Wise)
      }
      if(n_pulses < 0){
        wing_pos = wing_pos - (360./9360.)*(float)pulse_counter;      //(If went Counter Clock Wise)
      }

                                                                      
          
      if(wing_pos >= 360.00){                                         // The angle should stay between 0 and 360 degrees
        wing_pos = wing_pos - 360.00;
      }
      if(wing_pos < 0.00){
        wing_pos = wing_pos + 360.00;
      }         
// Next, it prints the position of the wing and also the direction of the wind (those to are relative to the boat)       
 

//      delay(2000);  
          
    }
  }              
}
//-------------ENDWORM------------------

void camber_ctrl(void)
{
  if (vwthetaBR >= 5 && vwthetaBR <= 355)    // if we are pointing at least 50 degrees from the wind use the camber
  {
    if (vwthetaBR >= 0 && vwthetaBR <=140) {  //if wind is starboard
      camber_out = 120; 
    }
    if (vwthetaBR >= 220 && vwthetaBR <360) {
      camber_out = 60; 
    }
    if (vwthetaBR > 140 && vwthetaBR <220) {
      camber_out = 90; 
    }
    
  }
  else  //otherwise don't use camber for max L/D //nevermind we always use camber
  {
    camber_out=90;  
  }
}

void servo_out(void)
{
  Rudd_Servo.write((int)rudder_out+91);
  Camb_Servo.write(camber_out);
  Tail_Servo.write(tail_out);
  Worm_Servo.write(worm_out);

//  Serial.print("Wing Pos = ");
//  Serial.print(wing_pos);        //(where we actually stopped)
//  Serial.print("  ");
//  Serial.print("AoA = ");
//  Serial.print(AoA);
//  Serial.print("  ");
//  Serial.print("Detla Wing angle = ");
//  Serial.println(delta_wing_angle);
//  Serial.println("");
}





