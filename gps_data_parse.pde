 //GPS String
  if (strcmp(str1, "$GPGLL") == 0) 
  {
    //     ,3354.4970,N,11759.5354,W,025604,V,S*52 lat/lon; V(a=valid, v=invalid)
    //     0 1 2 3 4 5 6 7

    sscanf(val, "$%5s,%f,%c,%f,%c,%d,%c,", str, &lat_deg_nmea, &lat_dir,
    &lon_deg_nmea, &lon_dir, &hms, &valid);

    //check 'valid' before continuing; throw error code if not valid
    if (valid == 'V')
      return 1; 

    //     lat_deg is in the format ddmm.mmmm 

    //this first moves the decimal so that the latitude degrees is the whole part of the number
    //then modf returns the integer portion to 'grades' and the fractional (minutes) to 'frac'.
    frac = modf(lat_deg_nmea / 100.0, &grades); 
    // Frac is out of 60, not 100, since it's in minutes; so convert to a normal decimal
    lat = (double) (grades + frac * 100.0 / 60.0) * (lat_dir == 'S' ? -1.0    : 1.0); // change the sign of latitude based on if it's north/south

    //do the same for longitude
    frac = modf(lon_deg_nmea / 100.0, &grades);
    lon = (double) (grades + frac * 100.0 / 60.0) * (lon_dir == 'W' ? -1.0 : 1.0);

    /*print("The string: %s\n", str);
     printf("Lat_dir nmea: %f\n", lat_deg_nmea);
     printf("Lat: %f\n", lon1);
     printf("Lat_dir: %c\n", lon_dir);*/

    latitude = latitude + lat; //cb! dont we want a moving average? 
    longitude = longitude + lon;        
    GPGLL++;
  }

  //Wind sensor compass
  if (strcmp(str1, "$HCHDG") == 0) 
  {
    sscanf(val, "$%5s,%f,%f,%c,%f,%c,", str, &head_deg, &dev_deg, &dev_dir, &var_deg, &var_dir);

    /*                printf("The string: %s\n", str);
     printf("Heading: %f\n", head_deg);
     printf("Dev: %f\n", dev_deg);
     printf("Dev dir: %c\n", dev_dir);
     printf("Var: %f\n", var_deg);
     printf("Var dir: %c\n", var_dir);*/

    heading = heading + head_deg; //cb! dont we want a moving average?
    deviation = deviation + dev_deg; //what is this in compass terminology? I think we should be taking dev_dir into account
    variance = variance + var_deg; //what is this in compass terminology? I think we should be taking var_dir into account
    HCHDG++;
  }

  //Wind speed and wind direction
  if (strcmp(str1, "$WIMWV") == 0) 
  {
    sscanf(val, "$%5s,%f,%c,%f,%c,%c,", str, &wind_ang, &wind_ref,&wind_vel, &speed_unit, &valid);
    //    printf("Wing angle: %f\n", wind_ang);

    //check 'valid' before continuing; throw error code if not valid
    if (valid == 'V')
      return 1; 

    //wind_ref for the PB100 is always R? (relative to boat)
    //speed unit for the PB100 is always N? (knots)
    wind_angl = wind_angl + wind_ang; //cb! dont we want a moving average?
    wind_velocity = wind_velocity + wind_vel;
    WIMWV++;
  }

  //Boat's speed
  if (strcmp(str1, "$GPVTG") == 0) 
  {
    //Add sscanf
    sscanf(val, "$%5s,%f,%c,%f,%c,%f,%c,%f,%c", str, &cov_true, &ref_true,&cov_meg, &ref_meg, &sov_knot, &ref_knot, &sov_kmh, &ref_kmh,&valid);
    //    printf("True course made good over ground: %f\n", sov_kmh);

    //check 'valid' before continuing; throw error code if not valid
    if (valid == 'V')
      return 1; 

    //cov_true is the actual course the boat has been travelling in; ref_true = T this is relative to true north
    //meg_true is the actual course the boat has been travelling in; ref_true = M this is relative to magnetic north
    //ref_knot is always N to indicate knots
    //ref_kmh is always K to indicate kilometers

    bspeed += sov_kmh; //cb! dont we want a moving average?
    bspeedk += sov_knot;
    GPVTG++;
  }
