//for stationkpeeing, do we want to call this function? probably
//- could tack() as we switch waypoints?
//- different simpler function to turn 180 beam reach?
//- tacking radius needs to be checked so that we dont leave the box

#define MINSPEED 2 //CB the minimum speed that the boat needs to be travelling to tack
// this will depend on the present wind speed; I made up 2 (is this fast?)

#define ERROR_SPEED 2; //error code 2 means that the boat wasnt going fast enough

void tack(float bspeed, float wind_angl, float speedUpDirection)
{
       int tackComplete = 0;
       int newData;
       int count = 0;
       float startingWindAngl = wind_angl; //keep track of which side the wind started on
       

       //we should store which side the wind is coming from at the start of the tacking loop,
       //and not exit until we've switched sides

       while(tackComplete == 0) // keep working until tack is completed
       {
               while (bspeed < MINSPEED)
               {
                      //have a timer to fail, this is 5 seconds right now (50); this needs work
                       count++;
                       if (count > 50)
                         return ERROR_SPEED;
                         
                       sailControl();
                       sailStraight(speedUpDirection); // direction before tack
                       delay(100);
                       newData = sensorData(BUFF_MAX, 'w'); //get new boat speed
                       //CB calling sensorData this frequently, it wont have a new boat speed every time; but that should be ok
                       //the only issue might be if we interupt a data sentence in the middle;
                      // will have to test this to see if the delay is too short

               }

               newData = sensorData(BUFF_MAX, 'w');
               //CB data's checksum is checked as it arrives; it would be reasonable to check the speed

               if (wind_angl < 180)
               {
                       setsails(0); // CHRISTINE what angle for left tack? //CB all in is -30, left and right are the same for sail control
                       setrudder(-45); // CHECK IF NEG OR POS FOR LEFT TACK
                       while(wind_angl <180 && boatspeed > MINSPEED)
                       {
                               delay(100); // how long of a delay between sensor updates?
                               newData = sensorData(BUFF_MAX, 'w');
                       }
                       if(bspeed < MINSPEED){
                               Setsails(-30);
                               SailControl();
                               sailStraight(speedUpDirection); // bear off
                       }

                       delay(1000); //wait to make sure tack completed
                       sailStraight(????); // bear off
                       newData = sensorData(BUFF_MAX, 'w');

                       if(wind_angl > 180 && bspeed > MINSPEED)
                       {
                               tackComplete = 1;
                       }
               }

               else if (windAngle >180)
               {
                       setsails(0);
                       setrudder(45);
                       while(wind_angl > 180 && boatspeed > MINSPEED)
                       {
                               delay(100);
                               newData = sensorData(BUFF_MAX, 'w');
                       }
                       if(bspeed == 0){
                               Setsails(-30);
                               SailControl();
                               sailStraight(speedUpDirection);
                       }

                       delay(1000);
                       newData = sensorData(BUFF_MAX, 'w');

                       if(wind_angle < 180 && bspeed > MINSPEED)
                               tackComplete = 1;
               }
       }
       SailControl(); //make sure this is called outside this function
}
