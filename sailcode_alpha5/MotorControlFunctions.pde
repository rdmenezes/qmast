//arduino servo library
void arduinoServo(int pos){
      myservo.write(pos);              // tell servo to go to position in variable 'pos' 
}


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
 
  int servo_num =1;
  int pos; //position ("position" was highlighted as a special name?)
 // Serial.println("Controlling motors");
  
//check input, and change is appropriate
  if (ang > 45)
    ang = 45;
  else if (ang < -45)
    ang = -45;
  
  pos = RUDDER_SERVO_RATE*(ang + 45) * 254.0 / 90.0;//convert from 180 degree range, -90 to +90 angle to a 0 to 256 maximum position range
  
  servo_command(servo_num,pos,0);
  //delay(10);
}

void setSails(float ang)
//this could make more sense conceptually for sails if it mapped 0 to 90 rather than -45 to +45
// presently the working range on the smartwinch (april 3) only respoings to -30 to +30 angles
{
  int servo_num = 2;
  int servo_num2 = 0;    //to be second servo for jib
  int pos; //position ("position" was highlighted as a special name?)
 // Serial.println("Controlling motors");
 int posjib; //jib position
  
//check input, and change is appropriate
  if (ang > 45)
    ang = 45;
  else if (ang < -45)
    ang = -45;
  
  pos = MAIN_SERVO_RATE*(ang + 45) * 254.0 / 90.0;//convert from 180 (90?) degree range, -90 to +90 (-45 to +45?) angle to a 0 to 256 maximum position range
  posjib = JIB_SERVO_RATE*(ang + 45) * 254.0 / 90.0;        //convert to proper jib position, modify after testing to match ain sail
  servo_command(servo_num,pos,0); //0 tells it to only turn short range
  servo_command(servo_num2,posjib,0);        //turn jib
}
void setJib(float ang)
//yet to be implemented code for 3rd servo
//currently using setsails to call both main and jib servos
{
  int servo_num = 0;
  int pos;
  
  if (ang >45)
  ang = 45;
  else if (ang < -45)
  ang = -45;

  pos = JIB_SERVO_RATE*(ang + 45) * 254.0/90.0;
  servo_command(servo_num,pos,0);
}
void setMain(float ang)
//code for setting main sail only
{
  int servo_num = 2;
  int pos;
  if (ang > 45)
  ang = 45;
  else if (ang < -45)
  ang = -45;
  
  pos = MAIN_SERVO_RATE* (ang + 45) * 254.0/90.0;
    servo_command(servo_num,pos,0);
}
