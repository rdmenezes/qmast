/*
From Arduino website.
Sept 15th, 2011. Valerie. Works on the Uno with ethernet shield
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x6D, 0xCA };
byte ip[] = { 192,168,0,100  };
Server server(80);
when connected directly to computer with ethernet (and also USB for power but probably irrelevant)
navigate browswer to 192.168.0.100 and it displays the analog inputs

*/

#include <SPI.h>
#include <Ethernet.h>

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x6D, 0xCA };
byte ip[] = {192,168,13,101}; //{74,49,35,48};
//byte gateway[] ={74,49,31,1};
//byte subnet[] = {255,255,255,0};

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
Server server(80);

void setup()
{
  // start the Ethernet connection and the server:
  Ethernet.begin(mac, ip);//,gateway, subnet);
  server.begin();
}

void loop()
{
  // listen for incoming clients
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();

          client.print("<h1><font color=\"red\" face = \"Century Gothic\">whoooooooo working!!! (Hello Laszlo and Cory)<br /></font></h1>");
          client.print("sample output: <br />");
          // output the value of each analog input pin
          for (int analogChannel = 0; analogChannel < 6; analogChannel++) {
            client.print("analog input ");
            client.print(analogChannel);
            client.print(" is ");
            client.print(analogRead(analogChannel));
            client.println("<br />");
          }
         
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
  }
}

