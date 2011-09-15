#define ASCII_LENGTH 7

char txBuffer[200];

volatile boolean txLock = false;
volatile int current_tx_byte = 0;
volatile short current_byte_position;
// Always useful to have an interrupt counter.
volatile int interruptCount = 0;

void rtty_tx_interrupt(){
  interruptCount++;
  if(txLock){
          
      // Pull out current byte
      char current_byte = txBuffer[current_tx_byte];
      
      // Null character? Finish transmitting
      if(current_byte == 0){
         txLock = false;
         return;
      }
      
      int current_bit = 0;
      
      if(current_byte_position == 0){ // Start bit
          current_bit = 0;
      }else if(current_byte_position == (ASCII_LENGTH + 1)){ // Stop bit
          current_bit = 1;
      }else{ // Data bit
       current_bit = 1&(current_byte>>(current_byte_position-1));
      }
      
      
      // Transmit!
      txbit(current_bit);
      
      // Increment all our counters.
      current_byte_position++;
      
      if(current_byte_position==(ASCII_LENGTH + 2)){
          current_tx_byte++;
          current_byte_position = 0;
      }
  }
}

void rtty_txstring(char *string){
  if(txLock == false){
    strcpy(txBuffer, string);
    current_tx_byte = 0;
    current_byte_position = 0;
    txLock = true;

  }
}

void waitForTX(){
    while(txLock){}
}

void resetInterruptCount(){
    interruptCount = 0;
}

void waitForCount(int value){
    while(interruptCount<value){}
}
