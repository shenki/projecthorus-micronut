#include <OneWire.h>
#include <DallasTemperature.h>
//#include <NewSoftSerial.h>

// pin assignments
#define PIN_RTTY_ENABLE     4 // Active High
#define PIN_ONEWIRE         A0
#define PIN_SD_SELECT       0
#define PIN_RTTY_SPACE      2
#define PIN_RTTY_MARK       3
#define PWR_LED  A3

#define TEMPERATURE_PRECISION 9

// RTTY speed
const int bitRate = 300;

//NewSoftSerial mySerial(5, 6);


// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(PIN_ONEWIRE);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device addresses
DeviceAddress insideThermometer, outsideThermometer;

char txbuffer[100];

void setup(){
//      mySerial.begin(9600);
  
          pinMode(PIN_RTTY_ENABLE, OUTPUT);
        pinMode(PWR_LED,OUTPUT);
        pinMode(PIN_RTTY_MARK, OUTPUT);
        pinMode(PIN_RTTY_SPACE, OUTPUT);
    
            // Turn on LED
        digitalWrite(PWR_LED,HIGH);
        // Start TX1H/NTX2 Module.
        digitalWrite(PIN_RTTY_ENABLE, HIGH);    
        
  rtty_txstring("Booting up.\n");
  // Start up the library
  sensors.begin();
  
  int num_devices = sensors.getDeviceCount();
  
  sprintf(txbuffer,"Found %d sensors.\n",num_devices);
  rtty_txstring(txbuffer);
  
   if (!sensors.getAddress(insideThermometer, 0)) rtty_txstring("Unable to find address for Device 0\n"); 
  if (!sensors.getAddress(outsideThermometer, 1)) rtty_txstring("Unable to find address for Device 1\n"); 
}

void loop(){
    rtty_txstring("Sensor 0: {");
  printAddress(insideThermometer);
  rtty_txstring("}\n");
  
    rtty_txstring("Sensor 1: {");
  printAddress(outsideThermometer);
  rtty_txstring("}\n");
  
  delay(2000);
}

void printAddress(DeviceAddress deviceAddress)
{
  for (uint8_t i = 0; i < 8; i++)
  {
    // zero pad the address if necessary
    char temp[5];
    unsigned int tempbyte = 0;
    tempbyte = deviceAddress[i];
    
    rtty_txstring("0x");
    if (deviceAddress[i] < 16) rtty_txstring("0");
    sprintf(temp, "%X", tempbyte);
    rtty_txstring(temp);
    if (i<7) rtty_txstring(",");
  }
}
