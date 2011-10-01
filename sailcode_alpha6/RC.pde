void RCMode(){

  Serial.println("RC mode, receives inputs from other arduino and hacked old transmitter");
  Serial.println(" 'q' exits back to menu, you might need to press it up to 3 times.");
  Serial.println("~");
  rudderDir *= -1;
  int sailsVal = 0;
  int rudVal = 0;
  boolean exit = false;
  int rcVal;
  
  while (!exit){
    while(Serial.available() == false);
    rcVal = Serial.read();
    switch(rcVal)
    {  
    case '1'://rudder values are from 120 to 180, ignore the 1 then subtract 50 to get actual -30 to 30 value
      while(!Serial.available());
      rudVal = Serial.read() - '0';
      while(!Serial.available());
      rudVal = rudVal*10 + Serial.read() - '0';
      rudVal -= 50;
      setrudder(rudVal);
      break; 
    case '2'://sails values are from 220 to 280, ignore the 2 then subtract 50 to get actual -30 to 30 value
      while(!Serial.available());
      sailsVal = Serial.read() - '0';
      while(!Serial.available());
      sailsVal = sailsVal*10 + Serial.read() - '0';
      sailsVal -= 25;
      sailsVal *= 2; 
      setSails(sailsVal);                                                          
      break;                                                       
    case 'q':
      Serial.println("exiting RC mode");
      delay(2000);
      Serial.println("||||||||||||||||||||||||||||||||||||||||||||||");            //ending symbol, lots so that it is not missed
      rudderDir *= -1;
      exit = true;
    }                                                                                                            
  }
}

