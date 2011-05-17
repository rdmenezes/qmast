// 'c' = compass
// 'w' = wind sensor
// sensorData replaces Compass() and Wind() with one function. This is not complete; the rollover array (at least) needs to be split into two separate arrays.
int sensorData(int bufferLength, char device) 
{ //compass connects to serial2
  int dataAvailable; // how many bytes are available on the serial port
  char array[LONGEST_NMEA];//array to hold data from serial port before parsing; 2* longest might be too long and inefficient

  char checksum; //computed checksum for the NMEA data between $ and *
  char endCheckSum; //the HEX checksum that is added by the NMEA device
  int xorState; //holds the XOR  state (whether to use the next data in the xor checksum) from global
  int j; //j is a counter for the number of bytes which have been stored but not parsed yet

  int i; //counter

  int error;//error flag for parser
  bool twoCommasPresent = false; //Alright, this flag will be set if the data being read in has two commas in a row. This is needed since
  	  	  	  	  	  	  	  	 //it will crash the program as strtok will have trouble with the delimiters later.

  Serial.println(device); //display that data is being gathered from a device

   // delay(5000);
   if(device == 'c')
   dataAvailable = Serial2.available(); //check how many bytes are in the buffer
   else if (device == 'w')
   dataAvailable = Serial3.available(); //check how many bytes are in the buffer
 
 if(!dataAvailable)
 {
    noData = 1;//set a global flag that there's no data in the buffer; either the loop is running too fast or theres something broken
    Serial.println("No data available. ");
    digitalWrite(noDataLED,HIGH);//turn on error indicator LED to warn about no data present
    digitalWrite(goodCompassDataLED, LOW); //data isnt good if it isnt there
  } 
  else {
    digitalWrite(oldDataLED,LOW); //there is data, buffer isnt full, so turn off error indicator light
    digitalWrite(noDataLED,LOW);//turn off error indicator LED to warn about no data
    
    if (dataAvailable > bufferLength) { //the buffer has filled up; the data is likely corrupt;
    //may need to reduce this number, as the buffer will still fill up as we read out data and dont want it to wraparound between here an
    //when we get the data out
    
    //flushing data is probably not the best; the data will not be corrupt since the port blocks, it will justbe old, so accept it.
      Serial.flush(); //clear the serial buffer
//    extraWindData = 0; //'clear' the extra data buffer, because any data wrapping around will be destroyed by clearing the buffer
//    savedChecksum=0;//clear the saved XOR value
//    savedXorState=0;//clear the saved XORstate value
//    lostData = 1;//set a global flag to indicate that the loop isnt running fast enough to keep ahead of the data

        Serial.println("You filled the buffer, data old. ");
        digitalWrite(oldDataLED,HIGH);//turn on error indicator LED to warn about old data
        digitalWrite(goodCompassDataLED, LOW); //data is old, so not so goood
       }

    
    //first copy all the leftover data into array from the buffer;  //!!! this has to depend on if it's wind or compass, and different arrays for them!
    if(device == 'w')
    {
      for (i = 0; i < extraWindData; i++){
        array[i] = extraWindDataArray[i]; //the extraWindData array was created the last time the buffer was emptied
        //probably actually don't need the second global array
      }
    }
    else if (device == 'c')
    {
      for (i = 0; i < extraCompassData; i++){
        array[i] = extraCompassDataArray[i]; //the extraWindData array was created the last time the buffer was emptied
        //probably actually don't need the second global array
      }
    }
    
    //now continue filling array from the serial port
  
    if(device == 'w')
    {
      checksum = savedWindChecksum;//set the xor error checksum to the saved value (only xor if between $ and *)
      xorState = savedWindXorState;//set the XOR state (whether to use the next data in the xor checksum) from global
      j = extraWindData; //j is a counter for the number of bytes which have been stored but not parsed yet
      extraWindData = 0;//reset for the next time, in case there isn't any extraData; could optimize these variable declarations
      savedWindChecksum = 0;//reset for the next time
      savedWindXorState = 0;//reset for next time
    }
    else if (device == 'c')
    {
      checksum = savedCompassChecksum;//set the xor error checksum to the saved value (only xor if between $ and *)
      xorState = savedCompassXorState;//set the XOR state (whether to use the next data in the xor checksum) from global
      j = extraCompassData; //j is a counter for the number of bytes which have been stored but not parsed yet
      extraCompassData = 0;//reset for the next time, in case there isn't any extraData; could optimize these variable declarations
      savedCompassChecksum = 0;//reset for the next time
      savedCompassXorState = 0;//reset for next time
    }
    
  //  Serial.print(array[0]);
   // Serial.print(array[1]);
   // Serial.print(array[2]);
    
    while(dataAvailable){//this loop empties the whole serial buffer, and parses every time there is a newline
    
     if(device == 'c')
      array[j] = Serial2.read();
      else  if(device == 'w')
      array[j] = Serial3.read();
      
      //Serial.print(array[j]);      
    	if (j > 0) {
    		if (array[j] == ',' && array[j-1] == ',') {
    			twoCommasPresent = true;
                        digitalWrite(goodCompassDataLED, LOW); //data is bad
                        digitalWrite(twoCommasLED,HIGH);//turn on error indicator LED to warn about old data                         
    		}
    	}

        if ((array[j] == '\n') && j > SHORTEST_NMEA) {//check the size of the array before bothering with the checksum
        //if you're not getting here and using serial monitor, make sure to select newline from the line ending dropdown near the baud rate
      //  Serial.print("read slash n, checksum is:  ");
        //compass strings seem to end with *<checksum>\r\n (carriage return, linefeed = 0x0D, 0x0A) so there's an extra j index between the two checksum values (j-3, j-2) and the current j.
        //just skip over it when checking the checksum
          endCheckSum = (convertASCIItoHex(array[j-3]) << 4) | convertASCIItoHex(array[j-2]); //calculate the checksum by converting from the ASCII to HEX 
     //   Serial.print(endCheckSum,HEX);
    //    Serial.print("  , checksum calculated is  ");
     //   Serial.println(checksum,HEX);
        //check the XOR before bothering to parse; if its ok, reset the xor and parse, reset j
          if (checksum==endCheckSum){
        //since hex values only take 4 bits, shift the more significant half to the left by 4 bits, the bitwise or it with the least significant half
        //then check if this value matches the calculated checksum (this part has been tested and should work)
    //      Serial.println("checksum good, parsing.");

          //Before parsing the valid string, check to see if the string contains two consecutive commas as indicated by the twoCommasPresent flag
            if (!twoCommasPresent) {
             // Serial.println(array[0]); //print first character (should be $)
              array[j+1] = '\0';//append the end of string character
              digitalWrite(twoCommasLED,LOW);//turn off error indicator LED to warn about old data
    //          Serial.println("Good string, about to parse");
              error = Parser(array); //checksum was successful, so parse              
              //delay(500);  //trying to add a delay to account for the fact that the code works when print out all the elements of the array, but not when you don't. Seems sketchy.
             } else {
        	  twoCommasPresent = false;
            //      Serial.println("Two commas present, didnt parse");
                  
        	  //This will be where we handle the presence of twoCommas, since it means that the boat is doing something strange
        	  //AKA tilted two far, bad compass data
        	  //GPS can't locate satellites, lots of commas, no values.
              }
          
          digitalWrite(checksumBadLED,LOW);//checksum was bad if on, its not bad anymore
          
        } else {
       //     Serial.println("checksum not good...");// else statement and this line are only here for testing
            digitalWrite(checksumBadLED,HIGH);//checksum was bad, turn on indicator
            digitalWrite(goodCompassDataLED, LOW); //data is bad
        }
        //regardless of checksum, reset array to beginning and reset checksum
        j = -1;//this will start writing over the old data, need -1 because we add to j
        //should be fine how we parse presently to have old data tagged on the end,
        //but watch out if we change how we parse
        checksum=0;//set the xor checksum back to zero
        twoCommasPresent = false; // there isnt any data, so reset the twoCommasPresent
      } //end if we're at the end of the data
      
      else if (array[j] == '$') {//if we encounter $ its the start of new data, so restart the data
    //  Serial.println("found a $, restarting...");
        //if its not in the 0 position there's been an error so get rid of the data and start a new line anyways
        array[0] = '$'; //move the $ to the first character
        j = 0;//start at the first byte to fill the array
        checksum=0;//set the xor checksum back to zero
        xorState = 1;//start the Xoring for the checksum once a new $ character is found
        twoCommasPresent = false; // there isnt any data, so reset the twoCommasPresent
      } 
      else if (j > LONGEST_NMEA){//if over the maximum data size, there's been corrupted data so just start at 0 and wait for $
//        Serial.println("string too long, clearing some stuff");
        j = -1;//start at the first byte to fill the array
        // Serial2.flush(); //dont flush because there might be good data at the end
        checksum=0;//set the xor checksum back to zero
        xorState = 0;//only start the Xoring for the checksum once a new $ character is found, not here
        twoCommasPresent = false; // there isnt any data, so reset the twoCommasPresent
       
        digitalWrite(goodCompassDataLED,LOW);//turn on error indicator LED to warn about old data
      } 
      else if (array[j] == '*'){//if find a * within a reasonable length, stop XORing and wait for \n
        //could set a flag to stop XORing
      //  Serial.println("found a *");
        xorState = 0;
      } 
      else if (xorState) //for all other cases, xor unless it's after *
        checksum^=array[j];

      //removed this because it can be checked when a newline is encountered
      //else checksumFromNMEA=checksumFromNMEA*8+array[j];//something like this, keep shifting it up a character
     // Serial.println(array[j]/*,HEX*/);
      j++;
      
      //keep emptying buffer until it's empty; doing this should limit roll-over data
      if(device == 'c')
        dataAvailable = Serial2.available(); //check how many bytes are in the buffer
      else if (device == 'w')
        dataAvailable = Serial3.available(); //check how many bytes are in the buffer
    }//end loop, used to be from 0 to dataAvailable, now its while dataAvailable

//Jan 28, Christine:
//this is the part where the data is being messed up; extraWindDataArray isnt saving useful data, just 0's. Memory issue??? 
//Patch/fix: add in delay, so that partial data never wraps around and data is disgarded instead!

 //   Serial.print("end, 0 is:");
 //   Serial.println(array[0]);

    if ((j > 0) && (j < LONGEST_NMEA) && (twoCommasPresent==false)) { //this means that there was leftover data; set a flag and save the state globally

      if (device == 'w')
      {
        for (i = 0; i < j; i++)
          extraWindDataArray[i] = array[i]; //copy the leftover data into the temp global array
          extraWindData = j;
          savedWindChecksum=checksum;
          savedWindXorState=xorState;
      }
      else if (device == 'c')
      {
        for (i = 0; i < j; i++)
          extraCompassDataArray[i] = array[i];
          extraCompassData = j;
          savedCompassChecksum=checksum;
          savedCompassXorState=xorState;
      }

      
      // twoCommasPresent status isnt saved, since data isnt saved if it has two commas
 //     Serial.println("Stored extra data - ");
      digitalWrite(rolloverDataLED, HIGH); //indicates data rolled over, not fast enough
      
  //    Serial.print(extraWindData);
  //    Serial.print(",");
 //     Serial.print(extraWindDataArray[0],HEX);
 //     Serial.print(extraWindDataArray[1],HEX);
 //     Serial.print(extraWindDataArray[2],HEX);
  //    Serial.print(extraWindDataArray[3],HEX);      
    }
    else if (j > LONGEST_NMEA)
       digitalWrite(twoCommasLED, HIGH); //error light
    else 
      digitalWrite(rolloverDataLED, LOW); //indicates data didnt roll over
      
  }//end if theres data to parse
 

 
 /*  Serial.println(headingc);
   Serial.println(pitch);
   Serial.println(roll);
   Serial.println(PTNTHTM); */ 

//wind doesn't have a sample mode...
  if(device == 'c')
   Serial2.println("$PTNT,HTM*63"); //compass is in sample mode now; so request the next sample! :)
   
   return error;
}

void connectSensors(){
//this function loops for 1 minute,until we get a signal or it times out
//useful at the start of any program
//but this doesnt seem to have worked in testing or maybe it did and I lost xbee connection  
  int GPSerrors =0;
  int compassErrors = 0;
  int error;
  
  while(boatLocation.latDeg == 0 && GPSerrors < 600)
   {
     error = sensorData(BUFF_MAX,'w');
     delay(100);
     Serial.println("no gps data");
     GPSerrors++;
   }

  while(heading_newest == 0 && compassErrors < 600)
  {
      error = sensorData(BUFF_MAX,'c');  
      delay(100);
      Serial.println("no compass data");
      compassErrors++;
  }

  if (GPSerrors >= 600 || compassErrors >= 600){
    while(1)
    {
      Serial.println("Too many data errors, end of program (press reset to try again).");
      delay(1000);
    }  
  }
  
}


int Wind() 
{	//fill in code to get data from the serial port if availabile
//wind connects to serial1
//replace this with finished compass code
 int error = 0;

      //Uncomment a section to test it parsing that kind of command! (will print the global variables)
  //GPS testing:
  error = Parser("$GPGLL,4413.7075,N,07629.5199,W,192945,A,A*5E"); // this is returning 44.23  and -76.49; off by 0.1, 0.2?
 // Serial.println(latitude);//curent latitude
 // Serial.println(longitude); //Current longitude
  //Serial.println(GPSX); //Target X coordinate
  //Serial.println(GPSY); //Target Y coordinate
  //Serial.println(prevGPSX); //previous Target X coordinate
  //Serial.println(prevGPSY); //previous Target Y coordinate


 /* Heading angle using wind sensor testing:
  int error = Parser("$HCHDG,204.4,0.0,E,12.6,W*67"); //returning 204.4, 0.0, 12.6 - > good!
  Serial.println(heading);//heading relative to true north
  Serial.println(deviation);//deviation relative to true north; do we use this in our calculations?
  Serial.println(variance);//variance relative to true north; do we use this in our calculations?
 */

 /* Boat's speed testing:
  int error = Parser("$GPVTG,225.1,T,237.7,M,0.1,N,0.2,K,A*25"); //returning 0.20, 0.10 -> good I think? (which parameters are these)
  Serial.println(bspeed); //Boat's speed in km/h
  Serial.println(bspeedk); //Boat's speed in knots
  */
  
 /* Wind data testing:
  int error = Parser("$WIMWV,251.4,R,3.1,N,A*23"); //returning 251.40, 3.10 -> good~
  Serial.println(wind_angl);//wind angle, (relative to boat or north?)
  Serial.println( wind_velocity);//wind velocity in knots
 */
 
  /* Compass testing
  // The 75.9 is the dip angle; 2618 is the magnetic field ; http://www.google.ca/url?sa=t&source=web&cd=3&ved=0CCEQFjAC&url=http%3A%2F%2Fgpsd.googlecode.com%2Ffiles%2Ftruenorth-reference.pdf&ei=jLn-TLaTAtvtnQeE1KGgCw&usg=AFQjCNFKgSCpWdeEoXWtQQiYeHJYXeXQ-g; http://lists.berlios.de/pipermail/gpsd-dev/2006-October/004558.html
  int error = Parser("$PTNTHTM,71.3,N,-0.4,N,-1.4,N,75.9,2618*03"); //returning 71.30, -0.40, -1.40 -> good!
   Serial.println(headingc);
   Serial.println(pitch);
   Serial.println(roll);
   Serial.println(PTNTHTM);
   */	return error;
}
