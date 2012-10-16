void setup()
{
  Serial.begin(9600);
  
}


void loop(){
  byte in;
  while(Serial.available())
  {
   in = Serial.read();
    Serial.print(in); 
  }
  
}
