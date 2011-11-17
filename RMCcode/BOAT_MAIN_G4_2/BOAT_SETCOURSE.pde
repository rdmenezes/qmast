//function [wpx wpy] = SetCourse(bx,by,tx,ty,tSP)
//% this should set NW waypoints at CPAdist around the markers.. We want to sail around the markers, not through them so we set these waypoitns around.

void setcourse(void)
{



  float CPAdist=6; //%Closets Point of Approach *not actually
  short int NW=3;       //%Number of Waypoints around a marker
  float A[wp_total+1];
  float B[wp_total+1];
  float brng;
  float brngrad;
  float dist;
  float x[NW];
  float y[NW];
  float angle;
  float r[2];
  float theta[2];
  float CPAbrng[NW];

  //anaylze incidence and exit angles at each marker
  for (int k=1; k<= wp_total; k++)
  {
    cart2pol(WPTXY[k][0]-WPTXY[k-1][0],WPTXY[k][1]-WPTXY[k-1][1],&r[0],&theta[0]);
    cart2pol(WPTXY[k+1][0]-WPTXY[k][0],WPTXY[k+1][1]-WPTXY[k][1],&r[1],&theta[1]); //incident course - outgoing course
    angle = theta[0]-theta[1];

    A[k]= angle*180/pi; //Total turning angle of the boat on Starbord buoys
    if (A[k]<0) {
      A[k]=A[k]+360; 
    }
    //Serial.print("angle ");
    //Serial.println(A[k]);
    B[k]=360-A[k];  //Total turning angle of the boat on port buoys
  }


  for (int i=1;i<=wp_total;i++)
  {
    cart2pol(WPTXY[i][0]-WPTXY[i-1][0],WPTXY[i][1]-WPTXY[i-1][1],&dist,&brngrad);
    brng = brngrad*180/pi;  //change to degrees
    Serial.print("brng:");
    Serial.println(brng);

    if (i<wp_total)
    {
      if (WPTturn == 0)              //Turn Port
      {
        CPAbrng[0]=brng-90;
        if (CPAbrng[0]<0) {
          CPAbrng[0]=CPAbrng[0]+360; 
        }
        for (int j=1;j<NW;j++)
        {
          CPAbrng[j]=CPAbrng[j-1] + B[i]/(NW-1);
        }
      }
      else
      {
        CPAbrng[0]=brng+90;     //Turn Starboard
        if (CPAbrng[0]<0) {
          CPAbrng[0]=CPAbrng[0]+360; 
        }
        for (int j=1;j<NW;j++)
        {
          CPAbrng[j]=CPAbrng[j-1] - A[i]/(NW-1);
        }
      }
    }
    else if(i==wp_total)
    {
      //sail through the last waypoint

      CPAbrng[0]=brng;
      for (int j=1;j<NW;j++)
      {
        CPAbrng[j]=brng; //fill the other ones even if we dont need to
      }
    }

    for (int j=0;j<NW;j++)
    {
      pol2cart(&x[j],&y[j],CPAdist,CPAbrng[j]*pi/180);
      //Serial.print( x[j]);Serial.print(",");Serial.println(y[j]);
    }
      //Serial.print(x[0]);Serial.print(",");Serial.println(y[0]);
    if (i < wp_total)
    {
      for (int j=0; j<NW; j++)
      {
        wptxy[wpsub_total][0]=WPTXY[i][0]+x[j];
        wptxy[wpsub_total][1]=WPTXY[i][1]+y[j];
        wpsub_total++;
      }
    }
    else
    {
      wptxy[wpsub_total][0]=WPTXY[i][0]+x[0];    //Sail through the final waypoint
      wptxy[wpsub_total][1]=WPTXY[i][1]+y[0];
      wpsub_total++;
    }
  }
  Serial.print("N ");
  Serial.println(wpsub_total,DEC);

  for (int j=0; j<wpsub_total; j++)
  {

    Serial.print("subWXY #, ");
    Serial.print(j,DEC);
    Serial.print(",");
    Serial.print(wptxy[j][0],DEC);
    //Serial.print(WPTXY[1][0],DEC);
    Serial.print(",");
    Serial.println(wptxy[j][1],DEC);
  }
}



