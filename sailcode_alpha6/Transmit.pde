void transmit(void)
{
  long boatLat;
  long boatLon;
  boatLat = boatLocation.latDeg*1000000+boatLocation.latMin*10000/0.6;
  boatLon = boatLocation.lonDeg*1000000+boatLocation.lonMin*10000/0.6;
  Serial.print("###");
  //GPS
  Serial.print("LAT:");
  Serial.print(boatLat,DEC);
  Serial.print("LON:");
  Serial.print(boatLon,DEC); //wp_current_lat
  Serial.print("SPD:");
  Serial.print(bspeed,2);
  //Wind Dirn and Vel
  Serial.print("vwthetaBR:");
  Serial.print(wind_angl,2);
  Serial.print("vwthetaT:");
  Serial.print(trueWind,2);
  Serial.print("vwR:");
  Serial.print(wind_velocity,2);
  //Accelerometer
  Serial.print("ROL:");
  Serial.print(roll);
  //Navigation
  //Control
  Serial.print("MAIN:");
  Serial.print(mainVal,DEC); 
  Serial.print("JIB:");
  Serial.print(jibVal,DEC);
  Serial.print("RUD:");
  Serial.print(rudderVal,DEC);
  //What we are doing
  Serial.print("vbthetaT:");
  Serial.print(headingc,2);
  Serial.print("setPoint:");
  Serial.print(headingVal,2);

  //tacking
  Serial.print("TAK:");
  Serial.print(tacking,BIN);
  Serial.print("SID:");
  Serial.print(tackingSide,DEC);
  Serial.print("IRON:");
  Serial.print(ironTime,DEC);
  Serial.print(",DMD:");
  Serial.print(distanceVal);  // current distance
  Serial.print(",ERR:');
  Serial.print(errorCode);
  Serial.print("***");
}

void relayData(){//sends data to shore

  Serial.println(millis());
 //send data to zigbee
 Serial.println();
 Serial.print(boatLocation.latDeg);
 Serial.print(","); 
 Serial.print(boatLocation.latMin);
 Serial.print(",");
 Serial.print(boatLocation.lonDeg); //latitude and longitude of boat's location, split into more precise degrees and minutes, to fit into a float
 Serial.print(",");
 Serial.print(boatLocation.lonMin);
 Serial.print(",");
 Serial.print(bspeed); //boat speed 
 Serial.print(",");
 Serial.print(heading);  //boat direction
 Serial.print(",");
 Serial.print(wind_angl);  //wind angle, (relative to boat or north?)
 Serial.print(",");
 Serial.print(wind_velocity);//wind velocity in knots
 Serial.print(",");
 Serial.println(headingc);//compass 
}
