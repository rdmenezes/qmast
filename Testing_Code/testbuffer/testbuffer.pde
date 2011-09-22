/*
* Code to test the behaviour of the buffer. Sets up, waits 2 seconds, reads all data available in the buffer, the prints it out.
* To make it go again, type "g" into the serial monitor.
* If you want the line numbers to appear, change the global bool linenumbers to true.
* This code does NOT output what is input to the buffer in real time.
*
* To change the size of the buffer, change the global RX_BUFFER_SIZE in HardwareSerial.cpp in C:\..\arduino-0021\hardware\arduino\cores\arduino
*
* The purpose of this code was to see whether buffer was overwritting itself before being emptied. It is not (as suspected). The buffer is written 
* to until full, then no further data is accepted. Also we wanted to see the proof that we could effectively change the size of the buffer.
*
* Feb 14th, 2011
* Valerie Sugarman
*/



char buffer[300]; // hold data read from the buffer before printing to the serial monitor. make it bigger than it needs to be
bool go; // whether or not to execute the code on this iteration. Code will execute once by default, then again when the users inputs "g" into the serial monitor
bool linenumbers = false; // whether or not to display linenumbers and print one byte at a time from the buffer, or display as a chunk.

void setup()
{
  Serial.begin(9600);
  Serial2.begin(19200);
  go = true;
  delay(2000); // let everything set itself up.
}

void loop()
{

  if(go)
  {
    int i;
    for(i = 0; Serial2.available(); i++)
    {
      buffer[i] = Serial2.read();
    }

    for(int j = 0; j < i; j++)
    {
      if(linenumbers)
      {
        Serial.print(j, DEC);
        Serial.print(": ");
        Serial.println(buffer[j]);
      }
      else
      {
         Serial.print(buffer[j]);
      }
     

    }
    go = false;
    Serial.println("\nDone!");
  }
  
  if(Serial.available())
  {
    char input = Serial.read();
    if(input == 'g')
      go = true;
  }


}


