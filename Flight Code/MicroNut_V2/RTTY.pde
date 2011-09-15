/*
	MicroNut Flight Computer Software
	
	RTTY Driver
	
	Written by:
	Terry Baume <terry@bogaurd.net>
	Mark Jessop <lenniethelemming@gmail.com>
	
	This code is based on Robert Harrison's (rharrison@hgf.com) RTTY code as used in the Icarus project
	http://pegasushabproject.org.uk/wiki/doku.php/ideas:notes?s=rtty

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    For a full copy of the GNU General Public License, 
    see <http://www.gnu.org/licenses/>.
*/


// Transmit a string, log it to SD & produce debug output
void txString(char *string) {
        digitalWrite(PIN_PWR_LED,LOW);
        digitalWrite(PIN_PWR_LED,HIGH);
	// We need accurate timing, switch off interrupts
	noInterrupts();
	
	// CRC16 checksum
	char txSum[6];
	unsigned int checkSum = CRC16Sum(string);
	sprintf(txSum, "%04X", checkSum);
	
	// Log the string
	#if DEBUG > 1
		debug << F("RTTY: ") << string << "*" << txSum << endl;
		debug << HRULE << endl;
	#endif
	
	#if LOGGER > 0
		logger << string << F("*") << txSum << endl;
	#endif
	
	// TX the string
	rtty_txstring(string);
	rtty_txstring("*");
	rtty_txstring(txSum);
	rtty_txstring("\r\n");
	
	// Interrupts back on
	interrupts();
        digitalWrite(PIN_PWR_LED,LOW);
}

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

unsigned int CRC16Sum(char *string) {
	unsigned int i;
	unsigned int crc;
	crc = 0xFFFF;
	// Calculate the sum, ignore $ sign's
	for (i = 0; i < strlen(string); i++) {
		if (string[i] != '$') crc = _crc_xmodem_update(crc,(uint8_t)string[i]);
	}
	return crc;
}

void sendArray(uint8_t *arraydata, uint8_t len){

	rtty_txstring("Array Bytes:");
	for (uint8_t i = 0; i < len; i++)
	{
		// zero pad the value if necessary
		char temp[5];
		unsigned int tempbyte = 0;
		tempbyte = arraydata[i];
		
		rtty_txstring("0x");
		if (arraydata[i] < 16) rtty_txstring("0");
		sprintf(temp, "%X", tempbyte);
		rtty_txstring(temp);
		if (i<7) rtty_txstring(",");
	}
	rtty_txstring("}\n");
}