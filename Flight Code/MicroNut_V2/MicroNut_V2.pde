/*
	MicroNut Flight Computer Software
	
	Written by:
	Mark Jessop <lenniethelemming@gmail.com>

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

#include <Mega_SPI.h>
#include <spieeprom.h>
//#include <TimerOne.h>
#include <TinyGPS.h>
#include <Streaming.h>
#include <Flash.h>
#include <NewSoftSerial.h>
#include <util/crc16.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Wire.h>

// Pin Mappings
#define PIN_RTTY_ENABLE     4 	// Active High
#define PIN_ONEWIRE         A0	// Handle from OneWire Library
#define PIN_FLASH_CS        10	// Active Low, handled within SPI library
#define PIN_RTTY_SPACE      2
#define PIN_RTTY_MARK       3
#define PIN_PWR_LED         A3


// Global Variables

SPIEEPROM storage(1); // Object for Flash memory access.
byte FLASH_FLAGS = 0x00;
#define FLASH_ERROR	0
#define FLASH_ERROR_NOTIFIED 1
#define FLASH_CLEARED 2

// RTTY speed
const int bitRate = 300;

// tinyGPS object
TinyGPS gps;

// Temp sensor objects
OneWire oneWire(PIN_ONEWIRE);
DallasTemperature sensors(&oneWire);

// Internal Temp Sensor Device IDs (MicroNut Boards)
//uint8_t internal[] = {0x28,0xB9,0xF2,0x36,0x03,0x00,0x00,0x0F}; // #1
uint8_t internal[] = {0x28,0x19,0x18,0x37,0x03,0x00,0x00,0xBB}; // #2

// External Temp Sensor Device IDs
//uint8_t external[] = {0x28,0xAB,0xDC,0x59,0x02,0x00,0x00,0xC1}; 
//uint8_t external[] = {0x28,0x6A,0x24,0xE3,0x02,0x00,0x00,0x7B}; // Sensor E1
uint8_t external[] = {0x28,0xF2,0x9B,0xE3,0x02,0x00,0x00,0x4B};


struct position_record // Total 25 bytes
{
	unsigned int 		sequence_no; 		// 2 bytes
	uint8_t			hour;				// 1 byte
	uint8_t			minute;				// 1 byte
	uint8_t			second;				// 1 byte
	float			latitude;			// 4 bytes
	float			longitude;			// 4 bytes
	unsigned int		altitude;			// 2 bytes
	unsigned int		velocity;			// 2 bytes
	uint8_t			sats;				// 1 byte
	int8_t			temp1; // Internal  // 1 byte
	int8_t			temp2; // External  // 1 byte
	uint8_t			custom[5];			// 5 bytes
};
position_record record1 = {0,0,0,0, 0.0,0.0, 0,0,0,0,0, {0,0,0,0,0}};//{0,1,2,3, -33.1234, 138.2345, 40575,200,10,4,-5, {0,0,0,0,0}};

// Output transmit Buffer.
char txBuffer[128]; 


void setup(){
	// Initialize IOs
	pinMode(PIN_RTTY_ENABLE, OUTPUT);
	pinMode(PIN_RTTY_SPACE, OUTPUT);
	pinMode(PIN_RTTY_MARK, OUTPUT);
	pinMode(PIN_PWR_LED, OUTPUT);
	digitalWrite(PIN_RTTY_ENABLE, HIGH);
	digitalWrite(PIN_RTTY_MARK, HIGH);
	digitalWrite(PIN_RTTY_SPACE, LOW);
	digitalWrite(PIN_PWR_LED, LOW);
	delay(500);
	// Initialize the Timer interrupt delay, setting the baud rate.
	
	//Timer1.initialize(20000); // 50 Baud
	//Timer1.initialize(3333);  // 300 Baud
	//Timer1.initialize(1666);  // 600 Baud
	//Timer1.initialize(833); // 1200 baud
	
	
	rtty_txstring("Booting Up.\n");
	
	// Setup the SPI Flash Memory, if it exists.
	storage.setup();
	storage.clearSR();
	flash_read_pointer();
	
	if(bitRead(FLASH_FLAGS,FLASH_CLEARED)){
		rtty_txstring("Flash Erased.\n");
		if(flash_test(0x3FFFFF,0xAA)==0){
			rtty_txstring("Flash Test Failed.\n");
			bitSet(FLASH_FLAGS, FLASH_ERROR);
		}else{
			digitalWrite(PIN_PWR_LED, HIGH);
			rtty_txstring("Flash Test Passed.\n");
		}
	}
	print_slots_remaining();
	
	Serial.begin(9600);
	configNMEA();
	rtty_txstring("Started GPS.\n");
	
	sensors.begin();
	sensors.requestTemperatures();
	rtty_txstring("Started Temp Sensors.\n");
	
	rtty_txstring("Boot Complete.\n");

}

void loop(){
	if(bitRead(FLASH_FLAGS, FLASH_ERROR) && (bitRead(FLASH_FLAGS,FLASH_ERROR_NOTIFIED)==0)){
		rtty_txstring("Flash Memory Failure.\n");
		bitSet(FLASH_FLAGS, FLASH_ERROR_NOTIFIED);
	}
	
	
	// get the GPS data
	feedGPS(); // up to 3 second delay here
	gps.f_get_position(&record1.latitude, &record1.longitude);
	record1.sats = (uint8_t)gps.sats();
	record1.altitude = (unsigned int)gps.f_altitude();
	record1.velocity = (unsigned int)gps.f_speed_kmph();
	gps.crack_datetime(0, 0, 0, &record1.hour, &record1.minute, &record1.second);
	
	int _intTemp = sensors.getTempC(internal);
    if (_intTemp!=85 && _intTemp!=127 &&
        _intTemp!=-127 && _intTemp!=999) {
        record1.temp1 = (int8_t)_intTemp;
    }
	
    int _extTemp = sensors.getTempC(external);
    if (_extTemp!=85 && _extTemp!=127 && _extTemp!=-127 && _extTemp!=999) {
        record1.temp2 = (int8_t)_extTemp;
    }

	generate_string();
	txString(txBuffer);
	
	flash_write_record();
	record1.sequence_no++;
	sensors.requestTemperatures();
	
	delay(1000);
	

}


void generate_string(){
	char latString[12], longString[12];
	
	dtostrf(record1.latitude, 11, 5, latString);
	dtostrf(record1.longitude, 11, 5, longString);

	sprintf(txBuffer, "$$HORUS,%u,%02u:%02u:%02d,%s,%s,%u,%u,%u;%d;%d", record1.sequence_no, record1.hour, record1.minute, record1.second, trim(latString), trim(longString), record1.altitude, record1.velocity, record1.sats, record1.temp1, record1.temp2);

}


