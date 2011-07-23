void cart2pol(float x,float y,float *r,float *theta)
{
  *r = sqrt(pow(x,2)+pow(y,2));
  *theta = atan2(y,x);//check this
}

void  pol2cart(float *x, float *y, float r, float theta)
{
  *x= r*cos(theta);
  *y= r*sin(theta);
}

float comp2pol(float comp)    //convert compass values from instruments to polar values 
{
  float pol;
  pol = comp*-1 + 90;
  if (pol < 0) {
    pol = pol + 360; }
  return pol;
}

float pol2comp(float pol)   //polar to compass
{
  float comp;
  comp = (pol-90)*(-1);
  if (comp < 0){
    comp = comp +360; }
  return comp;
}
  
void convertC2P(void)      //take all the measured readings and make them polar
{
  vbthetaTP = comp2pol(vbthetaT);
  vbthetaMP = comp2pol(vbthetaM);
  vwthetaTP = comp2pol(vwthetaT);
}
  
  
