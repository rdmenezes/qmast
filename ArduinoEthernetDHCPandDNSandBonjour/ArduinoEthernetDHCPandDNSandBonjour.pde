// Just a quick demo that basically combines the samples shipping individually within the
// Arduino DHCP, DNS and Bonjour libraries. This sketch will do 3 things:
//    1. Attempt to get network configuration data via DHCP.
//    2. Allow for DNS name resolution via the serial line, using the DNS server from the
//       the DHCP lease.
//    3. Announce its IP address on link-local Bonjour as "arduino.local", once an IP has
//       been received via DHCP.
//
// For detailed code comments on how everything works, please look at the individual
// sample code shipping with each of the libraries.

#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>
#include <EthernetBonjour.h>

const char* bonjour_hostname = "arduino";
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

const char* ip_to_str(const uint8_t*);
Server server(1080);
void setup()
{
  Serial.begin(9600);

  EthernetDHCP.begin(mac, 1);
  server.begin();
}

void loop()
{
  static DhcpState prevState = DhcpStateNone;
  static unsigned long prevTime = 0;

  DhcpState state = EthernetDHCP.poll();

  if (prevState != state) {
    Serial.println();

    switch (state) {
      case DhcpStateDiscovering:
        Serial.print("Discovering servers.");
        break;
      case DhcpStateRequesting:
        Serial.print("Requesting lease.");
        break;
      case DhcpStateRenewing:
        Serial.print("Renewing lease.");
        break;
      case DhcpStateLeased: {
        Serial.println("Obtained lease!");

        const byte* ipAddr = EthernetDHCP.ipAddress();
        const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
        const byte* dnsAddr = EthernetDHCP.dnsIpAddress();

        Serial.print("My IP address is ");
        Serial.println(ip_to_str(ipAddr));

        Serial.print("Gateway IP address is ");
        Serial.println(ip_to_str(gatewayAddr));

        Serial.print("DNS IP address is ");
        Serial.println(ip_to_str(dnsAddr));

        Serial.println('\n');
        
        Serial.println("DNS server set via DHCP. Send a host name via serial to resolve it.\n");
        EthernetDNS.setDNSServer(dnsAddr);
        
        EthernetBonjour.begin(bonjour_hostname);
        
        Serial.print("Also, the board is resolvable via Bonjour/ZeroConf as ");
        Serial.print(bonjour_hostname);
        Serial.println(".local\n"); 
        
        break;
      }
        // listen for incoming clients
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.println("hellooo");
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();

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
  } else if (state != DhcpStateLeased && millis() - prevTime > 300) {
     prevTime = millis();
     Serial.print('.'); 
  } else if (state == DhcpStateLeased) {
    char hostName[512];
    int length = 0;
    
    EthernetBonjour.run();
    
    while (Serial.available()) {
      hostName[length] = Serial.read();
      length = (length+1) % 512;
      delay(50);
    }
    
    hostName[length] = '\0';
    
    if (length > 0) {
      
      byte ipAddr[4];
      
      Serial.print("Resolving ");
      Serial.print(hostName);
      Serial.print("...");
 
      DNSError err = EthernetDNS.sendDNSQuery(hostName);
  
      if (DNSSuccess == err) {
        do {
          err = EthernetDNS.pollDNSReply(ipAddr);
  			
          if (DNSTryLater == err) {
            delay(20);
            Serial.print(".");
          }
        } while (DNSTryLater == err);
      }
  
      Serial.println();

      if (DNSSuccess == err) {
        Serial.print("The IP address is ");
        Serial.print(ip_to_str(ipAddr));
        Serial.println(".");
      } else if (DNSTimedOut == err) {
        Serial.println("Timed out.");
      } else if (DNSNotFound == err) {
        Serial.println("Does not exist.");
      } else {
        Serial.print("Failed with error code ");
        Serial.print((int)err, DEC);
        Serial.println(".");
      }
    }  
  }

  prevState = state;
}

const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}
