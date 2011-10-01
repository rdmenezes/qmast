//function for checking soil moisture against threshold
void moistureCheck() {
  static int counter = 1;//init static counter
  int moistAverage = 0; // init soil moisture average
  if((millis() - lastMoistTime) / 1000 > (MOIST_SAMPLE_INTERVAL / MOIST_SAMPLES)) {
    for(int i = MOIST_SAMPLES - 1; i > 0; i--) {
      moistValues[i] = moistValues[i-1]; //move the first measurement to be the second one, and so forth until we reach the end of the array.   
    }
    digitalWrite(PROBEPOWER, HIGH);
    moistValues[0] = analogRead(MOISTPIN);//take a measurement and put it in the first place
    digitalWrite(PROBEPOWER, LOW);
    lastMoistTime = millis();
    int moistTotal = 0;//create a little local int for an average of the moistValues array
    for(int i = 0; i < MOIST_SAMPLES; i++) {//average the measurements (but not the nulls)
      moistTotal += moistValues[i];//in order to make the average we need to add them first 
    }
    if(counter<MOIST_SAMPLES) {
      moistAverage = moistTotal/counter;
      counter++; //this will add to the counter each time we've gone through the function
    }
    else {
      moistAverage = moistTotal/MOIST_SAMPLES;//here we are taking the total of the current light readings and finding the average by dividing by the array size
    } 
    //lastMeasure = millis();
    Serial.print("moist: ");
    Serial.println(moistAverage,DEC); 

    ///return values
    if ((moistAverage < DRY)  &&  (lastMoistAvg >= DRY)  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
      uint8_t response = posttweet("URGENT! Water me!");   // announce to Twitter
      notify(response); 
    }
    else if  ((moistAverage < MOIST)  &&  (lastMoistAvg >= MOIST)  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
      uint8_t response = posttweet("Water me please.");   // announce to Twitter
      notify(response); 
    }
    lastMoistAvg = moistAverage; // record this moisture average for comparision the next time this function is called
    moistLight(moistAverage);
  }
}


//function for checking for watering events
void wateringCheck() {
  int moistAverage = 0; // init soil moisture average
  if((millis() - lastWaterTime) / 1000 > WATERED_INTERVAL) {
    digitalWrite(PROBEPOWER, HIGH);
    int waterVal = analogRead(MOISTPIN);//take a moisture measurement
    digitalWrite(PROBEPOWER, LOW);
    lastWaterTime = millis();

    Serial.print("watered: ");
    Serial.println(waterVal,DEC);
    if (waterVal >= lastWaterVal + WATERING_CRITERIA) { // if we've detected a watering event
      if (waterVal >= SOAKED  &&  lastWaterVal < MOIST &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL))) {
        uint8_t response = posttweet("Thank you for watering me!");  // announce to Twitter
        notify(response); 
      }
      else if  (waterVal >= SOAKED  &&  lastWaterVal >= MOIST  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
        uint8_t response = posttweet("You over watered me.");   // announce to Twitter
        notify(response); 
      }
      else if  (waterVal < SOAKED  &&  lastWaterVal < MOIST  &&  (millis() > (lastTwitterTime + TWITTER_INTERVAL)) ) {
        uint8_t response = posttweet("You didn't water me enough.");   // announce to Twitter
        notify(response); 
      }
    }    
    lastWaterVal = waterVal; // record the watering reading for comparison next time this function is called
  }
}


// function that prints twitter results to debug port
void notify( uint8_t resp) {
  if (resp)
    putstring_nl("tweet ok");
  else {
    putstring_nl("tweet fail");
    blinkLED(COMMLED,2,500);
  }
}


void moistLight (int wetness) {
  if (wetness < DRY) {
    blinkLED(MOISTLED, 6, 50);
    analogWrite(MOISTLED, 8);
  }
  else if (wetness < MOIST) {
    blinkLED(MOISTLED, 2, 500);
    analogWrite(MOISTLED, 24);
  }
  else {
    analogWrite(MOISTLED,wetness/4); // otherwise display a steady LED with brightness mapped to moisture
  }
}


void buttonCheck() { 
  static boolean lastSwitch = HIGH;
  static boolean lineEnding = false;
  if (digitalRead(SWITCH) == LOW && lastSwitch == HIGH) {

    digitalWrite(PROBEPOWER, HIGH);
    long moistLevel = analogRead(MOISTPIN);
    digitalWrite(PROBEPOWER, LOW);

    char *str1 = "Current Moisture: ";
    char *str2;
    str2= (char*) calloc (4,sizeof(char)); // allocate memory to string 2
    char *str3 = "%";
    char *str4 = "."; // a period ends every other tweet so there are no repeats

    itoa((moistLevel*100)/800,str2,10); //moisture is on a scale from 0 to 790.
    char *message;
    message = (char *)calloc(strlen(str1) + strlen(str2) + strlen(str3) + strlen(str4) + 1, sizeof(char));
    strcat(message, str1);
    strcat(message, str2);
    strcat(message, str3);   
    lineEnding = !lineEnding; // flip the line ending bit so every test is different (twitter won't post repeats)
    if (lineEnding)  strcat(message, str4);
    uint8_t response = posttweet(message);   // announce to Twitter
    free(message);
    free(str2);
    notify(response);  
    if (digitalRead(SWITCH) == LOW) { // if switch is held down, send a second tweet with the version number
      digitalWrite(XPORT_RESETPIN, LOW); // hold XPort in reset when it's not in use
      blinkLED(COMMLED,4,1000);
      char *message;
      char *str1 = "v";
      message = (char *)calloc(strlen(str1) + strlen(VERSION) + 1, sizeof(char));
      strcat(message, str1);
      strcat(message, VERSION);
      uint8_t response = posttweet(message);   // announce to Twitter
      free(message);
      notify(response);  
    }
  }
  lastSwitch = digitalRead(SWITCH);
}
