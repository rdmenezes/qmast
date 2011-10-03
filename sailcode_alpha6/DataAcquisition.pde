/** This file polls input from the compass and wind sensor, and more.
 *
 * sensorData replaces Compass() and Wind() with one function.
 *
 * This file contains a couple other supporting functions, but most of the
 * work is performed by this function. This function takes care of pulling
 * the NMEA Sentences from the Serial Buffer, and performing a checksum
 *
 * This function is actually doing a lot of things at once and would be
 * better suited to being broken down into many smaller functions.
 *
 * @param[in] bufferLength Will vary based on the device being used
 * @param[in] device Specify the device being used through a character code
 *
 * @note
 * 'c' = compass
 * 'w' = wind sensor
 * The wind sensor is connected to Serial3
 * The compass is connected to Serial2
 */
void sensorData(int bufferLength, char device) {
    // The number of bytes are available on the serial port
    int dataAvailable;
    /* Array to hold data from serial port before parsing;
     * (2*longest) might be too long and inefficient */
    char array[LONGEST_NMEA];

    char checksum;    // Computed checksum for the NMEA data between $ and *
    char endCheckSum; // The HEX checksum that is added by the NMEA device
    int xorState;     // Holds the XOR  state (whether to use the next data in
    // the xor checksum) from global
    int j;            // j is a counter for the number of bytes which have been
    // stored but not parsed yet
    int i;            // counter

    int error;        // Error flag for parser
    /* If there are two commas present, strtok will choke on the delimiters
     * bool variable will cause sentence to be dropped later on */
    bool twoCommasPresent = false;

    if(device == 'c') {
        dataAvailable = Serial2.available(); // check how many bytes are in the buffer
    } else if(device == 'w') {
        dataAvailable = Serial3.available(); // check how many bytes are in the buffer
    }

    if(!dataAvailable) {
        // Set a global flag that there's no data in the buffer; either the loop is
        // running too fast or theres something broken
        setErrorBit(noDataBit);
        setErrorBit(badCompassDataBit);
    } else {
        clearErrorBit(oldDataBit);
        clearErrorBit(noDataBit);
        if (dataAvailable > bufferLength) {
            /*The buffer has filled up; the data is likely corrupt;
            * We may need to reduce this number, as the buffer will still fill up
            * as we read out data and don't want it to wraparound between here an
            * when we get the data out */
            setErrorBit(oldDataBit);
            setErrorBit(badCompassDataBit);
            // Flushing data is probably not the best; the data will not be corrupt
            // since the port blocks, it will just be old, so accept it.
            // Serial.flush();    // clear the serial buffer
            // extraWindData = 0; // 'clear' the extra data buffer, because any data wrapping
            // around will be destroyed by clearing the buffer
            // savedChecksum=0;   // clear the saved XOR value
            // savedXorState=0;   // clear the saved XORstate value
            // lostData = 1;      // set a global flag to indicate that the loop
            // isnt running fast enough to keep ahead of the data

            // Serial.println("You filled the buffer, data old. ");
        } // End dataAvailible if statement

        // This has to depend on if it's wind or compass, and
        // different arrays for them!
        if(device == 'w') {
            for (i = 0; i < extraWindData; i++) {
                /* the extraWindData array was created the last time the buffer was
                 * emptied probably actually don't need the second global array
                 */
                array[i] = extraWindDataArray[i];
            }
        } else if (device == 'c') {
            for (i = 0; i < extraCompassData; i++) {
                /* the extraWindData array was created the last time the buffer was
                 * emptied probably actually don't need the second global array
                 */
                array[i] = extraCompassDataArray[i];
            }
        }

        //now continue filling array from the serial port

        if(device == 'w') {
            // set the xor error checksum to the saved value (only xor if between $
            // and *)
            checksum = savedWindChecksum;
            // set the XOR state (whether to use the next data in the xor checksum)
            // from global
            xorState = savedWindXorState;
            // j is a counter for the number of bytes which have been stored but not
            // parsed yet
            j = extraWindData;
            //reset for the next time, in case there isn't any extraData; could
            //optimize these variable declarations
            extraWindData = 0;
            savedWindChecksum = 0; // reset for next time
            savedWindXorState = 0; // reset for next time
        } else if (device == 'c') {
            checksum = savedCompassChecksum;
            xorState = savedCompassXorState;
            j = extraCompassData;
            extraCompassData = 0;
            savedCompassChecksum = 0;
            savedCompassXorState = 0;
        }

        // This loop empties the whole serial buffer, and parses every time there
        // is a newline
        while(dataAvailable) {
            if(device == 'c')
                array[j] = Serial2.read();
            else  if(device == 'w')
                array[j] = Serial3.read();

//      Serial.print(array[j]);
            if (j > 0) {
                if (array[j] == ',' && array[j-1] == ',') {
                    twoCommasPresent = true;
                    setErrorBit(badCompassDataBit);
                    setErrorBit(twoCommasBit);
                }
            } else {
                clearErrorBit(badCompassDataBit);
                clearErrorBit(twoCommasBit);
            }

            /* Check the size of the array before bothering with the checksum
            * if you're not getting here and using serial monitor, make sure
            * to select newline from the line ending drop down near the baud rate
            * Serial.print("read slash n, checksum is:  ");
            * compass strings seem to end with *<checksum>\r\n (carriage return,
            * linefeed = 0x0D, 0x0A) so there's an extra j index between the two
            * checksum values (j-3, j-2) and the current j.
            * just skip over it when checking the checksum */
            if ((array[j] == '\n') && j > SHORTEST_NMEA) {
                // calculate the checksum by converting from the ASCII to HEX
                endCheckSum = (convertASCIItoHex(array[j-3]) << 4) \
                              | convertASCIItoHex(array[j-2]);

                // Serial.print(endCheckSum,HEX);
                // Serial.print("  , checksum calculated is  ");
                // Serial.println(checksum,HEX);

                // check the XOR before bothering to parse; if its ok,
                // reset the xor and parse, reset j
                if (checksum==endCheckSum) {
                    // since hex values only take 4 bits, shift the more significant
                    // half to the left by 4 bits, the bitwise or it with the least
                    // significant half then check if this value matches the
                    // calculated checksum (this part has been tested and should work)

                    // Serial.println("checksum good, parsing.");

                    // Before parsing the valid string, check to see if the string
                    // contains two consecutive commas as indicated by the
                    // twoCommasPresent flag
                    if (!twoCommasPresent) {
                        // print first character (should be $)
                        // Serial.println(array[0]);

                        // append the end of string character
                        array[j+1] = '\0';
                        clearErrorBit(twoCommasBit);

                        // Serial.println("Good string, about to parse");
                        error = Parser(array); //checksum was successful, so parse
                    } else {
                        twoCommasPresent = false;
                        // Serial.println("Two commas present, didnt parse");

                        // This will be where we handle the presence of twoCommas,
                        // since it means that the boat is doing something strange
                        // AKA tilted two far, bad compass data
                        // GPS can't locate satellites, lots of commas, no values.
                    }
                    clearErrorBit(checksumBadBit);
                } else {
                    setErrorBit(checksumBadBit);
                    setErrorBit(badCompassDataBit);
                }
                // regardless of checksum, reset array to beginning and reset
                // checksum
                // this will start writing over the old data, need -1 because we
                // add to j
                j = -1;
                // should be fine how we parse presently to have old data tagged on
                // the end,
                // but watch out if we change how we parse
                checksum=0; //set the xor checksum back to zero
                // there isnt any data, so reset the twoCommasPresent
                twoCommasPresent = false;
                // end if we're at the end of the data
            } else if (array[j] == '$') {
                // if we encounter $ its the start of new data, so restart the data

                //  Serial.println("found a $, restarting...");

                // if its not in the 0 position there's been an error so get rid
                // of the data and start a new line anyways
                array[0] = '$'; // move the $ to the first character
                j = 0;          // start at the first byte to fill the array
                checksum=0;     // set the xor checksum back to zero
                // start the Xoring for the checksum once a
                // new $ character is found
                xorState = 1;
                // there isnt any data, so reset the twoCommasPresent
                twoCommasPresent = false;
            } else if (j > LONGEST_NMEA) {
                //if over the maximum data size, there's been corrupted data so just
                //start at 0 and wait for $
//	        	Serial.println("string too long, clearing some stuff");

                j = -1;//start at the first byte to fill the array
                // Serial2.flush(); //dont flush because there might be good data at the end
                checksum=0;//set the xor checksum back to zero
                xorState = 0;//only start the Xoring for the checksum once a new $ character is found, not here
                twoCommasPresent = false; // there isnt any data, so reset the twoCommasPresent
                setErrorBit(badCompassDataBit);
            } else if (array[j] == '*') { //if find a * within a reasonable length, stop XORing and wait for \n
                //could set a flag to stop XORing
                //  Serial.println("found a *");
                xorState = 0;
            } else if (xorState) //for all other cases, xor unless it's after *
                checksum^=array[j];

            //removed this because it can be checked when a newline is encountered
            //else checksumFromNMEA=checksumFromNMEA*8+array[j];//something like this, keep shifting it up a character
            j++;

            //keep emptying buffer until it's empty; doing this should limit roll-over data
            if(device == 'c')
                dataAvailable = Serial2.available(); //check how many bytes are in the buffer
            else if (device == 'w')
                dataAvailable = Serial3.available(); //check how many bytes are in the buffer
        }//end loop, used to be from 0 to dataAvailable, now its while dataAvailable

//   Serial.print("end, 0 is:");
//   Serial.println(array[0]);

        if ((j > 0) && (j < LONGEST_NMEA) && (twoCommasPresent==false)) { //this means that there was leftover data; set a flag and save the state globally

            if (device == 'w') {
                for (i = 0; i < j; i++)
                    extraWindDataArray[i] = array[i]; //copy the leftover data into the temp global array
                extraWindData = j;
                savedWindChecksum=checksum;
                savedWindXorState=xorState;
            } else if (device == 'c') {
                for (i = 0; i < j; i++)
                    extraCompassDataArray[i] = array[i];
                extraCompassData = j;
                savedCompassChecksum=checksum;
                savedCompassXorState=xorState;
            }
            setErrorBit(rolloverDataBit);
        }
        // twoCommasPresent status isnt saved, since data isnt saved if it has two commas
        else if (j > LONGEST_NMEA) {
            setErrorBit(twoCommasBit);
        } else {
            clearErrorBit(rolloverDataBit);
        }

    }//end if theres data to parse

    if(device == 'c')
        Serial2.println("$PTNT,HTM*63"); //compass is in sample mode now; so request the next sample! :)
}
void setErrorBit(int aBit) {

    bitSet(errorCode,aBit);    //sets an error bit in the error code
}

void clearErrorBit(int aBit) {

    bitClear(errorCode,aBit);
}

int checkErrorBit(int aBit) {
    int result;
    int mask = 1 << aBit; //start with bit 0 (rightmost) as 1 and shift left by variable bit
    //now we have one bit that is 1 in the correct location
    result = mask & errorCode;
    if (result == 0) {
        return 0;//the bit is not set
    } else {
        return 1;//the bit is set
    }
}


