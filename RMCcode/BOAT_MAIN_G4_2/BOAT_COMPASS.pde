LSM303DLH compass;

void init_compass(void)
{
  
  Wire.begin();
  compass.enable();
  //compass.m_max.x = +540; compass.m_max.y = +500; compass.m_max.z = 180;
  //compass.m_min.x = -520; compass.m_min.y = -570; compass.m_min.z = -770;
}



void getCompassData(void)
{
   compass.read();
   // X is roll   compass.a.x
   // Y is pitch  compass.a.y
   //Comp_heading = compass.heading((vector){0,-1,0});
}
