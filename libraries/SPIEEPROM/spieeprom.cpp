/*
 * spieeprom.cpp - library for SPI EEPROM IC's
 * https://bitbucket.org/trunet/spieeprom/
 * 
 * This library is based on code by Heather Dewey-Hagborg
 * available on http://www.arduino.cc/en/Tutorial/SPIEEPROM
 * 
 * by Wagner Sartori Junior <wsartori@gmail.com>
 *
 * Modified by Mark Jessop for TOPCAT project. 2011-08-01
 */

#include <WProgram.h>
#include <Mega_SPI.h>
#include "spieeprom.h"

SPIEEPROM::SPIEEPROM() {
	eeprom_type = 0;
	address = 0;
}

SPIEEPROM::SPIEEPROM(byte type) {
	if (type>1) {
		eeprom_type = 0;
	} else {
		eeprom_type = type;
	}
	address = 0;
}

void SPIEEPROM::setup() {
	pinMode(SLAVESELECT, OUTPUT);
	SPI_Begin();
}

void SPIEEPROM::send_address(long addr) {
	if (eeprom_type == 1) {
		SPI_transfer((byte)(addr>>16));
	}
	SPI_transfer((byte)(addr>>8));
	SPI_transfer((byte)(addr));
}

void SPIEEPROM::start_write() {
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(WREN); //send WREN command
	digitalWrite(SLAVESELECT,HIGH);
	delayMicroseconds(10);
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(WRITE); //send WRITE command
}
bool SPIEEPROM::isWIP() {
	byte data;
	
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(RDSR); // send RDSR command
	
	data = SPI_transfer(0xFF); //get data byte
	
	digitalWrite(SLAVESELECT,HIGH);
	
	return (data & (1 << 0));
}

uint8_t SPIEEPROM::write(long addr, byte data) {
	start_write();
	
	send_address(addr); // send address
	SPI_transfer(data); // transfer data
	
	digitalWrite(SLAVESELECT,HIGH);
	
	unsigned long start_write_time = millis();
	while (isWIP() && (millis() < (start_write_time + EEPROM_TIMEOUT)) ) {
		delay(1);
	}
	if( isWIP() ){ // Is the write still in progress? (i.e. something is broken)
		return 0;
	}else{
		return 1;
	}
}

uint8_t SPIEEPROM::write(long addr, byte data[], int arrLength) {
	start_write();
	
	send_address(addr); // send address

	for (int i=0;i<arrLength;i++) {
		SPI_transfer(data[i]); // transfer data
	//	Serial.print(data[i], HEX);
	//	Serial.print(" ");
	}
	
	digitalWrite(SLAVESELECT,HIGH);
	unsigned long start_write_time = millis();
	while (isWIP() && (millis() < (start_write_time + EEPROM_TIMEOUT)) ) {
		delay(1);
	}
	if( isWIP() ){ // Is the write still in progress? (i.e. something is broken)
		return 0;
	}else{
		return 1;
	}
}

uint8_t SPIEEPROM::write(long addr, char data[], int arrLength) {
	start_write();
	
	send_address(addr); // send address
	
	for (int i=0;i<arrLength;i++) {
		SPI_transfer(data[i]); // transfer data
	}
	
	digitalWrite(SLAVESELECT,HIGH);
	unsigned long start_write_time = millis();
	while (isWIP() && (millis() < (start_write_time + EEPROM_TIMEOUT)) ) {
		delay(1);
	}
	if( isWIP() ){ // Is the write still in progress? (i.e. something is broken)
		return 0;
	}else{
		return 1;
	}
}

byte SPIEEPROM::read_byte(long addr) {
	byte data;
	
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(READ); // send READ command
	
	send_address(addr); // send address
	data = SPI_transfer(0xFF); //get data byte
	
	digitalWrite(SLAVESELECT,HIGH); //release chip, signal end transfer
	
	return data;
}

char SPIEEPROM::read_char(long addr) {
	char data;
	
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(READ); // send READ command
	
	send_address(addr); // send address
	data = SPI_transfer(0xFF); //get data byte
	
	digitalWrite(SLAVESELECT,HIGH); //release chip, signal end transfer
	return data;
}

char SPIEEPROM::start_read(long addr){
	char data;
	
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(READ); // send READ command
	
	send_address(addr); // send address
	data = SPI_transfer(0xFF); //get data byte
	return data;
}

char SPIEEPROM::continue_read(){
	char data;
	data = SPI_transfer(0xFF); //get data byte
	return data;
}

void SPIEEPROM::end_read(){
	digitalWrite(SLAVESELECT,HIGH); //release chip, signal end transfer
}

uint8_t SPIEEPROM::pageErase(long addr){
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(WREN); //send WREN command
	digitalWrite(SLAVESELECT,HIGH);
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(PAGE_ERASE);
	
	send_address(addr);
	digitalWrite(SLAVESELECT,HIGH);
	
	unsigned long start_write_time = millis();
	while (isWIP() && (millis() < (start_write_time + EEPROM_TIMEOUT)) ) {
		delay(1);
	}
	if( isWIP() ){ // Is the write still in progress? (i.e. something is broken)
		return 0;
	}else{
		return 1;
	}
}

uint8_t SPIEEPROM::chipErase(){
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(WREN); //send WREN command
	digitalWrite(SLAVESELECT,HIGH);
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(CHIP_ERASE);
	digitalWrite(SLAVESELECT,HIGH);
	
	unsigned long start_write_time = millis();
	while (isWIP() && (millis() < (start_write_time + EEPROM_TIMEOUT)) ) {
		delay(1);
	}
	if( isWIP() ){ // Is the write still in progress? (i.e. something is broken)
		return 0;
	}else{
		return 1;
	}
}

void SPIEEPROM::clearSR(){
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(WREN); //send WREN command
	digitalWrite(SLAVESELECT,HIGH);
	delayMicroseconds(10);
	digitalWrite(SLAVESELECT,LOW);
	SPI_transfer(WRSR); //send WRSR command
	SPI_transfer(0x00);
	digitalWrite(SLAVESELECT,HIGH);
}
