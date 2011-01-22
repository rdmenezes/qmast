if (dataAvailable = Serial.available() > 126){ //the buffer has filled up; the data is likely corrupt;
//may need to reduce this number, as the buffer will still fill up as we read out data and dont want it to wraparound between here and when we get the data out
  Serial.flush(); //clear the serial buffer
  extraWindData = 0; //'clear' the extra data buffer, because any data wrapping around will be destroyed by clearing the buffer
}
else {
  j = 0;
  //first copy all the leftover data into array from the buffer
  for (i=0; i < extraWindData; i++)
    array[j] = extraWindDataArray[j];  
  extraWindData = 0;

  //now continue filling array from the serial port
  for (i=0; i< available; i++){//this loop empties the whole serial buffer, and parses every time there is a newline
    array[j] = Serial.read();
    if (array[j] = '\n' || '\0'){
      error = parser(array);
      j = 0;
    }
    j++;
  }

  if (j>1){ //this means that there was leftover data; set a flag and put it into a temp global array
    for (i=0; i++; i<j)
      extraWindDataArray[i] = array[i]; //copy the leftover data into the temp array   
    extraWindData = j;
  }
}



