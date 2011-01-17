
#include <MatrixNet.h>

MatrixNet myMatrix;

int spectrumLeft[7];  //hold left values of audio input
int spectrumRight[7]; //hold right values of audio input
float scale[14]; //array to hold scaled data from spectrum
float damp;// damping factor between 0 and 1. 0.95 works well
float scaler; //scaling value between 0 and 2 to boost or cut levels
int audioDamp = 30;  //damping factor read from 
int audioScale = 85; 
int audioThreshold = 20; ///cutoff threshold to stop LEDs blinking from noise. May need individual cutoff per band
byte spectrumBuffer[14]; //array of spectrum values to send to Processing by serial port
byte powerBoard1[32]; //array for PowerMatrix 1 level values
byte powerBoard2[32]; //array for PowerMatrix 2 level values, currently not used
byte ledBoard[64]; //array for LEDMatrix
byte Band; //frequency bands
int BALLOON_COUNT = 66;
int bandAssign[66]; //array to hold band assignment values
int MAX_BANDS = 14;

boolean processingConnected = false;

int txLEDpin = 6; //pins for transmit and receive status LEDs
int rxLEDpin = 7;

int txLEDstate = LOW;
int rxLEDstate = LOW;

long txTime = 0; //variables to hold millisecond time 
long rxTime = 0;
long blinkTime = 30; //interval between blinks

void setup() {
  
  // We want to preserve the 
  // setBandsUnassigned();
  myMatrix.begin();
  //Setup pins to drive the spectrum analyzer. It needs RESET and STROBE pins.
  pinMode(5, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(txLEDpin, OUTPUT);
  pinMode(rxLEDpin, OUTPUT);
  
  digitalWrite(txLEDpin, LOW);
  digitalWrite(rxLEDpin, LOW);
 

  //Init spectrum analyzer
  digitalWrite(4,LOW);  //pin 4 is strobe on shield
  digitalWrite(5,HIGH); //pin 5 is RESET on the shield
  digitalWrite(4,HIGH);
  digitalWrite(4,LOW);
  digitalWrite(5,LOW);

  chksum_crc32gentab();
  
  //Start serial communication
  Serial.begin(115200); 
  
  waitforSerial();
  
}


// Function to read 7 band equalizers

unsigned long lastBandAssignMs = 0;

void loop() {
  //digitalWrite(txLEDpin, LOW);
  //calculate damping, audio scaling values from serial input
  damp = 255.0/(audioDamp + 255.0);
  scaler = (audioScale/255.0)*3; //maximum 3X boost
  
  //Band 0 = Lowest Frequencies.
  //load the latest frequency band levels.
  
  //digitalWrite(5, HIGH);
  //digitalWrite(5, LOW);
  for(Band=0;Band <7; Band++) {
    
    int bufferLeft = analogRead(0);
    int bufferRight = analogRead(1);
    
    //this is an attempt to damp the amplitudes. if the old level is greater than the current level, then use the old level 
    //multiplied by a decay factor
    if (spectrumLeft[Band] > bufferLeft) {
      
      spectrumLeft[Band] = int(spectrumLeft[Band]*damp);
      
      
    } else { //if the old level is less than the new level, then use the new level
      
      spectrumLeft[Band] = bufferLeft;
      
    }
    //do the same for the Right spectrum
    if(spectrumRight[Band] > bufferRight) {
      
      
      spectrumRight[Band] = int(spectrumRight[Band]*damp);
    
    } else {
      
      spectrumRight[Band] = bufferRight;
    
    }
    
    //scale to 255
    scale[Band] = ((spectrumLeft[Band]) / 1023.0) * 255;
    scale[Band+7] = ((spectrumRight[Band]) / 1023.0) * 255; //store Right bands in second half of array
    //load interger values into buffer for sending by Serial
    // clean up all audio signals below the audio threshold -- simply clamp them to zero.
    if (scale[Band] < audioThreshold) {
      spectrumBuffer[Band] = 0;
    } else {
      spectrumBuffer[Band] = int(constrain((scale[Band]*scaler), 0, 255));
    }
    
    if (scale[Band + 7] < audioThreshold) {
      spectrumBuffer[Band + 7] = 0;
    } else {
      spectrumBuffer[Band+7] = int(constrain((scale[Band+7]*scaler), 0, 255));
    }
    
    digitalWrite(4,HIGH);  //Strobe pin on the shield
    digitalWrite(4,LOW);  
   
  }

   //send 7 bands to first 7 LEDs in temporary prototype setup
   //sendSeven();
   if (processingConnected) {
     Serial.write(spectrumBuffer, 14); //write the spectrum values to the serial port
   }
   unsigned long now = millis();
   if (now - lastBandAssignMs > 10000) {
     lastBandAssignMs = now;
     byte data[BALLOON_COUNT + 1];
     data[0] = BALLOON_COUNT;
     for (int i = 0; i < BALLOON_COUNT; i++) { //read new values into bandAssign array
       data[i+1] = bandAssign[i];
       if (!processingConnected) {
         Serial.print(data[i+1], DEC);
         Serial.print(',');
       }
     }
     if (!processingConnected) {
       Serial.println(' ');
     } else {
       Serial.write(data, BALLOON_COUNT + 1);
     }
   } else {
     Serial.write(0, 1);
   }
   if (processingConnected) { //if processing is connected then blink the tx LED
     blinkTransmitLED();
   } else {
       digitalWrite(txLEDpin, LOW); //otherwise, turn it off
   }
   //digitalWrite(txLEDpin, HIGH);
   loadLevelArrays();
   updateBoards();
   
   checkSerial();
}

void checkSerial() { //check for Serial activity and update 

  if (Serial.available() <= 0) { //if not serial available make sure LED is off
    
    digitalWrite(rxLEDpin, LOW);
    
  }
  while (Serial.available() > 0) {
    blinkReceiveLED();
    byte firstByte = Serial.read();
    
    if (firstByte == 'X') { // Processing exited
      processingConnected = false;
      //Serial.flush();
      //delay(1000);
    } else if (firstByte == 'T') { // Processing is running
      processingConnected = true;
      //Serial.begin(112500);
      //delay(1000);
    }
    
    if (!processingConnected) { // bogus data can end up on the serial line, and we should ignore all of it if processing isn't running
      // we should not be getting data now .. send it back
      // 
      /*byte data[] = {'\n', 'B', 'A', 'D','N','C', firstByte};
      Serial.write(data, 7);
      Serial.flush();*/
      continue;
      
    }
    
    if (firstByte == 'S') { //read in slider values  
      audioDamp = Serial.read();
      audioScale = Serial.read();
      audioThreshold = Serial.read(); 
    } else if (firstByte == 'B') { //read in balloon band assignment array
      getNewLayout();
    } else if (firstByte == 'C') { //enter LED check mode
      enterLEDCheckMode();
    } else if (firstByte == 'R') { // R for replay the data you have back to us
      int balloon = Serial.read();
      byte data[] = {bandAssign[balloon]};
      //Serial.write(data, 1);
    } else {
      // something very bad happened
      // we set all the LEDs off and send the byte back to the processing
      /*byte data[] = {'\n', 'B', 'A', 'D', 'C', firstByte};
      Serial.write(data, 6);
      Serial.flush();*/
    }
      
    
    
    /*
    Serial.print(audioDamp);
    Serial.print(' ');
    Serial.print(audioScale);
    Serial.print(' ');
    Serial.println(audioThreshold);
    */
    
    
  }
  
   //digitalWrite(rxLEDpin, LOW); //when serial isn't available turn rxLED off
  
}

void getNewLayout() {
 while (Serial.available() < BALLOON_COUNT) { // + 4) {
   delay(10);
 } 
 
 if (!processingConnected) {
   Serial.println(999, DEC);
 }
 
 // put back the "data" stuff if you want to send data about what was written. useful for debugging, but can only work
 // if other data, namely AUDIO data writing, is disabled.
 // byte data[BALLOON_COUNT];
 for (int i = 0; i < BALLOON_COUNT; i++) { //read new values into bandAssign array
   bandAssign[i] = Serial.read();
   //data[i] = bandAssign[i]; 
 }

/*
 unsigned long checksum = chksum_crc32(bandAssign, BALLOON_COUNT);
 byte b_checksum[4] = {(&checksum)[0]};
 for (int i = 0; i < 4; ++i) {
   if (((byte*)(&checksum))[i] != Serial.read() ) {
     setBandsUnassigned();
     delay(60*1000);
   }
 }
 */
 
 //Serial.write(data, BALLOON_COUNT);
 
 //digitalWrite(rxLEDpin, LOW);
}
 

byte getSpectrumFromBandAssignment(int bandAssignmentIndex) {
  int i = bandAssign[bandAssignmentIndex];
  if (i >= MAX_BANDS) {
    return 0;
  } else {
    return spectrumBuffer[i];
  }
}
 
void loadLevelArrays() { //load level values into Matrix arrays 

 for (int i = 0; i < 6; i++) { //get first 12 values for six 2 LED balloons
     
    powerBoard1[2*i] = powerBoard1[2*i + 1] = getSpectrumFromBandAssignment(i);
    
  }
  
  for (int i = 6; i < 26; i++) {

    powerBoard1[i+6] = getSpectrumFromBandAssignment(i);
    
  } //first board array is now full with data for first 26 baloons. 6 5ft (0-5), 12 4ft (6-17), 8 3ft (18-25);
  
  /*
  for (int i = 26; i < 58; i++ {
  
    powerBoard2[i-26] =spectrumBuffer[bandAssign[i]];
    
  } //second board array now full 
  
  */
  
  for (int i = 26; i < 42; i++) {
    
    powerBoard2[i-26] = getSpectrumFromBandAssignment(i); 
  }
  // TODO: are there going to be 21 or 24 3' balloons?
  //powerBoard2 has 16 LEDs, for remaing 16 3 ft baloons (24 total)
  
  for (int i = 42; i < 66; i++) {
    
    ledBoard[i-42] = getSpectrumFromBandAssignment(i);
  }
 //LEDBoard has 24 LEds
  
}  


void updateBoards() {
 
   myMatrix.changePowerBoard(0, powerBoard1);
   delay(5);
   myMatrix.changePowerBoard(1, powerBoard2);
   delay(5);
   myMatrix.changeLEDBoard(2, ledBoard, ledBoard, ledBoard);
   delay(5);
   /*
   byte fullOn[64];
   
   for (int i = 0; i < 64; i++) {
     
     fullOn[i] = 255;
     
   }
   
   myMatrix.changeLEDBoard(2, fullOn , fullOn, fullOn);
  delay(10);
  */
}


void setBandsUnassigned() { //rest all LED levels to 0
  for (int i = 0; i < BALLOON_COUNT; ++i) {
    bandAssign[i] = MAX_BANDS + 1;
  }
}

void enterLEDCheckMode() {
  digitalWrite(rxLEDpin, HIGH); //turn rx LED on to indicate LEDCheckMode is active
  digitalWrite(txLEDpin, LOW);  //turn off tx LED
  //set all LEDs to zero
  setBandsUnassigned();
  
  byte serialIn = Serial.read();
  
  while (serialIn != 'E') { //'E' indicates end
    if (serialIn == 'S') {
      audioDamp = Serial.read();
      audioScale = Serial.read();
      audioThreshold = Serial.read(); 
    } else if (serialIn == 'D') {
      byte led = Serial.read();
      byte on = Serial.read();
      if (on != 0) {
        bandAssign[led] = 0; // put the scaler value into band 0 
      } else {
        bandAssign[led] = MAX_BANDS + 1;
      }
    }
    
    spectrumBuffer[0] = audioThreshold; // while in check mode, the spectrum is ONLY the audio scaler value, not the true audio
    serialIn = Serial.read();
    
    // display what the user sent in check mode
    loadLevelArrays();
    updateBoards();  
  }
  
  // leaving check mode, reset everything
  setBandsUnassigned();
}
  
  


void blinkTransmitLED() { // uses Arduino tutorial 'Blink without Delay' example
  unsigned long currentTime = millis();
  
  if (currentTime - txTime > blinkTime) {
     
     txTime = currentTime;
    
     if (txLEDstate == LOW) {
        txLEDstate = HIGH;
     } else {
        txLEDstate = LOW;
     } 
     
     digitalWrite(txLEDpin, txLEDstate);
  }
  
  
}

void blinkReceiveLED() { // uses Arduino tutorial 'Blink without Delay' example
  unsigned long currentTime = millis();
  
  if (currentTime - rxTime > blinkTime) {
     
     rxTime = currentTime;
    
     if (rxLEDstate == LOW) {
        rxLEDstate = HIGH;
     } else {
        rxLEDstate = LOW;
     } 
     
     digitalWrite(rxLEDpin, rxLEDstate);
  }
  
}

void waitforSerial() {
  
}
    
/* crc_tab[] -- this crcTable is being build by chksum_crc32GenTab().
 *		so make sure, you call it before using the other
 *		functions
 */

unsigned long crc_tab[256];



/* chksum_crc() -- to a given block, this one calculates the
 *				crc32-checksum until the length is
 *				reached. the crc32-checksum will be
 *				the result.
 */

unsigned long chksum_crc32 (int *block, unsigned int length)

{

   unsigned long crc;

   unsigned long i;



   crc = 0xFFFFFFFF;

   for (i = 0; i < length; i++)

   {

      crc = ((crc >> 8) & 0x00FFFFFF) ^ crc_tab[(crc ^ *block++) & 0xFF];

   }

   return (crc ^ 0xFFFFFFFF);

}



/* chksum_crc32gentab() --      to a global crc_tab[256], this one will

 *				calculate the crcTable for crc32-checksums.

 *				it is generated to the polynom [..]

 */



void chksum_crc32gentab ()

{

   unsigned long crc, poly;

   int i, j;



   poly = 0xEDB88320L;

   for (i = 0; i < 256; i++)

   {

      crc = i;

      for (j = 8; j > 0; j--)

      {

	 if (crc & 1)

	 {

	    crc = (crc >> 1) ^ poly;

	 }

	 else

	 {

	    crc >>= 1;

	 }

      }

      crc_tab[i] = crc;

   }

}

  
  


