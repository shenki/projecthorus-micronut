/*
	MicroNut Flight Computer Software
	
	GPS Driver
	
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

#include <Streaming.h>

// GPS PUBX request string
FLASH_STRING(PUBX, "$PUBX,00*33");

// NMEA commands
FLASH_STRING(GLL_OFF, "$PUBX,40,GLL,0,0,0,0*5C");
FLASH_STRING(ZDA_OFF, "$PUBX,40,ZDA,0,0,0,0*44");
FLASH_STRING(GSV_OFF, "$PUBX,40,GSV,0,0,0,0*59");
FLASH_STRING(GSA_OFF, "$PUBX,40,GSA,0,0,0,0*4E");
FLASH_STRING(RMC_OFF, "$PUBX,40,RMC,0,0,0,0*47");
FLASH_STRING(GGA_OFF, "$PUBX,40,GGA,0,0,0,0*5A");
FLASH_STRING(VTG_OFF, "$PUBX,40,VTG,0,0,0,0*5E");

// configures the GPS to only use the strings we want
void configNMEA() {
	Serial << GLL_OFF << endl;
	Serial << ZDA_OFF << endl;
	Serial << GSV_OFF << endl;
	Serial << GSA_OFF << endl;
	Serial << RMC_OFF << endl; 
	Serial << GGA_OFF << endl;
	Serial << VTG_OFF << endl; 
	
	// Set the navigation mode (Airborne, 1G)
	uint8_t setNav[] = {0xB5, 0x62, 0x06, 0x24, 0x24, 0x00, 0xFF, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x10, 0x27, 0x00, 0x00, 0x05, 0x00, 0xFA, 0x00, 0xFA, 0x00, 0x64, 0x00, 0x2C, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x16, 0xDC};
	sendUBX(setNav, sizeof(setNav)/sizeof(uint8_t));
	getUBX_ACK(setNav);
}

// request the PUBX string and feed the GPS
void feedGPS() {	
	Serial << PUBX << endl;
	long startTime = millis();
	while (millis() < startTime + 3000) {
		if (Serial.available()) {
			byte c = Serial.read();

			if (gps.encode(c)) {
				break;
			}
		}
	}
}

// Send a byte array of UBX protocol to the GPS
void sendUBX(uint8_t *MSG, uint8_t len) {
	for(int i=0; i<len; i++) {
		Serial.print(MSG[i], BYTE);
	}
}
 
 
// Calculate expected UBX ACK packet and parse UBX response from GPS
boolean getUBX_ACK(uint8_t *MSG) {
	uint8_t b;
	uint8_t ackByteID = 0;
	uint8_t ackPacket[10];
	int startTime = millis();
 
	// Construct the expected ACK packet    
	ackPacket[0] = 0xB5;	// header
	ackPacket[1] = 0x62;	// header
	ackPacket[2] = 0x05;	// class
	ackPacket[3] = 0x01;	// id
	ackPacket[4] = 0x02;	// length
	ackPacket[5] = 0x00;
	ackPacket[6] = MSG[2];	// ACK class
	ackPacket[7] = MSG[3];	// ACK id
	ackPacket[8] = 0;		// CK_A
	ackPacket[9] = 0;		// CK_B
 
	// Calculate the checksums
	for (uint8_t i=2; i<8; i++) {
		ackPacket[8] = ackPacket[8] + ackPacket[i];
		ackPacket[9] = ackPacket[9] + ackPacket[8];
	}
 
	while (1) {
 
		// Test for success
		if (ackByteID > 9) {
				// All packets in order!
				return true;
		}
 
		// Timeout if no valid response in 3 seconds
		if (millis() - startTime > 3000) { 
			return false;
		}
 
		// Make sure data is available to read
		if (Serial.available()) {
			b = Serial.read();
 
			// Check that bytes arrive in sequence as per expected ACK packet
			if (b == ackPacket[ackByteID]) { 
				ackByteID++;
			} else {
				ackByteID = 0;	// Reset and look again, invalid order
			}
 
		}
	}
}

