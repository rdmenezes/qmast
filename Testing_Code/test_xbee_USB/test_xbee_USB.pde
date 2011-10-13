

void setup()
{
  Serial.begin(9600);
  
  
  
}

void loop()
{
  char incoming;
  if(Serial.available())
  {
    Serial.println("Reading properly");    
  }
  while(Serial.available())
  {
    incoming = Serial.read();
    Serial.print(incoming);
  }
  
  Serial.println("yay!");
  
  delay(1000);
  
}
