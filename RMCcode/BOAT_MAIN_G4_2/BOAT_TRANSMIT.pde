

void transmit(void)
{
  Serial.print("###");
  //GPS
  Serial.print("LAT:");
  Serial.print(current_loc.lat/10,DEC);
  Serial.print(",LON:");
  Serial.print(current_loc.lng/10,DEC); //wp_current_lat
  Serial.print(",ALT:");
  Serial.print("0");
  Serial.print(",GPS:");
  Serial.print(GPSLOCK,BIN);
  Serial.print(",SPD:");
  Serial.print(ground_speed,2);
  //Wind Dirn and Vel
  Serial.print(",vwthetaBR:");
  Serial.print(vwthetaBR,2);
  Serial.print(",vwR:");
  Serial.print(vwR,2);
  Serial.print(",vwthetaT: ");
  Serial.print(vwthetaT,2);
  Serial.print(",vwT: ");
  Serial.print(vwT,2);
  //Accelerometer
  Serial.print(",TIL:");
  Serial.print(-compass.a.y*90/1024,2);
  Serial.print(",ROL:");
  Serial.print(compass.a.x*90/1024,2);//Actually is the waypoint.
  //Navigation
  Serial.print(",DMD:");
  Serial.print(dmode);  // current decision
  Serial.print(",WPT:");
  Serial.print(wp_index,DEC);  // current decision
  //Control
  Serial.print(",TAIL:");
  Serial.print(tail_out,DEC); 
  Serial.print(",CAM:");
  Serial.print(camber_out,DEC);
  Serial.print(",RUD:");
  Serial.print((int)rudder_out,DEC);
  Serial.print(",WORM:");
  Serial.print(worm_out,DEC);
  //What we are doing
  Serial.print(",brng: ");
  Serial.print(brng,2);
  Serial.print(",setPoint: ");
  Serial.print(pol2comp(setPoint),2);
  Serial.print(",vbthetaT: ");
  Serial.print(vbthetaT,2); 
  Serial.print(",SPOS: ");
  Serial.print(wing_pos,2);
  Serial.print(",WT: ");
  Serial.print(WINDTEST,DEC); 
  Serial.print(",T21: ");
  Serial.print((stnkeept2-stnkeept1)/1000,DEC);
  

  Serial.print(",BX: ");
  Serial.print(BXY[0],1); 
  Serial.print(",BY: ");
  Serial.print(BXY[1],1);                      
  Serial.println(",***");


  //Serial.print(",CRS:");    // compass not calibrated yet
  //Serial.print(headingValue/10,DEC);
  //Serial.print(",BTV:");
  //Serial.print(Lipo,DEC);


}

