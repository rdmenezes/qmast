#define WINCH 3
#define RUDDER 1
#define POWER 11
#define DIRECTION 9
#define ANGLE_PIN A5

#define ZERO_VOLTS 512 
#define NO_FIELD_PIN 2
#define MIN_ANGLE 110          //set later when in boat and sail on
#define MAX_ANGLE 200


int input_angle;
int input_no_field;
int angle;
int winchVal;

void setup(){

  Serial.begin(9600);

  pinMode(WINCH, INPUT);
  pinMode(POWER, OUTPUT);
  pinMode(DIRECTION, OUTPUT);
  pinMode(ANGLE_PIN, INPUT);  
  pinMode(NO_FIELD_PIN, INPUT);
  input_angle = 0;


}
void loop(){
  winchVal = getPWM_Value(WINCH);
  input_angle = analogRead(ANGLE_PIN);
  input_no_field = digitalRead(NO_FIELD_PIN);

  Serial.print("input_angle:");
  Serial.print(input_angle);
  Serial.print("   winchval:");
  Serial.print(winchVal);
  
  if( (winchVal < 20 && winchVal > 0) && (input_angle > MIN_ANGLE)){
    // pull in
    digitalWrite(POWER, HIGH);
    digitalWrite(DIRECTION, LOW);
    Serial.println(" Dir-LOW");
  }
  else if ((winchVal > 60) && (input_angle < MAX_ANGLE)){
    digitalWrite(POWER, HIGH);
    digitalWrite(DIRECTION, HIGH);
    Serial.println(" Dir-HIGH");
  }
  else{
    digitalWrite(POWER, LOW);

  }

  Serial.println(" ");
  delay(100);
}//end of loop

int getPWM_Value(int pinIn){

  int RCVal = pulseIn(pinIn, HIGH, 20000);
  if (RCVal == 0) {
    RCVal = -1;
  }

  RCVal = map(RCVal, 1000, 2000, 0, 100);
  return RCVal;

}

