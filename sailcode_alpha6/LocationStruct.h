//Place to put all structs inorder to allow for passing and returning of structs from functions.
//structs placed inside the main program can not be returned or passed to functions

struct points{
  double latDeg;            //degree of latitude
  double latMin;            //minute of latitude
  double lonDeg;            //degree of longitude
  double lonMin;            //minute of longitude
};            
 //struct for holding course waypoints 
 
points waypoints[10] ={        //optional preset values for registers
  {44.0,13.6927,-76.0,-29.5175},       //note both degrees and minutes must have the right sign in order for manipulation of gps data to work
  {0,0,0,0}, 
  {0,0,0,0}};
  //initialization of struct, put default coordinates here
  
points stationPoints[4];      //possible additional structures for stationkeeping and 
                              //course plotting
points floatingStationPoints[4];  //plot for points within the stationkeeping square                              
points coursePoints[10];  

points clearPoints = {        //generic empty struct, use for clearing other structs
  0,0,0,0};

points boatLocation;        // boats current location, 

points stayPoint; //used in stationkeeping
