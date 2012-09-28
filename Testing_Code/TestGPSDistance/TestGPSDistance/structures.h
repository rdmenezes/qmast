struct points{
  double latDeg;            //degree of latitude
  double latMin;            //minute of latitude
  double lonDeg;            //degree of longitude
  double lonMin;            //minute of longitude
};            
 //struct for holding course waypoints 
 
points waypoints[10] ={        //optional preset values for registers
  {44.0, 13.5687, -76.0, -29.3879}, //south lampost
  {44.0, 13.5743, -76.0, -29.3735}, //middle tree
  {44.0, 12.6238, -76.0, -48.9558}, // dirt pit
  {44.0, 22.8678, -76.0, -49.2078}}; // top of parking lot
  //initialization of struct, put default coordinates here
  
points stationPoints[4];      //possible additional structures for stationkeeping and 
                              //course plotting
points floatingStationPoints[4];  //plot for points within the stationkeeping square                              
points coursePoints[10]={        //optional preset values for registers
  {44.0, 13.6803, -76.0, -29.5175}, //south lampost
  {44.0, 13.6927, -76.0, -29.5351}, //middle tree
  {44.0, 13.7067, -76.0, -29.4847}, // dirt pit
  {44.0, 13.7207, -76.0, -29.5247}};  //top of parking lot

points clearPoints = {        //generic empty struct, use for clearing other structs
  0,0,0,0};

points boatLocation = {44.0, 13.5687, -76.0, -29.3879};        // boats current location, 
//middle lamp post

//GPGLL,4413.6803,N,07629.5175,W,232409,A,A*58 south lamp post
 //GPGLL,4413.6927,N,07629.5351,W,230533,A,A*51 middle tree by door
 //GPGLL,4413.7067,N,07629.4847,W,232037,A,A*53 NW corner of the dirt pit by white house
 //GPGLL,4413.7139,N,07629.5007,W,231721,A,A*57 middle lamp post
 //GPGLL,4413.7207,N,07629.5247,W,231234,A,A*5E at the top of the parking lot/bay ramp, where the edging and sidewalk end
 
 
// 44.228689
//-76.492070
//
//44.228655
//-76.491622  //actual gps for end of sidewalk and lampost


  // there are (approximately) 1855 meters in a minute of latitude; this isn't true for longitude, as it depends on the latitude
  //there are approximately 1314 m in a minute of longitude at 45 degrees north; this difference will mean that if we just use deltax over deltay in minutes to find an angle it will be wrong
  //possible systemic error from the way the gps parses coordinates, coordinates are currently off by a couple kilometers but degrees are right, entire string may be in degrees will need to go and 
  //test if it is a single systemic error from a shitty gps or if theer is alway an offset of this amount i which case we can fix it.
