// Parser for Hall Effect Sensor
// Returns angle detected by sensor. If error, returns -360.
/*
#define ANGLE_PIN A3
#define NO_FIELD_PIN 2
#define ZERO_VOLTS 512
*/
int HallEffectParse(void)
{
  int input_angle = 0;
  int no_field;
  int angleOut;
  
  input_angle = analogRead(ANGLE_PIN);  
  no_field = digitalRead(NO_FIELD_PIN);
  angleOut = (input_angle - ZERO_VOLTS)*(180.0/408.0); //scale factor for degrees to analog voltage
  if(no_field == LOW)
  {
    return -360;
  }
  else
  {
    angleOut = angleOut + 180; //adjust since sensor outputs -180 to 180
    return angleOut;
  }
}
