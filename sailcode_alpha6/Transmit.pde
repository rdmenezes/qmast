void transmit(void)
{
  int boatLat;
  int boatLon;
  boatLat = boatLocation.latDeg*100000+boatLocation.latMin*10000/0.6;
  boatLat = boatLocation.lonDeg*100000+boatLocation.lonMin*10000/0.6;
  Serial.print("###");
  //GPS
  Serial.print("LAT:");
  Serial.print(boatLat,DEC);
  Serial.print("LON:");
  Serial.print(boatLon,DEC); //wp_current_lat
  Serial.print("ALT:");
  Serial.print("0");
  Serial.print("GPS:");
  Serial.print("1");
  Serial.print("SPD:");
  Serial.print(bspeed,2);
  //Wind Dirn and Vel
  Serial.print("vwthetaBR:");
  Serial.print(wind_angl,2);
  Serial.print("vwR:");
  Serial.print(wind_velocity,2);
  //Accelerometer
  Serial.print("ROL:");
  Serial.print(roll);
  //Navigation
//  Serial.print(dmode);  // current decision
  Serial.print("WPT:");
  Serial.print(currentPoint,DEC);  // current decision
  //Control
  Serial.print("MAIN:");
  Serial.print(mainVal,DEC); 
  Serial.print("JIB:");
  Serial.print(jibVal,DEC);
  Serial.print("RUD:");
  Serial.print(rudderVal,DEC);
  //What we are doing
  Serial.print("vbthetaT: ");
  Serial.print(headingc,2);
  Serial.print("setPoint: ");
  Serial.print(headingVal,2);
  
  Serial.print("TAK:");
  Serial.print(tacking,DEC);
  Serial.print("SID:");
  Serial.print(tackingSide,DEC);
  Serial.print("IRON:");
  Serial.print(ironTime,DEC);
//  Serial.print(",WT: ");
//  Serial.print(WINDTEST,DEC); 
//  Serial.print(",T21: ");
//  Serial.print((stnkeept2-stnkeept1)/1000,DEC);
  
//  Serial.print(",BX: ");
//  Serial.print(BXY[0],1); 
//  Serial.print(",BY: ");
//  Serial.print(BXY[1],1);                      
//  Serial.println(",***");

  //Serial.print(",CRS:");    // compass not calibrated yet
  //Serial.print(headingValue/10,DEC);
  //Serial.print(",BTV:");
  //Serial.print(Lipo,DEC);

  Serial.print("***");
}
