/*
*  Copyright (C) 2012 Libelium Comunicaciones Distribuidas S.L.
*  http://www.libelium.com
*
*  This program is free software: you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation, either version 3 of the License, or
*  (at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see .
*
*  Version 0.1
*  Author: Alejandro Gállego
*/


int led = 13;
int onModulePin = 2;        // the pin to switch on the module (without press on button) 

int timesToSend = 1;        // Numbers of SMS to send
int count = 0;

char phone_number[]="**********";     // ********* is the number to call

void switchModule(){
    digitalWrite(onModulePin,HIGH);
    delay(2000);
    digitalWrite(onModulePin,LOW);
}

void setup(){

    Serial.begin(115200);                // UART baud rate
    delay(2000);
    pinMode(led, OUTPUT);
    pinMode(onModulePin, OUTPUT);
    switchModule();                    // switches the module ON

    for (int i=0;i< 5;i++){
        delay(5000);
    } 

    Serial.println("AT+CMGF=1");         // sets the SMS mode to text
    //Serial.println("AT");
    delay(100);
}

void loop(){

  
    while (count < timesToSend){
        delay(1500);
        Serial.print("AT+CMGS=\"");   // send the SMS number
        Serial.print(phone_number);
    Serial.println("\""); 
        delay(1500);      
        Serial.print("Hello from Telus sim/cooking hacks board.");     // the SMS body
        delay(500);
        Serial.write(0x1A);       //sends ++
        Serial.write(0x0D);
        Serial.write(0x0A);

        delay(5000);

        count++;
    }
}
