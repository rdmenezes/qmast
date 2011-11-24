%last boats location
%list waypoints
%wind direction
%last velocity

%wind_angle is a an ANGLE
%windAngle is actually a vector (and a global)
%wind_Angle is a function that gets wind_angle using global windAngle
%(i fully realize how bad this is...)
%windDirn is a local variable commonly used to store windAngle
%wind_angle is also a common local for wind_angle
%getWindDirn is a function to get windDirn vector
%windAngle was also formally a local to sail??? but changed


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
global true false tacking setEndFlag;

global setrudder sailAngle
global MARK_DISTANCE
MARK_DISTANCE=1;
true=1;
false=0;
tacking=0;














%environment
wayPointList={[104,134],[600,2000]};

lastVel=[1,0]; %cant start from 0,0 so fix later cause lazy
headingc=[1,0]; %cant start from 0,0 so fix later cause lazy
windDir=[0,-1];
setEndFlag=0;

scatter(wayPointList{:})

hold on

here='top'
while(setEndFlag==0)
    
    sailCourse(boatLocation, wayPointList)
    
    
    pause(0.5)
    scatter(boatLocation(1),boatLocation(2),'MarkerFaceColor','r')
    
    
end

hold off

end


function result=between(boatHeading,windDirn)
here='between'

    angle=acosd(((boatHeading(1)*windDirn(1))+(boatHeading(2)*windDirn(2)))/(sqrt(boatHeading(1)^2+boatHeading(2)^2)*sqrt(windDirn(1)^2+windDirn(2)^2)));

    if(angle>45)
        result=0;
    else
        result=1;
    end

end

function result=dotAngle(a,b)
here='dotAngle'

    result=acosd(((a(1)*b(1))+(a(2)*b(2)))/(sqrt(a(1)^2+a(2)^2)*sqrt(b(1)^2+b(2)^2)));

end

function result=getWindDirn
here='getWindDirn'
    global windAngle;
    
    result=windAngle;

end


function sailCourse(boatLocation, coursePoints) 
    global setEndFlag MARK_DISTANCE;
    here='sailCourse'
    currentPoint=1;
    points=length(coursePoints);
    
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
here='GPSdistance'

    result=sqrt((destination(1)-currentLocation(1))^2+(destination(2)-currentLocation(2))^2);

end

function result=getWaypointDirn(boatLocation,destination)

    here='getWayPointDirn'

    distanceToWaypoint = GPSdistance(boatLocation, destination);

    result=[(destination(1)-boatLocation(1))/distanceToWaypoint,...
        (destination(2)-boatLocation(2))/distanceToWaypoint];

end


%given a waypoint
function result=sailToWaypoint(waypoint)
    global tacking boatLocation;

    here='sailToWaypoint'

    %// called to keep the gui up to date
    %distance = GPSdistance(boatLocation, waypoint);
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

    global headingc;
    
    here='sail'
    
    windDirn = getWindDirn();
    %// check if the waypoint's direction is between the wind and closehauled on
    %// either side (ie are we downwind?)
    if(between(waypointDirn, windDirn))
        %//*should* prevent boat from ever trying to sail upwind
        directionError = dotAngle(getCloseHauledDirn(), headingc);
    else 
        directionError = dotAngle(waypointDirn, headingc);
    end

    rudderControl(directionError);
    
    sailControl();
    
end

%was boolean
function result=checkTack(corridorHalfWidth, waypoint) 

    global headingc boatLocation;
    
    here='checkTack'

    windDirn = getWindDirn();
    waypointDirn=getWaypointDirn(boatLocation,windDirn);
    c=windDirn

    %// Checks if closehauled first. Done with trig. It's a right-angled triangle, where
    %// opp is the distance perpendicular to the wind angle (the number we're looking for)
    %// and theta is the angle between the wind and the waypoint directions; positive
    %// when windDirn > waypointDirn
        
    if(between(headingc, windDirn)) 
        waypointDirn = getWaypointDirn(waypoint);
        theta = acos(((waypointDirn(1)*windDirn(1))+(waypointDirn(2)*windDirn(2)))/(sqrt(waypointDirn(1)^2+waypointDirn(2)^2)*sqrt(windDirn(1)^2+windDirn(2)^2)));

        %// the hypotenuse is as long as the distance between the boat and the waypoint, in meters
        hypotenuse = GPSdistance(boatLocation, waypoint); %// latitude is Y, longitude X for waypoints
        distance = hypotenuse * sin(theta);
  
        %// check the direction of the wind so we only try to tack towards the mark
        if ( ((distance < 0) && (wind_angl > 180)) || ((distance > 0) && (wind_angl < 180))) 

            %//we're outside corridor
            if (abs(distance) > corridorHalfWidth)

                result=true;
                return
                %//if we're past the layline
            elseif(~between(waypointDirn, windDirn)) 

                result=true;
                return
            end
        end
    end
    result=false;
end






%/** This function controls the sails, proportional to the wind direction with no consideration for wind strength.
 %*/
function sailControl()

here='sailControl'
     global sailAngle
% 
%     wind_angle=wind_Angle;
% 
%     if (wind_angle > 180)           %// wind is from port side, but we dont care
%         windAngle = 360 - wind_angle;   %// set to 180 scale, dont care if it's on port or starboard right now,
%     else
%         windAngle = wind_angle;
%     end
% 
%     %//  If not in irons
%     if (windAngle > TACKING_ANGLE)
%         %// scale the range of winds from 40->180 (140 degree range) onto 0 to 100 controls;
%         %// 0 means all the way in
%         setSails( (windAngle-TACKING_ANGLE)*100/(180 - TACKING_ANGLE) );
%     else
%         setSails(ALL_IN);%// set sails all the way in, in irons
%     end
% 
%     %// if heeled over a lot (experimentally found that 40 was appropriate according to cory)
%     if (abs(roll) > 40)        
%         setMain(ALL_OUT); %// set sails all the way out, keep jibaX
%     end
    
    sailAngle=0;
    
end



%/** Controls the rudder movement, used to be part of sail.
% * but is moved to a seperate function so it is easier to modify
% *
% * @param[in] directionError This needs explanation.
% */
function rudderControl(directionError)
    
    here='rudderControl'
    
    global setrudder

    if (directionError < 0)
        directionError = directionError + 360;
    end

    %// rudder deadzone to avoid constant adjustments and oscillating, only change the rudder
    %// if there's a big error
    directionError > 10
    directionError < 350
    if  ((directionError > 10) && (directionError < 350)) 
        %//turn left, so send a negative to setRudder function
        if (directionError > 180) 
            %//adjust rudder proportional;
            setrudder=(directionError-360)/5;
        else
            %// adjust rudder proportional; setrudder accepts -30 to +30
            setrudder=(directionError/5);
        end
    else
        setrudder=0;%//set to neutral position
    end
    
    here='there'

end


function result=wind_Angle
    global windAngle headingc;
    
    here='wind_Angle'
    
    windDirn=[-windAngle(1) -windAngle(2)];
    
    result=acos(((headingc(1)*windDirn(1))+(headingc(2)*windDirn(2)))/(sqrt(headingc(1)^2+headingc(2)^2)*sqrt(windDirn(1)^2+windDirn(2)^2)));

end


function tack
    global tacking;
    
    here='tack'

    wind_angle=wind_Angle;

    if(tacking == false) 
        if(wind_angle > 180) 
            tackingSide = 1;
        else
            tackingSide = -1;
        end
    end
    

    tacking = true;
    %ironTime=ironTime+1;                  %//checks to see if turned far enough
%     if(ironTime > 200)           %//waits about 10 seconds to before assuming in irons
%         getOutofIrons(tackingSide);
%         inIrons = true;
%     end
    if(((wind_angle > 180) && (wind_angle < 310)) || ((wind_angle < 180) && (wind_angle > 50)))
        tackingSide = 0;
        dirn = getCloseHauledDirn();
        ironTime = 0;
        %inIrons = false;
    
    elseif((tacking == true)) %&& (inIrons == false)) %//tacks depending on the side the wind is aproaching from
        if(tackingSide == 1)        %//nested if statements
            if(wind_angl > 180) 
                sailControl()
                setRudder(-20);
            else
                sailControl();                  %//sets main and jib to allows better turning
                setRudder(-20);
            end      %//rudder angle cannot be too steep, this would stall the boat, rather than turn it
        end
        %//mirror for other side
        if(tackingSide == -1) 
            if(wind_angl < 180) 
                sailControl();
                setRudder(20);
            else
                sailControl();                    %//sets main and jib to allows better turning
                setRudder(20);
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

function setRudder(angle)
    global rudderAngle
    
    bins = [-30 -15 0 15 30];
    
    rudderAngle = interp1(bins,bins,angle,'nearest');
end

function setMain(angle)
    global mainAngle
    
    mainAngle = angle;
end

function simulate
    global boatLocation rudderAngle windAngle mainAngle velocity

    %Constants for first order simluation
    windConstant=10;
    dragConstant=5;
        
    boatLocation = boatLocation + velocity / framerate;
    velocity = velocity + ( (windConstant*dot(velocity,windAngle)/norm(velocity)) ...
    - dragConstant*velocity) / framerate; % First order approximation of acceleration
    % windAngle = 
 
end

function result=getCloseHauledDirn

here='getCloseHauledDirn'
%//find the compass heading that is close-hauled on the present tack
wind_angle=wind_Angle;

windHeading = getWindDirn(); %//compass bearing for the wind
%//determine which tack we're on
if (wind_angle > 180) %//wind from left side of boat first
    desiredDirection = windHeading + 45; %//bear off to the right
else
    desiredDirection = windHeading - 45; %//bear off to the left
end
    
if(desiredDirection < 0)
    desiredDirection =desiredDirection+ 360;
elseif(desiredDirection > 360)
    desiredDirection =desiredDirection- 360;
end

result=desiredDirection;

end


%//code to get out of irons if boat is stuck
%function getOutofIrons(tackside)

 %   setMain(ALL_OUT);
 %   setJib(ALL_IN);
%    setRudder(30*tackside);
%end
