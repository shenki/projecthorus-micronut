/*
	MicroNut Flight Computer Software
	
	SPI Flash Handler
	
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

#define	FLASH_SIZE	16384 // Flash size in pages.

#define FLASH_POINTER 250 // We use the last 6 bytes in the first page to store the pointer.

// The flash memory is divided into 256 byte pages, with 10x25-byte memory slots per page.
// This ends up wasting 98kb, but saves the hassle of having to write across page boundaries.


long flash_next_slot = 0; 


void flash_write_record(){ //unsigned int sequence_no, uint8_t hour, uint8_t minute, uint8_t second, float latitude, float longitude, unsigned int altitude, unsigned int velocity, uint8_t sats, int8_t temp1, int8_t temp2, uint8_t custom0, uint8_t custom1, uint8_t custom2, uint8_t custom3, uint8_t custom4){
	uint8_t temp_data_store[25];
	long address = (flash_next_slot * 25) + (flash_next_slot/10)*6;
	
	temp_data_store[0] = (uint8_t)(record1.sequence_no>>8);
	temp_data_store[1] = (uint8_t)(record1.sequence_no);
	temp_data_store[2] = record1.hour;
	temp_data_store[3] = record1.minute;
	temp_data_store[4] = record1.second;
	memcpy(&temp_data_store[5], &record1.latitude, sizeof(record1.latitude));
	memcpy(&temp_data_store[9], &record1.longitude, sizeof(record1.longitude));
	temp_data_store[13] = (uint8_t)(record1.altitude>>8);
	temp_data_store[14] = (uint8_t)(record1.altitude);
	temp_data_store[15] = (uint8_t)(record1.velocity>>8);
	temp_data_store[16] = (uint8_t)(record1.velocity);
	temp_data_store[17] = record1.sats;
	memcpy(&temp_data_store[18], &record1.temp1, sizeof(record1.temp1));
	memcpy(&temp_data_store[19], &record1.temp2, sizeof(record1.temp2));
	memcpy(&temp_data_store[20], &record1.custom, sizeof(record1.custom));

	
	// Write into flash.
	storage.clearSR();
	if(storage.write(address, temp_data_store,25) == 0){
		bitSet(FLASH_FLAGS, FLASH_ERROR);
	}else{
		flash_next_slot++;
		flash_update_pointer();
	}	
}

void flash_read_record(unsigned long record_no){
	uint8_t temp_data_store[25];
	long address;
	if(record_no<FLASH_SIZE){
		address = (record_no * 25) + (record_no/10)*6;
	}else{return;}
	
	temp_data_store[0] = storage.start_read(address);
	for(int i = 1; i<25; i++){
		temp_data_store[i] = storage.continue_read();
	}
	storage.end_read();
	
	record1.sequence_no = temp_data_store[0];
	record1.sequence_no = record1.sequence_no<<8;
	record1.sequence_no |= temp_data_store[1];
	record1.hour = temp_data_store[2];
	record1.minute = temp_data_store[3];
	record1.second = temp_data_store[4];
	memcpy(&record1.latitude, &temp_data_store[5], 4);
	memcpy(&record1.longitude, &temp_data_store[9], 4);
	record1.altitude = temp_data_store[13];
	record1.altitude = record1.altitude<<8;
	record1.altitude |= temp_data_store[14];
	record1.velocity = temp_data_store[15];
	record1.velocity = record1.velocity<<8;
	record1.velocity |= temp_data_store[16];
	record1.sats = temp_data_store[17];
	memcpy(&record1.temp1, &temp_data_store[18], 1);
	memcpy(&record1.temp2, &temp_data_store[19], 1);
	memcpy(&record1.custom, &temp_data_store[20], 5);
}

void flash_clear(){
	flash_next_slot = 0;
	flash_update_pointer();
}

void flash_update_pointer(){
	uint8_t temp_data_store[6];
	temp_data_store[0] = (uint8_t)(flash_next_slot>>24);
	temp_data_store[1] = (uint8_t)(flash_next_slot>>16);
	temp_data_store[2] = (uint8_t)(flash_next_slot>>8);
	temp_data_store[3] = (uint8_t)(flash_next_slot);
	unsigned int crc = crc16(temp_data_store, 4);
	temp_data_store[4] = (uint8_t)(crc>>8);
	temp_data_store[5] = (uint8_t)(crc);
	
	//sendArray(temp_data_store,6);
	// Write into flash.
	storage.clearSR();
	if(storage.write(250, temp_data_store, 6) == 0){
		bitSet(FLASH_FLAGS, FLASH_ERROR);
	}
}

void flash_read_pointer(){
	uint8_t temp_data_store[6];
	temp_data_store[0] = storage.start_read(250);
	for(int i = 1; i<6; i++){
		temp_data_store[i] = storage.continue_read();
	}
	storage.end_read();
	
	//sendArray(temp_data_store,6);
	
	unsigned int crc = crc16(temp_data_store, 4);
	
	if( ((uint8_t)crc == temp_data_store[5]) && ((uint8_t)(crc>>8) == temp_data_store[4]) ){
		flash_next_slot = temp_data_store[0];
		flash_next_slot = flash_next_slot << 8;
		flash_next_slot |= temp_data_store[1];
		flash_next_slot = flash_next_slot << 8;
		flash_next_slot |= temp_data_store[2];
		flash_next_slot = flash_next_slot << 8;
		flash_next_slot |= temp_data_store[3];
	}else{
		flash_clear();
		bitSet(FLASH_FLAGS, FLASH_CLEARED);
	}
}

uint8_t flash_test(long address, uint8_t value){
	if(storage.write(address, value) == 0){
		bitSet(FLASH_FLAGS, FLASH_ERROR);
		return 0;
	}else{
		if(storage.read_byte(address) == value){return 1;}
		else{ return 0;}
	}
}

void print_slots_remaining(){
	long slots_left = 163840 - flash_next_slot;
	char temp[10];
	rtty_txstring("Flash Memory Slots Remaining: ");
	sprintf(temp, "%ld\n", slots_left);
	rtty_txstring(temp);
}