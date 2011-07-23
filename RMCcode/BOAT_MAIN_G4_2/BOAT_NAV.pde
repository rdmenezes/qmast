unsigned int UW = 45;    //degrees we can sail from upwind
unsigned int delta = 2;  //fuzzy conditions
char dmode = 'X';  //decision mode
float brngrad;     //beaing in rad
float dist;        //distance to target
float boatdist;    //distance from last wpt
float boattheta;   //angle from last wpt
float wptdist;     //wpt 2 wpt angle and dist
float wpttheta;

float brng;
float dx;


void boatlogic(void) {     //(vbtheta,bx,by,vw,vwtheta,wpx,wpy,k,bx1,by1)
  unsigned int dxset=60;        //change this to how far the boat can sail off course

  cart2pol(WPTXY[wp_index][0]-BXY[0],WPTXY[wp_index][1]-BXY[1],&dist,&brngrad); 
  //find the bearing and distance to target
  brng =brngrad*180/pi; 
//  Serial.println(brng,DEC);
//  Serial.print("BXY:");
//  Serial.print(BXY[0],DEC);
//  Serial.print(",");
//  Serial.println(BXY[1],DEC);
  
  //change to degrees
  if (brng < 0) {
    brng= brng+360; 
  }



  cart2pol(WPTXY[wp_index][0]-WPTXY[wp_index-1][0],WPTXY[wp_index][1]-WPTXY[wp_index-1][1],&wptdist,&wpttheta);    //find the wpt to wpt angle    //CHANGE THE WPX[k] & WPX[k-1]
  cart2pol(BXY[0]-WPTXY[wp_index-1][0],BXY[1]-WPTXY[wp_index-1][1],&boatdist,&boattheta);         //find the boat to last wpt angle and dist
  dx=sin(abs(boattheta-wpttheta))* boatdist;        //find the course normal distance


  if(abs(brng-vwthetaTP) > UW) {  //Sail a straight line if we are more than 30 deg to the wind    //this IF is in DEG
    vbtheta=brng;
    dmode = 'A';
  }
  else if (dx>dxset && boattheta-wpttheta >= 0) {    //Don't sail course normal farther than dxset // this IF is in RADIANS
    vbtheta = vwthetaTP-UW;
    dmode = 'B';
  }  
  else if (dx>dxset && boattheta-wpttheta < 0) {   
    vbtheta = vwthetaTP+UW;
    dmode = 'C';
  }  
  else if (vbthetaTP <= vwthetaTP+UW+delta && vbthetaTP >= vwthetaTP+UW-delta){ //If we are already sailing as far upwind as we can, stay that way
    vbtheta = vwthetaTP+UW;
    dmode = 'D';
  } 
  else if (vbthetaTP <= vwthetaTP-UW+delta && vbthetaTP >= vwthetaTP-UW-delta){
    vbtheta = vwthetaTP-UW; 
    dmode = 'E';
  }  
  else if (brng-vwthetaTP >= 0){ // if wind is to the right of the bearing, sail on left side of the wind
    vbtheta= vwthetaTP+UW;
    dmode = 'F';
  }  
  else if (brng-vwthetaTP < 0) {
    vbtheta = vwthetaTP-UW;
    ;// if wind is to the left of the bearing, sail on right side of the wind
    dmode = 'G';
  }  
  if (vbtheta < 0)
  {
    vbtheta = vbtheta + 360;  //vbtheta is in POLAR!
  }


}



void wptcheck(void)
{
  if (sqrt(pow(WPTXY[wp_index][0]-BXY[0],2)+pow(WPTXY[wp_index][1]-BXY[1],2)) <= 3)    //if we are withing 3 meters go 2 next wpt
  {
    wp_index++;
  }
  if (wp_index > wp_total)
  {
    wp_index = 0;    //return home if we've comlpeted all waypoints
  }
}


//StationKeeping Instructions
//Set first waypoint near the edge of the box
//Set a bunch of otherwayspoints across the box
//The boat will leave the box for home at stnkeepmins

void stationkeep(void)
{
  if (stnkeepON == 1)  // If we are running the station keeping
    {
      if ((stnkeep == 0) & (wp_index == 2)) // If we haven't already started the timer and we've reached the first waypoint
      {
        stnkeep = 1;
        stnkeept1 = millis();
        Serial.print("Time1");Serial.println(stnkeept1,DEC);
      }
      stnkeept2 = millis();
      if ((stnkeept2 - stnkeept1 >= stnkeepsec*1000) & (stnkeep == 1)) //If we've started the timer and the time is greater than 5minutes
      {
        wp_index = 0;
      }
    }
}

