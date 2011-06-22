//arduino servo library
//void arduinoServo(int pos){
//      myservo.write(pos);              // tell servo to go to position in variable 'pos' 
//}


//Pololu servo board test in Mini SSC II mode
//(mode jumper innplace on Pololu board)

//Servo_command receieves a servo number (acceptable range: 00-FE) and a position (acceptable range: 00-FE)
void servo_command(int whichservo, int position, byte longRange)
{
 servo_ser.print(0xFF, BYTE); //servo control board sync
 //Plolou documentation is wrong on servo numbers in MiniSSCII
 servo_ser.print(whichservo+(longRange*8), BYTE); //servo number, 180 mode
 servo_ser.print(position, BYTE); //servo position
}


//Accept a angle range to turn the rudder to 
//float ang acceptable values: 90 degree total range (emulation); -45 = left; +45 = right; 0 = centre 
// this direction (-'ve angles are LEFT turns) has been verified on the roller skate boat, with the wheel at the back emulating the rudder properly
// except the servo is upside down; so on the real boat, -'ve angles are RIGHT turns
void setrudder(float ang)
{
//fill this in with the code to interface with pololu 

  int servo_num = 1;
  int pos; //position ("position" was highlighted as a special name?)
  
 // Serial.println("Controlling motors");
  
//check input, and change is appropriate
constrain(ang,-30,30);

  pos = RUDDER_SERVO_RATE*(ang + 45) * rudderDir * 254.0 / 90.0;//convert from 180 degree range, -90 to +90 angle to a 0 to 256 maximum position range
//  myservo.write((ang+90));
  servo_command(servo_num,pos,0);
  //delay(10);
}

void setSails(float ang)
//this could make more sense conceptually for sails if it mapped 0 to 90 rather than -45 to +45
// presently the working range on the smartwinch (april 3) only respoings to -30 to +30 angles
{
  setJib(ang);
  setMain(ang);

 
}
void setJib(float ang)
//yet to be implemented code for 3rd servo
//currently using setsails to call both main and jib servos
{
  int servo_num = 3;
  int pos;
  constrain(ang, 1,100);

  pos = ang*110.0/100.0;
    servo_command(servo_num,pos,0); 
}
void setMain(float ang)
//code for setting main sail only
{
  int servo_num = 2;
  int pos;
  constrain(ang,1,100);
  
  pos = (ang + 50)*104.0/100.0;
  servo_command(servo_num,pos,0); 
}
int pid(int err)
//experimental code for a possible future pid control of rudder and sails
//this may give better performance and smooth out motor movements
//needs to be tuned
//proportion values for all 3 sections need to be adjusted,
//integral function may need to be limited to prevent overshoot
//may need to eliminate derivative term completely if the system noise turns out to be too great
{
 static int error;    //the amount of error
 static int proportion;    //proportional change to the error
 static int integral;    //integral change
 static int differential;  //differential change
 static int lastError[5];      //previous error
 static int output;
 static int i = 0;            //counter
 int j;
  
  error = err;
  proportion = error/5;
  for(j = 0; j <5; j++)
  {
  integral += lastError[i]/20;
  }
  integral += error/20 ;
  differential = (error - lastError[i-1])/10;
  lastError[i] = error;
  if(i == 4){
    i = 0;
  }
  else{
    i++;
  }
  output = proportion+ integral + differential;
  return output;
}
