//Place to put all structs inorder to allow for passing and returning of structs from functions.

struct points{
  double latDeg;
  double latMin;
  double lonDeg;
  double lonMin;
};            
 //struct for holding course waypoints 
 
points waypoints[10] ={        //optional preset values for registers
  {44.0,13.6927,-76.0,29.5175}, 
  {0,0,0,0}, 
  {0,0,0,0}};
  //initialization of struct, put default coordinates here
  
points stationPoints[4];      //possible additional structures for stationkeeping and 
                              //course plotting
points coursePoints[10];  
