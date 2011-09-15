#include <TimerOne.h>

#define VOLTAGE_MONITOR 7
#define PIN_RTTY_ENABLE     A1 // Active High
#define PIN_ONEWIRE         5
#define PIN_SD_SELECT       A0
#define PIN_RTTY_SPACE      A2
#define PIN_RTTY_MARK       A3
#define PWR_LED  3


void setup(){
        pinMode(PIN_RTTY_ENABLE, OUTPUT);
        pinMode(PWR_LED,OUTPUT);
        pinMode(PIN_RTTY_MARK, OUTPUT);
        pinMode(PIN_RTTY_SPACE, OUTPUT);
        // Turn on LED
        digitalWrite(PWR_LED,HIGH);
        // Start TX1H/NTX2 Module.
        digitalWrite(PIN_RTTY_ENABLE, HIGH);
        
        //Timer1.initialize(20000); // 50 Baud
        //Timer1.initialize(3333);  // 300 Baud
        Timer1.initialize(1666);  // 600 Baud
        //Timer1.initialize(833); // 1200 baud
}

void loop(){
  rtty_txstring("Testing 1234567890fassdfsadfdsafsdafdsafaewrq4gwqreg\n");
  Timer1.attachInterrupt(rtty_tx_interrupt);
  waitForTX();
  Timer1.detachInterrupt();
  delay(500);
}


void txbit (int bit) {
	if (bit) {
		// High - mark
		digitalWrite(PIN_RTTY_SPACE, HIGH);
		digitalWrite(PIN_RTTY_MARK, LOW);	
		
	} else {
		// Low - space
		digitalWrite(PIN_RTTY_MARK, HIGH);
		digitalWrite(PIN_RTTY_SPACE, LOW);
	}
}
