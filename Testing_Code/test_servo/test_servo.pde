#include <Servo.h>

Servo myservo;


void setup()
{
  Serial.begin(9600);
  myservo.attach(7);
  
}

void loop()
{
  delay(3000);
  myservo.write(0);
  delay(3000);
  myservo.write(180);
  
  
}
