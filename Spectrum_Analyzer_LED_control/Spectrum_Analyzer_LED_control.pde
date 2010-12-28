
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
int bandAssign[128]; //array to hold band assignment values
int balloonNumber;


  
void setup() {
  
  myMatrix.begin();
  //Setup pins to drive the spectrum analyzer. It needs RESET and STROBE pins.
  pinMode(5, OUTPUT);
  pinMode(4, OUTPUT);
 

  //Init spectrum analyzer
  digitalWrite(4,LOW);  //pin 4 is strobe on shield
  digitalWrite(5,HIGH); //pin 5 is RESET on the shield
  digitalWrite(4,HIGH);
  digitalWrite(4,LOW);
  digitalWrite(5,LOW);
  Serial.begin(115200); 
  
}


// Function to read 7 band equalizers
 
void loop() {
  
  //calculate damping, audio scaling values from serial input
  damp = 255.0/(audioDamp + 255.0);
  scaler = (audioScale/255.0)*3; //maximum 3X boost
  
  //Band 0 = Lowest Frequencies.
  //load the latest frequency band levels.
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
      
      //damp = audioDamp
      spectrumRight[Band] = int(spectrumRight[Band]*damp);
    
    } else {
      
      spectrumRight[Band] = bufferRight;
    
    }
    
    //scale to 255
    scale[Band] = ((spectrumLeft[Band]) / 1023.0) * 255;
    scale[Band+7] = ((spectrumRight[Band]) / 1023.0) * 255; //store Right bands in second half of array
    //load interger values into buffer for sending by Serial
    spectrumBuffer[Band] = int(constrain((scale[Band]*scaler), 0, 255));
    spectrumBuffer[Band+7] = int(constrain((scale[Band+7]*scaler), 0, 255));
    
    digitalWrite(4,HIGH);  //Strobe pin on the shield
    digitalWrite(4,LOW);  
   
  }
  
 
    
    
  
  //load 7 Left bands into Matrix arrays. if the value is below the threshold then set the LED to 0. this is to
  //prevent flickering from line noise when audio is not playing
  if (int(scale[0]) > audioThreshold) {
    
    powerBoard1[0] = int(spectrumBuffer[0]);
  } else {
    powerBoard1[0] = 0;
  }
    
  if (int(scale[1]) > audioThreshold) {
    
    powerBoard1[1] = int(spectrumBuffer[1]);
  } else {
    powerBoard1[1] = 0;
  }
  
  for (Band = 2; Band <7; Band++) {
    
    if (int(scale[Band]) > audioThreshold) {
    
    ledBoard[Band - 2] = int(spectrumBuffer[Band]);
    } else {
      ledBoard[Band - 2] = 0;
    }
      
  }
  
   //send scaled Spectrum values to Processing
   Serial.write(spectrumBuffer, 14); //write the spectrum values to the serial port
   myMatrix.changePowerBoard(0, powerBoard1);
   delay(10); //what is the minimum delay? 7ms? 5ms?
   myMatrix.changeLEDBoard(1, ledBoard, ledBoard, ledBoard);
   delay(10);
   checkSerial();
}

void checkSerial() { //check for Serial activity and update 

  while (Serial.available() >= 4) {
    byte firstByte = Serial.read();
    
    if (firstByte == 'S') { //read in slider values
    
    audioDamp = Serial.read();
    audioScale = Serial.read();
    audioThreshold = Serial.read();
    
    } else if (firstByte == 'B') { //read in balloon band assignment array
    
      getNewLayout();
    
    } else if (firstByte == 'C') { //enter LED check mode
    
       enterLEDCheckMode();
    }
    /*
    Serial.print(audioDamp);
    Serial.print(' ');
    Serial.print(audioScale);
    Serial.print(' ');
    Serial.println(audioThreshold);
    */
    
    
  }
  
}

void getNewLayout() {
 
  balloonNumber = Serial.read(); //second byte is the number of balloons
 for (int i = 0; i < balloonNumber; i++) { //read new values into bandAssign array
 
   bandAssign[i] = Serial.read();
   
 }
  
   
  }
 
 
void loadLevelArrays() { //load level values into Matrix arrays - still need to work in Threshold with if/else statement

 for (int i = 0; i < 6; i++) { //get first 12 values for six 2 LED balloons
     
    powerBoard1[2*i] = powerBoard1[2*i + 1] = spectrumBuffer[bandAssign[i]];
    
  }
  
  for (int i = 6; i < 26; i++) {

    powerBoard1[i+6] = spectrumBuffer[bandAssign[i]];
    
  } //first board array is now full with data for first 26 baloons. 6 5ft (0-5), 12 4ft (6-17), 8 3ft (18-25);
  
  /*
  for (int i = 26; i < 58; i++ {
  
    powerBoard2[i-26] =spectrumBuffer[bandAssign[i]];
    
  } //second board array now full 
  
  */
  
  for (int i = 26; i < 42; i++) {
    
    powerBoard2[i-26] = spectrumBuffer[bandAssign[i]]; 
  }
  //powerBoard2 has 16 LEDs, for remaing 16 3 ft baloons (24 total)
  
  for (int i = 42; i < 66; i++) {
    
    ledBoard[i-42] = spectrumBuffer[bandAssign[i]];
  }
 //LEDBoard has 24 LEds
  
}  


void updateBoards() {
 
   myMatrix.changePowerBoard(0, powerBoard1);
   delay(10);
   myMatrix.changePowerBoard(1, powerBoard2);
   delay(10);
   myMatrix.changeLEDBoard(2, ledBoard, ledBoard, ledBoard);
   delay(5);
  
}


void setBoardstoZero() { //rest all LED levels to 0
  for (int i = 0; i < 32; i++) {
    powerBoard1[i] = 0;
    powerBoard2[i] = 0;
    ledBoard[i] = 0;
    ledBoard[i+32] = 0;
  }
  
  updateBoards();

   
  
}

void enterLEDCheckMode() {
  
  //set all LEDs to zero
  setBoardstoZero();
  
  byte serialIn = 0;
  
  while (serialIn != 'E') { //'E' indicates end
    
  serialIn = Serial.read();
  
  
  
  
  }
  
  
  
  }
    
  
  


