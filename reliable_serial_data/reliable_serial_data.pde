//THis code hasn't been tested on the arduino yet; it should be compared to sailcode_alpha2 and 3, and to scanln

if ((dataAvailable = Serial.available()) > 126){ //the buffer has filled up; the data is likely corrupt;
//may need to reduce this number, as the buffer will still fill up as we read out data and dont want it to wraparound between here and when we get the data out
  Serial.flush(); //clear the serial buffer
  extraWindData = 0; //'clear' the extra data buffer, because any data wrapping around will be destroyed by clearing the buffer
  lostData=1;//set a global flag to indicate that the loop isnt running fast enough to keep ahead of the data
}
else {
  //first copy all the leftover data into array from the buffer
  for (i=0; i < extraWindData; i++)
    array[i] = extraWindDataArray[i];  //the extraWindData array was created the last time the buffer was emptied
  //probably actually don't need the second array

  //now continue filling array from the serial port
  j = extraWindData; //j is a counter for the number of bytes which have been stored but not parsed yet
  extraWindData = 0;//reset for the next time
  for (i=0; i< available; i++){//this loop empties the whole serial buffer, and parses every time there is a newline
    array[j] = Serial.read();
    
    if (array[j] == '\n' || array[j] == '\0'){     						 
      error = parser(array);
      j = -1;//this will start writing over the old data, need -1 because we add to j 
      			//should be fine how we parse presently to have old data tagged on the end, 
      			//but watch out if we change how we parse
    }
    else if (array[j] == '$' && j!=0){//if we encounter $ and its not in the 0 position there's been an error so get rid of the data and start a new line
    	array[0]='$'; //move the $ to the first character
    	j=0;//start at the first byte to fill the array
    }
    
    j++;
  }

  if (j>0){ //this means that there was leftover data; set a flag and put it into a temp global array
    for (i=0; i++; i<j)
      extraWindDataArray[i] = array[i]; //copy the leftover data into the temp global array   
    extraWindData = j;
  }
}



