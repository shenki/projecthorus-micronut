// Project Horus, www.projecthorus.org
// Terry Baume, 2009
// terry@bogaurd.net

// RTTY code

// This code is based on Robert Harrison's (rharrison@hgf.com) RTTY code as used in the Icarus project
// http://pegasushabproject.org.uk/wiki/doku.php/ideas:notes?s=rtty


// Transmit a string, one char at a time
void rtty_txstring (char *string) {
	//dummySerial.read();
	for (int i = 0; i < strlen(string); i++) {
		rtty_txbyte(string[i]);
	}
}

// Transmit a byte, bit by bit, LSB first
// ASCII_BIT can be either 7bit or 8bit
void rtty_txbyte (char c) {
	int i;
	// Start bit
	rtty_txbit (0);
	// Send bits for for char LSB first	
	for (i=0;i<7;i++) {
		if (c & 1) rtty_txbit(1); 
		else rtty_txbit(0);	
		c = c >> 1;
	}
	// Stop bit
	rtty_txbit (1);
}

// Transmit a bit as a mark or space
void rtty_txbit (int bit) {
	if (bit) {
		// High - mark
		digitalWrite(PIN_RTTY_SPACE, HIGH);
		digitalWrite(PIN_RTTY_MARK, LOW);	
		
	} else {
		// Low - space
		digitalWrite(PIN_RTTY_MARK, HIGH);
		digitalWrite(PIN_RTTY_SPACE, LOW);
	}
	
	switch (bitRate) {
	
		case 200:
			delayMicroseconds(5050);
			break;
			
		case 300:
			delayMicroseconds(3400);
			break;
			
		case 150:
			delayMicroseconds(6830);
			break;
		
		case 100:
			delayMicroseconds(10300);
			break;
		
		default:
			delayMicroseconds(10000);
			delayMicroseconds(10600);
	}
}

