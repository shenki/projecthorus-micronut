/*
  Spi.cpp - SPI library
  Copyright (c) 2008 Cam Thompson.
  Author: Cam Thompson, Micromega Corporation, <www.micromegacorp.com>
  Version: December 15, 2008

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
  
  Modified by Mark Jessop to work with the TOPCAT payload. 2011-08-01
*/

#include "WProgram.h"
#include "Mega_SPI.h"

//---------- constructor ----------------------------------------------------

void SPI_Begin(void)
{
  // initialize the SPI pins
  pinMode(SCK_PIN, OUTPUT);
  pinMode(MOSI_PIN, OUTPUT);
  pinMode(MISO_PIN, INPUT);
  pinMode(SS_PIN, OUTPUT);
  digitalWrite(SS_PIN, HIGH);

  // enable SPI Master, MSB, SPI mode 0, FOSC/4
  SPI_mode(0);
}


//------------------ mode ---------------------------------------------------

void SPI_mode(byte config)
{
  byte tmp;

  // enable SPI master with configuration byte specified
  
  /*
  SPCR = 0;
  SPCR = (config & 0x7F) | (1<<SPE) | (1<<MSTR);
  tmp = SPSR;
  tmp = SPDR;
  */
  SPDR = 0x00;
  
  SPCR = 0x00;
  SPSR = 0x00;
  SPCR = (1<<SPE)|(1<<MSTR);
  SPSR = (1<<SPI2X);
}

//------------------ transfer -----------------------------------------------

byte SPI_transfer(byte value)
{
 
//  Serial.print("[");
//  Serial.print(value, HEX);
//  Serial.print(",");
  
  SPDR = value;
  while (!(SPSR & (1<<SPIF))) {
  }
  
 // Serial.print(SPDR, HEX);
 // Serial.println("]");
  
  return SPDR;
}

byte SPI_transfer(byte value, byte period)
{
  SPDR = value;
  if (period > 0) delayMicroseconds(period);
  while (!(SPSR & (1<<SPIF))) ;
  return SPDR;
}


//---------- preinstantiate SPI object --------------------------------------

//MegaSPI SPI = MegaSPI();
