// adapted from Twitter Code http://www.ladyada.net

/***********************SOFTWARE UART*************************/

uint8_t serialavail_timeout(int timeout) {  // in ms

  while (timeout) {
    if (mySerial.available()) {
      if (XPORT_CTSPIN) { // we read some stuff, time to stop!
        digitalWrite(XPORT_CTSPIN, HIGH);
      }
      return 1;
    }
    // nothing in the queue, tell it to send something
    if (XPORT_CTSPIN) {
      digitalWrite(XPORT_CTSPIN, LOW);
    }
    timeout -= 1;
    delay(1);
  }
  if (XPORT_CTSPIN) { // we may need to process some stuff, so stop now
    digitalWrite(XPORT_CTSPIN, HIGH);
  }
  return 0;
}

uint8_t readline_timeout(int timeout) {
  uint8_t idx=0;
  char c;
  while (serialavail_timeout(timeout)) {
    c = mySerial.read();
    linebuffer[idx++] = c;
    if ((c == '\n') || (idx == 255)) {
      linebuffer[idx] = 0;
      errno = ERROR_NONE;
      return idx;
    }
  }
  linebuffer[idx] = 0;
  errno = ERROR_TIMEDOUT;
  return idx;
}

/********************XPORT STUFF**********************/

uint8_t XPort_reset(void) {
  char d;

  // 200 ms reset pulse

  delay(200);
  digitalWrite(XPORT_RESETPIN, HIGH);

  // wait for 'D' for disconnected
  if (serialavail_timeout(20000)) { // 20 second timeout 
    d = mySerial.read();
    //putstring("Read: "); Serial.print(d, HEX);
    if (d != 'D'){
      return ERROR_BADRESP;
    } 
    else {
      return 0;
    }
  }
  return ERROR_TIMEDOUT;
}  

uint8_t XPort_disconnected(void) {
  if (XPORT_DTRPIN != 0) {
    return digitalRead(XPORT_DTRPIN);
  } 
  return 0;
}


uint8_t XPort_connect(char *ipaddr, long port) {
  char ret;

  mySerial.print('C');
  mySerial.print(ipaddr);
  mySerial.print('/');
  mySerial.println(port);
  // wait for 'C'
  if (serialavail_timeout(5000)) { // 5 second timeout 
    ret = mySerial.read();
    putstring("Read: "); 
    Serial.print(ret, HEX);
    if (ret != 'C') {
      return ERROR_BADRESP;
    }
  } 
  else { 
    return ERROR_TIMEDOUT; 
  }
  return 0;
}

void XPort_flush(int timeout) {
  while (serialavail_timeout(timeout)) {
    mySerial.read();
  }
}

/********************TWITTER STUFF**********************/

uint8_t posttweet(char *tweet) {
  uint8_t ret=0;
  uint8_t success = 0;

  analogWrite(COMMLED,72); // light comm status light dimly
  ret = XPort_reset();
  //Serial.print("Ret: "); Serial.print(ret, HEX);
  switch (ret) {
  case  ERROR_TIMEDOUT: 
    { 
      blinkLED(COMMLED,4,500);
      putstring_nl("Timed out on reset! Check XPort config & IP"); 
      return 0;
    }
  case ERROR_BADRESP:  
    { 
      blinkLED(COMMLED,6,500);
      putstring_nl("Bad response on reset!");
      return 0;
    }
  case ERROR_NONE: 
    { 
      putstring_nl("Reset OK!");
      break;
    }
  default:
    blinkLED(COMMLED,8,500);
    putstring_nl("unknown error"); 
    return 0;
  }

  // time to connect...

  ret = XPort_connect(IPADDR, PORT);
  switch (ret) {
  case  ERROR_TIMEDOUT: 
    { 
      blinkLED(COMMLED,10,500);
      putstring_nl("Timed out on connect"); 
      return 0;
    }
  case ERROR_BADRESP:  
    { 
      blinkLED(COMMLED,12,500);
      putstring_nl("Failed to connect");
      return 0;
    }
  case ERROR_NONE: 
    { 
      putstring_nl("Connected..."); 
      break;
    }
  default:
    blinkLED(COMMLED,12,500);
    putstring_nl("Unknown error"); 
    return 0;
  }

  base64encode(USERNAMEPASS, linebuffer);

  // send the HTTP command, ie "GET /username/"
  putstringSS("POST "); 
  putstringSS(HTTPPATH);
  putstringSS_nl(" HTTP/1.1");
  putstring("POST "); 
  putstring(HTTPPATH); 
  putstring_nl(" HTTP/1.1");
  // next, the authentication
  putstringSS("Host: "); 
  putstringSS_nl(IPADDR);
  putstring("Host: "); 
  putstring_nl(IPADDR);
  putstringSS("Authorization: Basic ");
  putstring("Authorization: Basic ");
  mySerial.println(linebuffer);
  Serial.println(linebuffer);
  putstringSS("Content-Length: "); 
  mySerial.println(7+strlen(tweet), DEC);
  putstring("Content-Length: "); 
  Serial.println(7+strlen(tweet), DEC);
  putstringSS("\nstatus="); 
  mySerial.println(tweet);
  putstring("\nstatus="); 
  Serial.println(tweet);

  mySerial.print("");  

  while (1) {
    // read one line from the xport at a time
    ret = readline_timeout(3000); // 3s timeout
    // if we're using flow control, we can actually dump the line at the same time!
    Serial.print(linebuffer);
    if (strstr(linebuffer, "HTTP/1.1 200 OK") == linebuffer)
      success = 1;

    if (((errno == ERROR_TIMEDOUT) && XPort_disconnected()) ||
      ((XPORT_DTRPIN == 0) &&
      (linebuffer[0] == 'D') && (linebuffer[1] == 0)))  {
      putstring_nl("\nDisconnected...");
      return success;
    }
  }
}


void base64encode(char *s, char *r) {
  char padstr[4];
  char base64chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  uint8_t i, c;
  uint32_t n;

  c = strlen(s) % 3;
  if (c > 0) { 
    for (i=0; c < 3; c++) { 
      padstr[i++] = '='; 
    } 
  }
  padstr[i]=0;

  i = 0;
  for (c=0; c < strlen(s); c+=3) { 
    // these three 8-bit (ASCII) characters become one 24-bit number
    n = s[c]; 
    n <<= 8;
    n += s[c+1]; 
    if (c+2 > strlen(s)) {
      n &= 0xff00;
    }
    n <<= 8;
    n += s[c+2];
    if (c+1 > strlen(s)) {
      n &= 0xffff00;
    }

    // this 24-bit number gets separated into four 6-bit numbers
    // those four 6-bit numbers are used as indices into the base64 character list
    r[i++] = base64chars[(n >> 18) & 63];
    r[i++] = base64chars[(n >> 12) & 63];
    r[i++] = base64chars[(n >> 6) & 63];
    r[i++] = base64chars[n & 63];
  }
  i -= strlen(padstr);
  for (c=0; c<strlen(padstr); c++) {
    r[i++] = padstr[c];  
  }
  r[i] = 0;
  Serial.println(r);
}

