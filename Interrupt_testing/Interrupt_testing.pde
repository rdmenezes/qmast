//Basic Interrupt Routine, just counts sequentially every time there is a timer interrupt
//This code works correctly, but does not port at all to th the sailcode, further investigation needed

#include <avr/interrupt.h >
#include <avr/io.h >

#define INIT_TIMER_COUNT 0
#define RESET_TIMER1 TCNT1 = INIT_TIMER_COUNT

int int_counter = 0;
volatile int second = 0;
int oldSecond = 0;

// Aruino runs at 16 Mhz, so we have 61 Overflows per second...
// 1/ ((16000000 / 1024) / 256) = 1 / 61
ISR(TIMER1_OVF_vect) {
  int_counter += 1;
  if (int_counter == 500) {
    second+=1;
    int_counter = 0;
     Serial.println("Interrupt");
  }
};

void setup() {
  Serial.begin(9600);
  Serial.println("Initializing timerinterrupt");
  //Timer2 Settings:  Timer Prescaler /1024
  TCCR1A |= ((1 << CS22) | (1 << CS21) | (1 << CS20));
  //Timer2 Overflow Interrupt Enable
  TIMSK1 |= (1 << TOIE1);
  RESET_TIMER1;
  sei();
}

void loop() {
  if (oldSecond != second) {
    Serial.print(second);
    Serial.println(".");
    oldSecond = second;
  }
}
