//Utilities

float degreesToRadians(int angle) {
    return PI*angle/180.0;
}


int radiansToDegrees(float angle) {
    return 180*angle/PI;
}

boolean between(int angle, int a, int b) {
    //figures out if angle is between a and b on a circular scale

//first ensure angles are 0 to 360 normalized
    while (angle < 0)
        angle+= 360;
    while (angle >= 360)
        angle-= 360;

    while (a < 0)
        a+= 360;
    while (a >= 360)
        a-= 360;

    while (b < 0)
        b+= 360;
    while (b >= 360)
        b-= 360;


    //now check which boundary condition is higher and then determine if angle is between a and b, either on the inside or outside
    if (a < b) { //b is bigger
        if ((b - a) < 180) //check if the range numerically between a and b is smaller than the range numerically outside of a and b
            return a <= angle && angle <= b; //small angle is between a and b
        else //angle either has to be bigger than both bounds (b to 360) or smaller than both bounds (a to 0)
            return (a <= angle && b <= angle) || (angle <= a && angle <=b); //small angle is outside a and b, either on the left or right side of zero
    } else { //a is the bigger number, same as above with a switched for b
        if ((a - b) < 180)
            return b <= angle && angle <= a;
        else
            return (b <= angle && a <= angle) || (angle <= b && angle <=a);
    }
}

//from reliable serial data merge
//adapted from http://forum.sparkfun.com/viewtopic.php?f=17&t=9570
//(all of our checksums have numbers or capital letters so no worries about the UTIL_TOUPPER)
char convertASCIItoHex (const char ch) {
    if(ch >= '0' && ch <= '9')
        // if it's an ASCII number
    {
        return (ch - '0'); //subtract ASCII 0 value to get the hex value
    } else
        // if its a letter (assumed upper case)
    {
        return ((ch - 'A') + 10);//subtract ASCII A value then add 10 to get the hex value
    }
}
