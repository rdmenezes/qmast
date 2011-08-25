
//Pololu servo board test in Mini SSC II mode
//(mode jumper inplace on Pololu board)

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
    int pos; //position 
  
//check input, and change is appropriate
    constrain(ang,-30,30);
    pos = (ang + 45) * rudderDir * 254.0 / 90.0;//convert from 180 degree range, -90 to +90 angle to a 0 to 256 maximum position range
    servo_command(servo_num,pos,0);
    rudderVal = ang;
}

void setSails(float ang)
//this could make more sense conceptually for sails if it mapped 0 to 90 rather than -45 to +45
{
    setJib(ang);
    setMain(ang); 
}

void setJib(float ang)
//currently using setsails to call both main and jib servos
{
    int servo_num = 3;
    int pos;
  
    constrain(ang, 1,100);
    pos = ang*110.0/100.0; //tweaking for gaelforce 2, 
    servo_command(servo_num,pos,0); 
    jibVal = ang;
}

void setMain(float ang)
//code for setting main sail only
{
    int servo_num = 2;
    int pos;

    constrain(ang,1,100);  
    pos = (ang + 50)*104.0/100.0;  //tweaking for gaelforce 2, check if smartwinch fuse blows
    servo_command(servo_num,pos,0); 
    mainVal = ang;
}


