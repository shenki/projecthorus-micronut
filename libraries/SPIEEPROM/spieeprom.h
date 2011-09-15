/*
 * spieeprom.h - library for SPI EEPROM IC's
 * https://bitbucket.org/trunet/spieeprom/
 * 
 * This library is based on code by Heather Dewey-Hagborg
 * available on http://www.arduino.cc/en/Tutorial/SPIEEPROM
 * 
 * by Wagner Sartori Junior <wsartori@gmail.com>
 *
 * Modified by Mark Jessop for TOPCAT project. 2011-08-01
 */

#ifndef SPIEEPROM_h
#define SPIEEPROM_h

#include <WProgram.h>
#include <Mega_SPI.h> // relies on arduino SPI library

#if defined (__AVR_ATmega1280__) || defined (__AVR_ATmega2560__)
#define SLAVESELECT 53 // SPI SS Pin
                       // on MEGA2560 should be PIN 53
					   // change it if you want to use another pin
#endif

#ifndef SLAVESELECT
#define SLAVESELECT	10
#endif

//opcodes
#define WREN  6
#define WRDI  4
#define RDSR  5
#define WRSR  1
#define READ  3
#define WRITE 2
#define PAGE_ERASE	0x42
#define SECTOR_ERASE	0xD8
#define CHIP_ERASE	0xC7

#define EEPROM_TIMEOUT 30 // 100ms should be ok... Or do we want it to hang?

class SPIEEPROM
{
  private:
	long address;
	byte eeprom_type;
	
	void send_address(long addr);
	void start_write();
	bool isWIP(); // is write in progress?
	
  public:
	SPIEEPROM(); // default to type 0
    SPIEEPROM(byte type); // type=0: 16-bits address
						  // type=1: 24-bits address
						  // type>1: defaults to type 0
						
	void setup();

	uint8_t write(long addr, byte data);
	uint8_t write(long addr, byte data[], int arrLength);
	//void write(long addr, char data);
	uint8_t write(long addr, char data[], int arrLength);
	//void write(long addr, int data);
	//void write(long addr, long data);
	//void write(long addr, float data);
	
	byte  read_byte (long addr);
	//void  read_byte_array (long addr, byte data[]);
	char  read_char (long addr);
	char start_read(long addr);
	char continue_read();
	void end_read();
	//int   read_int  (long addr);
	//long  read_long (long addr);
	//float read_float(long addr);
	uint8_t pageErase(long addr);
	uint8_t chipErase();
	void clearSR();
};

#endif // SPIEEPROM_h
