


float boatlogicSUB(void) {     //(vbtheta,bx,by,vw,vwtheta,wpx,wpy,k,bx1,by1)
  unsigned int dxset=60;        //change this to how far the boat can sail off course

  cart2pol(wptxy[wp_index][0]-BXY[0],wptxy[wp_index][1]-BXY[1],&dist,&brngrad); 
  //find the bearing and distance to target
  brng =brngrad*180/pi;  
  //change to degrees
  if (brng < 0) {
    brng= brng+360; 
  }
  /*
  Serial.println(brng,DEC);
  Serial.print("BXY:,");
  Serial.print(BXY[0],DEC);
  Serial.print(",");
  Serial.println(BXY[1],DEC);
  */


  cart2pol(wptxy[wp_index][0]-wptxy[wp_index-1][0],wptxy[wp_index][1]-wptxy[wp_index-1][1],&wptdist,&wpttheta);    //find the wpt to wpt angle    //CHANGE THE WPX[k] & WPX[k-1]
  cart2pol(BXY[0]-wptxy[wp_index-1][0],BXY[1]-wptxy[wp_index-1][1],&boatdist,&boattheta);         //find the boat to last wpt angle and dist
  dx=sin(abs(boattheta-wpttheta))* boatdist;        //find the course normal distance


  if(abs(brng-vwthetaTP) > UW) {  //Sail a straight line if we are more than 30 deg to the wind    //this IF is in DEG
    vbtheta=brng;
    dmode = 'A';
  }
  else if (dx>dxset && boattheta-wpttheta >= 0) {    //Don't sail course normal farther than dxset // this IF is in RADIANS
    vbtheta = vwtheta-UW;
    dmode = 'B';
  }  
  else if (dx>dxset && boattheta-wpttheta < 0) {   
    vbtheta = vwthetaTP+UW;
    dmode = 'C';
  }  
  else if (vbthetaTP <= vwthetaTP+UW+delta && vbtheta >= vwthetaTP+UW-delta){ //If we are already sailing as far upwind as we can, stay that way
    vbtheta = vwthetaTP+UW;
    dmode = 'D';
  } 
  else if (vbthetaTP <= vwthetaTP-UW+delta && vbtheta >= vwthetaTP-UW-delta){
    vbtheta = vwthetaTP-UW;  
    dmode = 'E';
  }  
  else if (brng-vwtheta >= 0){ // if wind is to the right of the bearing, sail on left side of the wind
    vbtheta= vwthetaTP+UW; 
    dmode = 'F';
  }  
  else if (brng-vwtheta < 0) {
    vbtheta = vwthetaTP-UW;// if wind is to the left of the bearing, sail on right side of the wind
    dmode = 'G';
  }  
  if (vbtheta < 0)
  {
    vbtheta = vbtheta + 360;
  }
  return vbtheta;
}



void wptchecksub(void)
{
  if (sqrt(pow(wptxy[wp_index][0]-BXY[0],2)+pow(wptxy[wp_index][0]-BXY[0],2)) <= 3)    //if we are withing 4 meters go 2 next wpt
  {
    wp_index++;
  }
  if (wp_index > wpsub_total)
  {
    wp_index = 0;    //return home if we've comlpeted all waypoints
  }
}

