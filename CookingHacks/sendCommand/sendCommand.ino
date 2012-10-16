/*
 This chunk of code is designed to test the Cooking Hacks board's
 ability to recieve SMS text messages.
 If it works, we will be able to send messages to the boat from a cell phone.

 
 */


int led = 13;
int onModulePin = 2;

int timesToSend =1;
int count = 0;

int n_sms, x, sms_start;
char data[256];

void switchModule(){
	digitalWrite(onModulePin, HIGH);
	delay(2000);
	digitalWrite(onModulePin, LOW);	
}

void setup() {

	Serial.begin(115200);	//UART Baud rate
	delay(2000);
	pinMode(led, OUTPUT);
	pinMode(onModulePin, OUTPUT);
	switchModule(); //Switches the module ON

	for (int i=0; i<5; i++) {
		delay(5000);
	}

	Serial.println("AT+CMGF=1");
	delay(100);
	x=0;
	do{
		while(Serial.available()==0);
		data[x]=Serial.read();
		x++;
	}
	while(!((data[x-1] == 'K') && (data[x-2] == 'O'));	

}

void loop() {

	while(count < timesToSend){
		delay(1500);

		while(Serial.available()!=0) Serial.read();

		Serial.println("AT+CPMS=\"SM\",\"SM\",\"SM\""); //Selects SIM memory
		Serial.flush();
		for(x=0; x<255; x++) {
			data[x]='\0';
		}
		x=0;
		
		do{
			while(Serial.available()==0);
			data[x]=Serial.read();
			x++;
		}while(!((data[x-1] == 'K') && data[x-2] == 'O');

		x=0;
		do{
			x++;
		}while(data[x]!=' ');

		x++;
		n_sms=0;
		do{
			n_sms*=10;
			n_sms=n_sms + (data[x]-0x30);
		}while(data[x]!=',');

		Serial.print(" ");
		Serial.print(n_sms,DEC);

		//Now it shows the total number of SMS and the last SMS
		Serial.println(" SMS stored in SIM memory. Showing last SMS:");
		Serial.print("AT+CMGR=");//Reads the last SMS
		Serial.println(n_sms-1, DEC);
		Serial.flush();

		for(x=0; x< 255; x++){
			data[x] = '\0';
		}
		x=0;
		do{
			while(Serial.available()==0);
			data[x]=Serial.read();
			x++;
			if((data[x-1] ==0x0D) && (data[x-2] =='"')) {
				x=0;
			}
		} while(!((data[x-1] == 'K') && (data[x-2] =='O')));

		data[x-3]='\0'; //Finish the string right before the OK.

		Serial.println(data);

		delay(5000);

		count++;
	}
}
