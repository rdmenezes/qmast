/*
Testing the Hall Effect sensor
Valerie and Lazlo
July 2012

http://www.gmw.com/magnetic_sensors/sentron/2sa/GMW360ASM.html
http://www.gmw.com/magnetic_sensors/ametes/documents/Ametes_360ASM_Spec_07_May_2007.pdf

The short version:
Analog out gives 2.5V at 0 degrees, 0.5V at -180 degrees, 4.5V at 180 degrees
Sensor can reset its zero angle by temporarily connecting the analog out pin to +5V. This is then stored in non-volatile memory

Range of analag input is 0-1023
*/

#define ANGLE_PIN A5
#define ZERO_VOLTS 512
#define NO_FIELD_PIN 2
int input_angle;
int input_no_field;
int angle;

void setup() {
   Serial.begin(9600); 
   pinMode(ANGLE_PIN, INPUT);  
   pinMode(NO_FIELD_PIN, INPUT);
   input_angle = 0;
}


void loop() {
  
  input_angle = analogRead(ANGLE_PIN);
  input_no_field = digitalRead(NO_FIELD_PIN);
  angle = (input_angle - ZERO_VOLTS)*(180.0/408.0); //scale factor for mapping degrees to analog input values
  if(input_no_field == LOW)
  {
    Serial.println("No magnet...");
  }
  else
  {
    Serial.println(angle);
  }
  delay(500);
  
}  
