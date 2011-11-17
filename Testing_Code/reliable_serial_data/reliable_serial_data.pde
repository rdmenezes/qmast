//This code hasn't been tested on the arduino yet; it should be compared to sailcode_alpha2 and 3, and to scanln
#define SHORTEST_NMEA 5
#define LONGEST_NMEA 120

//!!!!when testing by sending strings through the serial monitor, you need to select "newline" ending from the dropdown beside the baud rate

// what's the shortest possible data string?
int		extraWindData = 0; //'clear' the extra global data buffer, because any data wrapping around will be destroyed by clearing the buffer
int		savedChecksum=0;//clear the global saved XOR value
int		savedXorState=0;//clear the global saved XORstate value
int		lostData = 1;//set a global flag to indicate that the loop isnt running fast enough to keep ahead of the data
int 		noData =1; // global flag to indicate serial buffer was empty
char 		extraWindDataArray[LONGEST_NMEA]; // a buffer to store roll-over data in case this data is fetched mid-line


int parser(char * array)
{
  return 0;
}

void setup()
{
  Serial.begin(9600);
}

void loop() {
  int dataAvailable; // how many bytes are available on the serial port
  char array[LONGEST_NMEA];//array to hold data from serial port before parsing; 2* longest might be too long and inefficient

  char checksum; //computed checksum for the NMEA data between $ and *

  int xorState; //holds the XOR  state (whether to use the next data in the xor checksum) from global
  int j; //j is a counter for the number of bytes which have been stored but not parsed yet

  int i; //counter

  int error;//error flag for parser
  bool twoCommasPresent = false; //Alright, this flag will be set if the data being read in has two commas in a row. This is needed since
  	  	  	  	  	  	  	  	 //it will crash the program as strtok will have trouble with the delimiters later.

    delay(5000);

  if ((dataAvailable = Serial.available()) > 126) { //the buffer has filled up; the data is likely corrupt;
    //may need to reduce this number, as the buffer will still fill up as we read out data and dont want it to wraparound between here an
    //when we get the data out
      Serial.flush(); //clear the serial buffer
    extraWindData = 0; //'clear' the extra data buffer, because any data wrapping around will be destroyed by clearing the buffer
    savedChecksum=0;//clear the saved XOR value
    savedXorState=0;//clear the saved XORstate value
    lostData = 1;//set a global flag to indicate that the loop isn't running fast enough to keep ahead of the data
    Serial.print("You filled the buffer. ");
  }
  else if(!dataAvailable){
    noData = 1;//set a global flag that there's no data in the buffer; either the loop is running too fast or theres something broken
    Serial.print("No data available. ");
  } 
  else {
    Serial.print("There is data! ");
    //first copy all the leftover data into array from the buffer
    for (i = 0; i < extraWindData; i++){
      array[i] = extraWindDataArray[i]; //the extraWindData array was created the last time the buffer was emptied
      //probably actually don't need the second global array
    }

    //now continue filling array from the serial port
    checksum = savedChecksum;//set the xor error checksum to the saved value (only xor if between $ and *)
    xorState = savedXorState;//set the XOR state (whether to use the next data in the xor checksum) from global
    j = extraWindData; //j is a counter for the number of bytes which have been stored but not parsed yet

    extraWindData = 0;//reset for the next time, in case there isn't any extraData; could optimize these variable declarations
    savedChecksum = 0;//reset for the next time
    savedXorState = 0;//reset for next time

    for (i = 0; i < dataAvailable; i++) {//this loop empties the whole serial buffer, and parses every time there is a newline
      array[j] = Serial.read();
      
      	if (j > 0) {
      		if (array[j] == ',' && array[j-1] == ',') {
      			twoCommasPresent = true;
      		}
      	}

        if ((array[j] == '\n' || array[j] == '\0') && j > SHORTEST_NMEA) {//check the size of the array before bothering with the checksum
        //if you're not getting here and using serial monitor, make sure to select newline from the line ending dropdown near the baud rate
        Serial.println("read newline/null character, about to check checksum.");
        //check the XOR before bothering to parse; if its ok, reset the xor and parse, reset j
        if (checksum==(( convertASCIItoHex(array[j-2]) << 4) | convertASCIItoHex(array[j-1]) )){
        //since hex values only take 4 bits, shift the more significant half to the left by 4 bits, the bitwise or it with the least significant half
        //then check if this value matches the calculated checksum (this part has been tested and should work)
          Serial.println("checksum is good, I'm parsing.");

          //Before parsing the valid string, check to see if the string contains two consecutive commas as indicated by the twoCommasPresent flag
          if (!twoCommasPresent) {
          	  error = parser(array); //checksum was successful, so parse
          } else {
        	  twoCommasPresent = false;
        	  //This will be where we handle the presence of twoCommas, since it means that the boat is doing something strange
        	  //AKA tilted two far, bad compass data
        	  //GPS can't locate satellites, lots of commas, no values.
          }

        }
        else
        Serial.println("checksum was not good...");// else statement and this line are only here for testing
        
        //regardless of checksum, reset array to beginning and reset checksum
        j = -1;//this will start writing over the old data, need -1 because we add to j
        //should be fine how we parse presently to have old data tagged on the end,
        //but watch out if we change how we parse
        checksum=0;//set the xor checksum back to zero
      } 
      else if (array[j] == '$') {//if we encounter $ its the start of new data, so restart the data
      Serial.println("found a $, restarting...");
        //if its not in the 0 position there's been an error so get rid of the data and start a new line anyways
        array[0] = '$'; //move the $ to the first character
        j = 0;//start at the first byte to fill the array
        checksum=0;//set the xor checksum back to zero
        xorState = 1;//start the Xoring for the checksum once a new $ character is found
      } 
      else if (j > LONGEST_NMEA){//if over the maximum data size, there's been corrupted data so just start at 0 and wait for $
      Serial.println("string too long, clearing some stuff");
        j = -1;//start at the first byte to fill the array
        //We should flush the buffer here
        Serial.flush();
        checksum=0;//set the xor checksum back to zero
        xorState = 0;//only start the Xoring for the checksum once a new $ character is found, not here
      } 
      else if (array[j] == '*'){//if find a * within a reasonable length, stop XORing and wait for \n
        //could set a flag to stop XORing
        Serial.println("found a *");
        xorState = 0;
      } 
      else if (xorState) //for all other cases, xor unless it's after *
        checksum^=array[j];

      //removed this because it can be checked when a newline is encountered
      //else checksumFromNMEA=checksumFromNMEA*8+array[j];//something like this, keep shifting it up a character
      Serial.println(array[j]);
      j++;
      
      
    }//end loop from 0 to dataAvailable

    if (j > 0 && j < LONGEST_NMEA) { //this means that there was leftover data; set a flag and save the state globally
      for (i = 0; i++; i < j)
        extraWindDataArray[i] = array[i]; //copy the leftover data into the temp global array
      extraWindData = j;
      savedChecksum=checksum;
      savedXorState=xorState;
    }
  }//end if theres data to parse
 
}//end loop

//adapted from http://forum.sparkfun.com/viewtopic.php?f=17&t=9570
//(all of our checksums have numbers or capital letters so no worries about the UTIL_TOUPPER)
char convertASCIItoHex (const char ch)
{
       if(ch >= '0' && ch <= '9')
       // if it's an ASCII number 
       {
         return ch - '0'; //subtract ASCII 0 value to get the hex value
       }
       else
       // if its a letter (assumed upper case)
       {
         return (ch - 'A') + 10;//subtract ASCII A value then add 10 to get the hex value
       }
}

