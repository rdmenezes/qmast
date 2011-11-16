%last boats location
%list waypoints
%wind direction
%last velocity


%Things to do, add globals for tack etc.

%environment
%wayPointList={[104,134],[600,2000]}
%lastPos=[0,0]
%lastVel=[1,0] %cant start from 0,0 so fix later cause lazy
%windDir=[0,-1]

%system
%tacking
%tacking_angle

function MatlabSailLogic
global true false;
true=1;
false=0;


%environment
wayPointList={[104,134],[600,2000]};
lastPos=[0,0];
lastVel=[1,0]; %cant start from 0,0 so fix later cause lazy
windDir=[0,-1];



sailCourse(lastPos, wayPointList)






end


function result=between(boatHeading,windDirn)

    angle=acosd(((boatHeading(1)*windDirn(1))+(boatHeading(2)*windDirn(2)))/(sqrt(boatHeading(1)^2+boatHeading(2)^2)*sqrt(windDirn(1)^2+windDirn(2)^2)))

    if(angle>15)
        result=0;
    else
        result=1;
    end

end


function sailCourse(boatLocation, coursePoints) 

    currentPoint=1;
    
    %returns in meters
    distanceToWaypoint = GPSdistance(boatLocation, coursePoints{currentPoint});
    %sets the rudder, stays in corridor if sailing upwind
    sailToWaypoint(coursePoints{currentPoint});

    if (distanceToWaypoint < MARK_DISTANCE)
        currentPoint=currentPoint+1;
    end
    if (currentPoint > points) 
        setEndFlag=1;
    end
    
end

function result=GPSdistance(currentLocation,destination)


    result=sqr((destination(1)-currentLocation(1))^2+(destination(2)-currentLocation(2))^2)

end

function result=getWayPointDirn(boatLocation,waypoint)

    distanceToWaypoint = GPSdistance(boatLocation, waypoint);

    result=[(destination(1)-currentLocation(1))/distanceToWaypoint,...
        (destination(2)-currentLocation(2))/distanceToWaypoint];

end


%given a waypoint
function result=sailToWaypoint(waypoint)
    global tacking distance;


    %// called to keep the gui up to date
    distance = GPSdistance(boatLocation, waypoint);
    %// get the next waypoint's compass bearing; must be positive 0-360 heading;
    waypointDirn = getWaypointDirn(boatLocation,waypoint);

    %checks if it is already tacking, saves having to run checktack
    %tacking global
    if(tacking == true)
        tack();
        %checks if outside corridor and sailing into the wind
    elseif(checkTack(10, waypoint) == true)
        tack();
        %not facing upwind or inside corridor
    else
        %get the next waypoint's compass bearing, must be positive 0-360 heading
        sail(waypointDirn)
    end
end


function sail(waypointDirn)
    
    windDirn = getWindDirn();
    %// check if the waypoint's direction is between the wind and closehauled on
    %// either side (ie are we downwind?)
    if(between(waypointDirn, windDirn))
        %//*should* prevent boat from ever trying to sail upwind
        directionError = getCloseHauledDirn() - headingc;
    else 
        directionError = waypointDirn - headingc;
    end

    rudderControl(directionError);
    
    sailControl();
    
end

%was boolean
function result=checkTack(corridorHalfWidth, waypoint) 
    global distance;

    windDirn = getWindDirn();
    currentHeading = headingc;

    %// Checks if closehauled first. Done with trig. It's a right-angled triangle, where
    %// opp is the distance perpendicular to the wind angle (the number we're looking for)
    %// and theta is the angle between the wind and the waypoint directions; positive
    %// when windDirn > waypointDirn
    if(between(currentHeading,windDirn - TACKING_ANGLE, windDirn + TACKING_ANGLE)) 
        waypointDirn = getWaypointDirn(waypoint);
        theta = waypointDirn - windDirn;

        %// the hypotenuse is as long as the distance between the boat and the waypoint, in meters
        hypotenuse = GPSdistance(boatLocation, waypoint); %// latitude is Y, longitude X for waypoints
        distance = hypotenuse * sin(degreesToRadians(theta));

        %// check the direction of the wind so we only try to tack towards the mark
        if ( (distance < 0 && wind_angl > 180) || (distance > 0 && wind_angl < 180) ) 

            %//we're outside corridor
            if (abs(distance) > corridorHalfWidth)

                result=true;
                %//if we're past the layline
            elseif(stuff)%!between(waypointDirn, windDirn + TACKING_ANGLE, windDirn - TACKING_ANGLE)) 

                result=true;
            end
        end
    end
    result=false;
end






%/** This function controls the sails, proportional to the wind direction with no consideration for wind strength.
 %*/
function sailControl()

    if (wind_angl > 180)           %// wind is from port side, but we dont care
        windAngle = 360 - wind_angl;   %// set to 180 scale, dont care if it's on port or starboard right now,
    else
        windAngle = wind_angl;
    end

    %//  If not in irons
    if (windAngle > TACKING_ANGLE)
        %// scale the range of winds from 40->180 (140 degree range) onto 0 to 100 controls;
        %// 0 means all the way in
        setSails( (windAngle-TACKING_ANGLE)*100/(180 - TACKING_ANGLE) );
    else
        setSails(ALL_IN);%// set sails all the way in, in irons
    end

    %// if heeled over a lot (experimentally found that 40 was appropriate according to cory)
    if (abs(roll) > 40)        
        setMain(ALL_OUT); %// set sails all the way out, keep jibaX
    end
end



%/** Controls the rudder movement, used to be part of sail.
% * but is moved to a seperate function so it is easier to modify
% *
% * @param[in] directionError This needs explanation.
% */
function rudderControl(directionError)
    while (directionError < 0)
        directionError = directionError + 360;
    end

    %// rudder deadzone to avoid constant adjustments and oscillating, only change the rudder
    %// if there's a big error
    if  (directionError > 10 && directionError < 350) 
        %//turn left, so send a negative to setrudder function
        if (directionError > 180) 
            %//adjust rudder proportional;
            setrudder((directionError-360)/5);
        else
            %// adjust rudder proportional; setrudder accepts -30 to +30
            setrudder(directionError/5);
        end
    else
        setrudder(0);%//set to neutral position
    end

end



function tack
    global tacking;

    if(tacking == false) 
        if(wind_angl > 180) 
            tackingSide = 1;
        else
            tackingSide = -1;
        end
    end
    
    
    ironTime = 0;
    tacking = true;
    ironTime=ironTime+1;                  %//checks to see if turned far enough
    if(ironTime > 200)           %//waits about 10 seconds to before assuming in irons
        getOutofIrons(tackingSide);
        inIrons = true;
    end
    if(((wind_angl > 180) && (wind_angl < 360-TACKING_ANGLE-5)) || ((wind_angl < 180) && (wind_angl > TACKING_ANGLE+5)))          %//check to see if still trying to tack
        tacking = false;        %//resets variables
        tackingSide = 0;
        dirn = getCloseHauledDirn();
        ironTime = 0;
        inIrons = false;
    
    elseif(tacking == true && inIrons == false) %//tacks depending on the side the wind is aproaching from
        if(tackingSide == 1)        %//nested if statements
            if(wind_angl > 180) 
                setJib(ALL_OUT);
                setMain(ALL_IN);
                setrudder(-20);
            else
                setJib(ALL_IN);    
                setMain(ALL_OUT); %//sets main and jib to allows better turning               
                setrudder(-20);
            end      %//rudder angle cannot be too steep, this would stall the boat, rather than turn it
        end
        %//mirror for other side
        if(tackingSide == -1) 
            if(wind_angl < 180) 
                setJib(ALL_OUT);
                setMain(ALL_IN);
                setrudder(20);
            else
                setJib(ALL_IN); 
                setMain(ALL_OUT); %//sets main and jib to allows better turning                                   
                setrudder(20);
            end      %//rudder angle cannot be too steep, this would stall the boat, rather than turn it
        end
    end
end

%function tweet(message) % Once we have the authentication keys, someone
%should run twitpref once, save the resulting variables as a .mat file, and
%have MatlabSailLogic load that.  If twit doesn't get the authentication
%stuff passed to it as arguments, it looks for those variables.  Also,
%put that in a separate folder so it doesn't get uploaded to the
%publically-viewable Google code repository. 
%
%   [status, result] = twit(message) 
%            
%   if status
%       
%end

%//code to get out of irons if boat is stuck
%function getOutofIrons(tackside)

 %   setMain(ALL_OUT);
 %   setJib(ALL_IN);
%    setrudder(30*tackside);
%end