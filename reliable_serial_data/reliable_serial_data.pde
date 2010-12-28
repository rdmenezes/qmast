//This code hasn't been tested on the arduino yet; it should be compared to sailcode_alpha2 and 3, and to scanln
#define SHORTEST_NMEA 5
#define LONGEST_NMEA 120
// what's the shortest possible data string?

void loop() {
	if ((dataAvailable = Serial.available()) > 126) { //the buffer has filled up; the data is likely corrupt;
	//may need to reduce this number, as the buffer will still fill up as we read out data and dont want it to wraparound between here and when we get the data out
		Serial.flush(); //clear the serial buffer
		extraWindData = 0; //'clear' the extra data buffer, because any data wrapping around will be destroyed by clearing the buffer
		savedChecksum=0;//clear the saved XOR value
		savedXorState=0;//clear the saved XORstate value
		lostData = 1;//set a global flag to indicate that the loop isnt running fast enough to keep ahead of the data
	}
	else if(!dataAvailable)
		noData = 1;//set a global flag that there's no data in the buffer; either the loop is running too fast or theres something broken
	else {
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

			if ((array[j] == '\n' || array[j] == '\0') && j > SHORTEST_NMEA) {//check the size of the array before bothering with the checksum

				//check the XOR before bothering to parse; if its ok, reset the xor and parse, reset j
				if (checksum==((array[j-2] << 4) | array[j-1])) //may have to do some type conversions here
					error = parser(array); //checksum was successful, so parse

				//regardless of checksum, reset array to beginning and reset checksum
				j = -1;//this will start writing over the old data, need -1 because we add to j
									//should be fine how we parse presently to have old data tagged on the end,
									//but watch out if we change how we parse
				checksum=0;//set the xor checksum back to zero
			} else if (array[j] == '$') {//if we encounter $ its the start of new data, so restart the data
				//if its not in the 0 position there's been an error so get rid of the data and start a new line anyways
				array[0] = '$'; //move the $ to the first character
				j = 0;//start at the first byte to fill the array
				checksum=0;//set the xor checksum back to zero
				xorState = 1;//start the Xoring for the checksum once a new $ character is found
			} else if (j > LONGEST_NMEA){//if over the maximum data size, there's been corrupted data so just start at 0 and wait for $
				j = -1;//start at the first byte to fill the array
				checksum=0;//set the xor checksum back to zero
				xorState = 0;//only start the Xoring for the checksum once a new $ character is found, not here
			} else if (array[j] == '*'){//if find a * within a reasonable length, stop XORing and wait for \n
				//could set a flag to stop XORing
				xorState = 0;
			} else if (xorState) //for all other cases, xor unless it's after *
				checksum^=array[j];

			//removed this because it can be checked when a newline is encountered
			//else checksumFromNMEA=checksumFromNMEA*8+array[j];//something like this, keep shifting it up a character

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
