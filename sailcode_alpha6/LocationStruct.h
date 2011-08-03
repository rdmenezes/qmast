//Place to put all structs inorder to allow for passing and returning of structs from functions.
//structs placed inside the main program can not be returned or passed to functions

struct points{
  double latDeg;            //degree of latitude
  double latMin;            //minute of latitude
  double lonDeg;            //degree of longitude
  double lonMin;            //minute of longitude
};            
 //struct for holding course waypoints 
 
points waypoints[10] = {        //optional preset values for registers
  {44.0,13.6927,-76.0,-29.5175},       //note both degrees and minutes must have the right sign in order for manipulation of gps data to work
  {38.0,58.9443,-76.0,-28.7383}, 
  {38.0,58.9515,-76.0,-28.7127}};
  //initialization of struct, put default coordinates here
  
points stationPoints[4];      //possible additional structures for stationkeeping and 
                              //course plotting
points floatingStationPoints[4];  //plot for points within the stationkeeping square                              
points coursePoints[10] = {
 {0,0,0,0},
 {0,0,0,0},
 {0,0,0,0},
 {0,0,0,0},
 {0,0,0,0},
 {0,0,0,0},
 {0,0,0,0},
 {0,0,0,0},
 {0,0,0,0}};  

points clearPoints = {        //generic empty struct, use for clearing other structs
  0,0,0,0};

points boatLocation;        // boats current location, 

points stayPoint; //used in stationkeeping

 //GPGLL,4413.6803,N,07629.5175,W,232409,A,A*58 south lamp post
 //GPGLL,4413.6927,N,07629.5351,W,230533,A,A*51 middle tree by door
 //GPGLL,4413.7067,N,07629.4847,W,232037,A,A*53 NW corner of the dirt pit by white house
 //GPGLL,4413.7139,N,07629.5007,W,231721,A,A*57 middle lamp post
 //GPGLL,4413.7207,N,07629.5247,W,231234,A,A*5E at the top of the parking lot/bay ramp, where the edging and sidewalk end

