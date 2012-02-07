


#define oldDataLED 49 //there is data, but buffer is full, error indicator light
#define noDataLED  48 // no data, error indicator LED
#define twoCommasLED 51 // indicates that there were two commas in the data, and it has been discarded and not parsed
#define checksumBadLED 50 // indicates checksum fail on data
#define goodCompassDataLED 53 // indicates that strtok returned PTNTHTM, so we probably got good data
#define rolloverDataLED 52 //indicates data rolled over, not fast enough

void setup () {
pinMode(oldDataLED, OUTPUT); //there is data, but buffer is full, error indicator light
 pinMode(noDataLED, OUTPUT);  // no data, error indicator LED
 pinMode(twoCommasLED, OUTPUT); // indicates that there were two commas in the data, and it has been discarded and not parsed
 pinMode(checksumBadLED, OUTPUT);// indicates checksum fail on data
 pinMode(goodCompassDataLED, OUTPUT); // indicates that strtok returned PTNTHTM, so we probably got good data
 pinMode(rolloverDataLED, OUTPUT); //indicates data rolled over, not fast enough
}

void loop () {
  digitalWrite(oldDataLED, HIGH);
  digitalWrite(noDataLED,HIGH);
  digitalWrite(twoCommasLED,HIGH);
  digitalWrite(checksumBadLED,HIGH);
  digitalWrite(goodCompassDataLED,HIGH);
  digitalWrite(rolloverDataLED,HIGH);
  
  delay(1000);
  
  digitalWrite(oldDataLED, LOW);
  digitalWrite(noDataLED,LOW);
  digitalWrite(twoCommasLED,LOW);
  digitalWrite(checksumBadLED,LOW);
  digitalWrite(goodCompassDataLED,LOW);
  digitalWrite(rolloverDataLED,LOW);
  
  delay(1000);
  
}

