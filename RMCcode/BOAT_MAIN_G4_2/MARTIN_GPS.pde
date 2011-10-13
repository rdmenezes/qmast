
/* DEGTORAD is the degree to radian factor */
#define DEGTORAD 0.0174532925
// representation of GPS corrdinate DDMM.mmmm using only integers
//struct gps_int_t {
//	short int deg;
//	short int min;
//	short int decimin1;
//	short int decimin2;
//};

// prototypes
void gps_str_to_int(char*, struct gps_int_t* );
void gps_int_to_float(struct gps_int_t*, struct gps_int_t*, float*);
void gps_rel_pos(struct gps_int_t*, struct gps_int_t*, float*);

// takes a DDMM.mmmm GPS coordinate and returns it in gps_int_t struct split: DD, MM, mm, mm
void gps_str_to_int(char *gps_char, struct gps_int_t *gps_int)    // Jordan's Parsing Function, Martin's didn't work
{
int temp1, temp2;
int temp3;
char *brkbJ;
tokenTempJ = strtok_r(gps_char, ".", &brkbJ);
temp1 = atoi(tokenTempJ);
//temp1 = atoi(&gps_char[0]);

//tokenTempJ[0] = strtok_r(NULL, ".", &brkb);

//Serial.print("Temp1:" );Serial.println(temp1);

(*gps_int).deg = temp1/100;
(*gps_int).min = temp1-(temp1/100)*100;

tokenTempJ = strtok_r(NULL, ".", &brkbJ);

temp2 = atoi(tokenTempJ);
//temp2 = atoi(&gps_char[5]);
//Serial.print("Temp2:");Serial.println(temp2);
/*
if(tokenTempJ[0]==0){//There was a leading zero
  temp3=atoi(tokenTempJ);
(*gps_int).decimin1 =(int) temp3/100;
(*gps_int).decimin2 =(int)(temp3-(*gps_int).decimin1/100)*10000;
}
temp3=atoi(tokenTempJ);
Serial.print(".Token:");Serial.println("."+tokenTempJ);
Serial.print("Temp3:");Serial.println(temp3);
(*gps_int).decimin1 =(int) temp3*100;
(*gps_int).decimin2 =(int)(temp3-(*gps_int).decimin1/100)*10000;
Serial.print("Decimin1:");Serial.println((*gps_int).decimin1);
Serial.print("Decimin2:");Serial.println((*gps_int).decimin2);
*/
(*gps_int).decimin1 = temp2/100;
(*gps_int).decimin2 = temp2-(temp2/100)*100;
}



//gives the position of coordinate 2 with respect to coordinate 1 in polar(d,theta), with theta=0 equal to N
void gps_rel_pos(struct gps_int_t pos1_int[], struct gps_int_t pos2_int[], float relposxy[])    
{
float latitude[3], longitude[3]; /*will contain lat/long 1, 2 and delta(2-1) */
float earth_radius, distance, theta, h;
earth_radius = 6372000.;
gps_int_to_float(&pos1_int[0], &pos2_int[0], &latitude[0]);
gps_int_to_float(&pos1_int[1], &pos2_int[1], &longitude[0]);
relposxy[0]=-1.*earth_radius*longitude[2]*DEGTORAD*cos(latitude[0]*DEGTORAD); //assumed west
relposxy[1]=earth_radius*latitude[2]*DEGTORAD;                                //assumed north

}


//takes 2 gps coordinate in integer format and outputs in float degree coordinate 1, 2 and the delta (2-1)
void gps_int_to_float(struct gps_int_t *gps1, struct gps_int_t *gps2, float gpsf[])  //Martin's Difference Function, Jordan's didn't work
{
long minint1, dminint1, minint2, dminint2, deltamin, deltadeci, delta;
minint1 = (*gps1).deg*60 + (*gps1).min;
dminint1 = (*gps1).decimin1*100 + (*gps1).decimin2;
minint2 = (*gps2).deg*60 + (*gps2).min;
dminint2 = (*gps2).decimin1*100 + (*gps2).decimin2;
deltamin = minint2 - minint1;
deltadeci = (dminint2 - dminint1) + deltamin*10000; //difference in 10000th of minutes
gpsf[0] = (float)minint1/60. + (float)dminint1/600000.;
gpsf[1] = (float)minint2/60. + (float)dminint2/600000.;
gpsf[2] = (float)deltadeci/600000.; //difference in degress
//printf("Floating: %f %f %f\n",gpsf[0],gpsf[1],gpsf[2]);
}



