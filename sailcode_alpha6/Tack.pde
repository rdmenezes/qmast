//early tacking code, simpler than the unimplemented version for testing
//Jib has to be let out at the beginning of turning, this exert a moment on the boat allowing for faster turning,
//after turned halfway, pull jib in and let main out, again faster turning, speed should not be an issue, not much required in order to turn
//should still check if in iron, if so let main out, turn rudder to one side, when angle is no longer closehauled
//try sailing again,

void tack() {

    static int newData = 0;
    int dirn;
    boolean inIrons = false;

    if(tacking == false) {
        if(wind_angl > 180) {
            tackingSide = 1;
        } else
            tackingSide = -1;
    }
    Serial.println("tacking........");
    tacking = true;
    ironTime++;                  //checks to see if turned far enough
    if(ironTime > 200) {          //waits about 10 seconds to before assuming in irons
        getOutofIrons(tackingSide);
        inIrons = true;
    }
    if(((wind_angl > 180) && (wind_angl < 360-TACKING_ANGLE-5)) || ((wind_angl < 180) && (wind_angl > TACKING_ANGLE+5))) {         //check to see if still trying to tack
        tacking = false;        //resets variables
        tackingSide = 0;
        dirn = getCloseHauledDirn();
        ironTime = 0;
        inIrons = false;
        Serial.println("done tacking");
    } else if(tacking == true && inIrons == false) {   //tacks depending on the side the wind is aproaching from
        if(tackingSide == 1) {       //nested if statements
            if(wind_angl > 180) {
                setJib(ALL_OUT);
                setMain(ALL_IN);
                setrudder(-20);
            } else {
                setMain(ALL_OUT);
                setJib(ALL_IN);                    //sets main and jib to allows better turning
                setrudder(-20);
            }      //rudder angle cannot be too steep, this would stall the boat, rather than turn it
        }
        //mirror for other side
        if(tackingSide == -1) {
            if(wind_angl < 180) {
                setJib(ALL_OUT);
                setMain(ALL_IN);
                setrudder(20);
            } else {
                setMain(ALL_OUT);
                setJib(ALL_IN);                    //sets main and jib to allows better turning
                setrudder(20);
            }      //rudder angle cannot be too steep, this would stall the boat, rather than turn it
        }
    }
}

//code to get out of irons if boat is stuck
void getOutofIrons(int tackside) {
    int dirn;

    setMain(ALL_OUT);
    setJib(ALL_IN);
    setrudder(30*tackside);
}


