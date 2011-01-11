
 int count;
 int pinThirteen;
 int pinTwelve;
 int pinTen;
  

void setup() {                
  
  count = 0;
  
  pinThirteen=1;
  pinTwelve=1;
  pinTen=1;
  
  pinMode(13, OUTPUT); 
  pinMode(12, OUTPUT);  
  pinMode(10, OUTPUT);
  
  digitalWrite(13, HIGH);
  digitalWrite(12, HIGH);
  digitalWrite(10, HIGH);
}

void loop() {
  toggle(13);
  if(count%3==0){
    toggle(12);
  }
  if (count%12==0){
    toggle(10);
  }
  delay(100);
  count++;
  
}

void toggle(int pin){
 if (pin == 13){ 
  if (pinThirteen == 1){
    digitalWrite(13,LOW);
    pinThirteen = 0;
  }
  else if (pinThirteen == 0){
    digitalWrite(13, HIGH);
    pinThirteen =1;
  }
 }
 
  else if (pin ==12){
   if(pinTwelve == 1){
     digitalWrite(12, LOW);
     pinTwelve = 0;
   }
   else if (pinTwelve ==0){
    digitalWrite(12,HIGH);
    pinTwelve=1;
   }
 }
 
 else if (pin ==10){
   if(pinTen == 1){
     digitalWrite(10, LOW);
     pinTen = 0;
   }
   else if (pinTen ==0){
    digitalWrite(10, HIGH);
    pinTen=1;
   }
 }
}
