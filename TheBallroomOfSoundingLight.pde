
int NUM_FREQS = 7;  //number of frequency bands - 7 left and 7 right
int audioX = 150, audioY = 450; //initial audio region coordinates
boolean ledCheckMode = false; //mode for checking LEDs one by one


PFont fontA; //global variable for the font
Serial myPort = null; 

int elapsedTime = 0;

int MAX_BANDS = 14;
int BALLOON_MAX_Y = audioY - 45;

// create three slider objects
Slider sliderScale;   //Audio Scaling slider
Slider sliderDamp;   //Damping slider
Slider sliderThreshold; //Threshold slider

AudioFrequencySelector[] audioSelectors;
AudioFrequencySelector audioDeselector;

LedCheckButton ledCheckButton;
LayoutUpdateButton layoutUpdateButton;

void setupAudio() {

  // create selectors for each band
  // 14 bands in total: 7 left and 7 right
  audioSelectors = new AudioFrequencySelector[NUM_FREQS+7];
  for (int i = 0; i < NUM_FREQS; ++i) {
    audioSelectors[i] = new AudioFrequencySelector(audioX + (i*35)+50, audioY + 255, str(i+1), i);
    audioSelectors[i+7] = new AudioFrequencySelector(audioX + ((i+7)*35)+50 + 35, audioY + 255, str(i+1), i+7);
  }
  
  audioDeselector = new AudioFrequencySelector(audioX + 50, audioY + 275, "CLR", MAX_BANDS + 1); //deselect
  
  ledCheckButton = new LedCheckButton (audioX + 50, audioY + 295);
  layoutUpdateButton = new LayoutUpdateButton(audioX + 50, audioY + 315);


  sliderScale=new Slider(audioX - 80,audioY+5,255, 255, "S"); // define slider objects
  sliderDamp=new Slider(audioX -40,audioY+5,255, 255, "D");
  sliderThreshold = new Slider(audioX, audioY+5, 255, 255, "T");
  sliderScale.p=85;   // default position of sliders
  sliderDamp.p=30;
  sliderThreshold.p = 20;
}

void drawAudio() {
  //read in 14 byte array containg 7 left bands (0-6) and 7 right band (7-13)
 
  sendConnectedStatus();
  
  byte[] inBuffer = new byte[15];
  while (myPort.available() >=15) {
    
    int numBytes = myPort.readBytes(inBuffer);
    assert(numBytes == 15);
    if (inBuffer[14] > 0) {
      numBytes = inBuffer[14];
      byte[] data = new byte[numBytes];
      while (myPort.available() < numBytes) {
        delay(1000);
      }
      int readBytes = myPort.readBytes(data);
      assert(numBytes == readBytes);
      if (bandAssign == null || bandAssign.length < numBytes + 1 ) {
        myPort.clear();
        break;
      }
      String errors = "";
      for (int i = 0; i < numBytes; ++i) {
        if (data[i] != bandAssign[i+1]) {
          errors += ("" + i + ": " + data[i] + ", " + bandAssign[i+1] + ". ");
        }
      }
      if (errors.length() > 0) {
        println("ERRORS: " + errors);
        myPort.clear();
      }
    }
   
  }
  pushStyle();
  sliderScale.render();  // render sliders
  sliderDamp.render();
  sliderThreshold.render();
  popStyle();

  //display slider values above sliders
  showSliderValues();

 
  pushStyle();
  for (int band=0; band<7; band++) { // draw equalizer

    fill(255,0,0,int(inBuffer[band]));
    stroke(255,0,0, 100); 
    rect(audioX + (band*35)+50, audioY + 255 ,35, -int(inBuffer[band]));  //draw Left spectrum
    
    
    fill(255,0,0,int(inBuffer[band+7]));
    rect(audioX + ((band+7)*35)+50 + 35, audioY + 255, 35, -int(inBuffer[band+7])); //draw Right spectrum
    
    //draw threshold
    stroke(100);
    line(audioX + 50, (audioY + 255 - sliderThreshold.p), audioX + 50 + (7*35), (audioY + 255 - sliderThreshold.p));
    line(audioX + ((band+7)*35)+50 + 35, (audioY + 255 - sliderThreshold.p), audioX + 50 + 280 + (7*35), (audioY + 255 - sliderThreshold.p));
    

    
    }
  popStyle();
  
   // draw selectors
  for (int i = 0; i < audioSelectors.length; ++i) {
    audioSelectors[i].draw();
    audioSelectors[i].checkPressed();
  }
  
  audioDeselector.draw();
  audioDeselector.checkPressed();
  ledCheckButton.draw();
  ledCheckButton.checkPressed();
  layoutUpdateButton.draw();
  layoutUpdateButton.checkPressed();
  
  text("LEFT", audioX + 50, audioY + 255);
  text("RIGHT", audioX + 50 + 280, audioY + 255);
  
  //pushStyle();
  
  for (int i = 0; i < balloons.length; ++i) {
    int id = balloons[i].freqId;
    if (id < MAX_BANDS) {
      balloons[i].alph =  int(inBuffer[id]);
    } else {
      balloons[i].alph = 0;
    }
  }
  
  
  //popStyle();

}



class Slider { //slider height and slider name not currently implemented
  int x, y, s, p, h;  //x pos, y pos, slider maximum value, slider position, height
  String name;
  boolean slide;
  
  Slider (int x, int y, int s, int h, String name) {
    this.x=x;
    this.y=y;
    this.s=s;
    this.h=h;
    this.name=name;
    p=0;
    slide=true;
    
    
  }

  void render() {
    stroke(100);
    strokeWeight(1);
    noFill();
    
    rect(x-10, y, 20, s+14); //slider body

    fill(150);
    rect(x-10, s-p+y, 20, 14);  //slider button
    
    text(name, x, y+s+30);

    
    if (slide=true && mousePressed==true && mouseX<x+15 && mouseX>x-15){
      if ((mouseY<=y+s+10) && (mouseY>=y-10)) {
        p=(3*p+(s-(mouseY-y)))/4;
        if (p<0) {
          p=0;
        } else if (p>s) {
          p=s;
        }
      }
    }
  }
}
//
//
// END AUDIO STUFF






// TODO(jeff/omar): add better coordinates and all the balloons, along with their associated LED id, here
int TINY = 30;
int SMALL = 45;
int MEDIUM = 60;
int LARGE = 75;
int X = 36;
int Y = 28;
int YMID = 178;
int XMID = 320;


Balloon[] leftTopBalloons = { 
  // small
  new Balloon(136, 0, SMALL),  new Balloon(68, 82, SMALL),   new Balloon(260, 51, SMALL), new Balloon(52, 140, SMALL),
  // top tiny
  new Balloon(275, 2, TINY),  new Balloon( 214,  71, TINY),   new Balloon( 116,  125, TINY), new Balloon( 172,  131, TINY), 
  // top large
  new Balloon(157, 75, MEDIUM),  new Balloon( 212, 10 , MEDIUM),
  new Balloon(250, 132, LARGE)
};

Balloon[] xAxisBalloons = { 
  // small
  new Balloon(0, YMID, TINY),  new Balloon(116, YMID, MEDIUM),   new Balloon(188, YMID, SMALL)
};

Balloon[] yAxisBalloons = { 
  // small
  new Balloon(XMID, 11, SMALL),  new Balloon(XMID, 86, LARGE),
  
  // balloons on the far right of the layout
  new Balloon(560, 30, TINY), new Balloon(630, 110, TINY), new Balloon(700, 105, TINY), new Balloon(680, 30, MEDIUM) 
};

Balloon lonelyBalloon = new Balloon(710, YMID, SMALL);

Balloon fakeSmallBalloon1 = new Balloon(0, 0, SMALL);
Balloon fakeSmallBalloon2 = new Balloon(0, 50, SMALL);
Balloon fakeSmallBalloon3 = new Balloon(0, 100, SMALL);


Balloon[] balloons = new Balloon[leftTopBalloons.length * 4 + xAxisBalloons.length * 2 + yAxisBalloons.length * 2 + 1 + 3];



BalloonTypeSelector[] selectors = {new BalloonTypeSelector(TINY, "2'", 10, 450), 
                                   new BalloonTypeSelector(SMALL, "3'", 10, 490), 
                                   new BalloonTypeSelector(MEDIUM, "4'", 10, 530), 
                                   new BalloonTypeSelector(LARGE, "5'", 10, 570)};

static byte NEXT_BALLOON_LED = 0;

public class Balloon {
  int x, y, diameter;
  int led;
  int freqId = MAX_BANDS + 1;
  int alph = 0;
  int text_width;
  int text_height;
  String dataFromArduino = "omar";
  
  Balloon(int x, int y, int diameter) {
    this.x = x;
    this.y = y;
    this.diameter = diameter;
    this.led = NEXT_BALLOON_LED++;
  }

  public boolean highlight = false;

  void draw() {
    fill(255, 0, 0, alph);
    stroke(66);
    ellipse(X + x, Y + y, diameter, diameter);  
    fill(100);
    
    //text_width = round(textWidth(str(freqId)));
    textAlign(CENTER, CENTER);
    text(str(led), X + x, Y + y +15);
    if (freqId < MAX_BANDS) {
    //String freqIDString = concat(str(freqId+1), "L");
    
    if (freqId < 7) {
        text(str(freqId +1) + "L", X + x, Y + y);
      } else {
        text(str(freqId +1 - 7) + "R", X + x, Y + y);
      }
    }
    
    /*
    byte[] data = {'R', byte(led)};
    myPort.write(data);
    byte[] inData = {'Z'};
    if (myPort.readBytes(inData) == 1) {
      dataFromArduino = str(inData[0]);
      text(dataFromArduino, X +x, Y + y - 15);
    } */
    
    if (highlight) {
      fill(200, 150);
      ellipse(X + x, Y + y, diameter, diameter);
    }
  }

  boolean inBalloon(int mx, int my) {
    int cx = X + x;
    int cy = Y + y;
    float d = sqrt((cx - mx)*(cx-mx) + (cy-my)*(cy-my));
    return d <= diameter / 2;
  }

}

import guicomponents.*;
GTextField titleTextField;
LscSaveButton lscSaveButton;
ArrayList configurations = new ArrayList();


void resetBalloons() {
// create the balloons array
  arrayCopy(leftTopBalloons, 0, balloons, 0, leftTopBalloons.length);
  
  // now fix up the right balloons by mirroring in the center axis
  int L = leftTopBalloons.length;
  for (int i = 0; i < leftTopBalloons.length; ++i) {
    // reflect in X axis, Y axis, and both
    balloons[L + 3*i] = new Balloon(balloons[i].x + (XMID - balloons[i].x) * 2, balloons[i].y, balloons[i].diameter);
    balloons[L + 3*i + 1] = new Balloon(balloons[i].x, balloons[i].y + (YMID - balloons[i].y) * 2, balloons[i].diameter);
    balloons[L + 3*i + 2] = new Balloon(balloons[i].x + (XMID - balloons[i].x) * 2, balloons[i].y + (YMID - balloons[i].y) * 2, balloons[i].diameter);
  }
  
  // y axis balloons
  L = 4 * L;
  arrayCopy(yAxisBalloons, 0, balloons, L, yAxisBalloons.length);
  L = L + yAxisBalloons.length;
  for (int i = 0; i < yAxisBalloons.length; ++i) {
    balloons[L + i] = new Balloon(yAxisBalloons[i].x, yAxisBalloons[i].y + (YMID - yAxisBalloons[i].y) * 2, yAxisBalloons[i].diameter);
  }

  // x axis balloons
  L = L + yAxisBalloons.length;
  arrayCopy(xAxisBalloons, 0, balloons, L, xAxisBalloons.length);
  L = L + xAxisBalloons.length;
  for (int i = 0; i < xAxisBalloons.length; ++i) {
    balloons[L + i] = new Balloon(xAxisBalloons[i].x + (XMID - xAxisBalloons[i].x) * 2, xAxisBalloons[i].y, xAxisBalloons[i].diameter);
  }
  
  balloons[balloons.length - 4] = lonelyBalloon;

  // FAKE BALLOONS FIX THIS
  balloons[balloons.length - 3] = fakeSmallBalloon1;
  balloons[balloons.length - 2] = fakeSmallBalloon2;
  balloons[balloons.length - 1] = fakeSmallBalloon3;


  sortBalloonsArrayBySize();  
}

void setup() {
  import processing.serial.*;
  size(XMID*2+150+300, 800);
  frameRate(18);
  //background(0);
  //fill(255);
  
  fontA = loadFont("Arial-BoldMT-14.vlw");//load font you want from data directory
  textFont(fontA, 14); //all fonts are 14 point Arial
  
  smooth();
  resetBalloons();
  
  // now setup the audio
  setupAudio();
  //set up the serial port
  myPort = new Serial(this, Serial.list()[0], 115200);
  
  waitforSerial(); //doesn't do anything yet
  
  // TELL ME THE # of BALLOONS
 println("THE NUMBER OF BALLOONS IS: " + balloons.length); 
 
  // now print out the text fields
  loadConfigurations();
  titleTextField = new GTextField(this, "Title Here", 800, 10, 100, 20);
  lscSaveButton = new LscSaveButton(910, 10);
}

// this is an inefficient sorting algorithm for making sure the balloons are sorted by LED id. this way, we don't
// need to send the LED id, since we'll always be sending them in order.
void sortBalloonsArrayBySize() {
 ArrayList allBalloons = new ArrayList(balloons.length);
  for (int i = 0; i < balloons.length; ++i) {
    allBalloons.add(balloons[i]);
  }
  
  ArrayList sortedBalloons = new ArrayList(balloons.length);
  while (allBalloons.size() > 0) {
    // find the minimum LED id in the array
    int  maxSize = TINY - 1;
    int minIndex = balloons.length + 1;
    for (byte i = 0; i < allBalloons.size(); ++i) {
      Balloon b = (Balloon)allBalloons.get(i);
      if (maxSize < b.diameter) {
        maxSize = b.diameter;
        minIndex = i;
      }
    }
    sortedBalloons.add(allBalloons.get(minIndex));
    allBalloons.remove(minIndex);    
  }
  
  for (int i = 0; i < sortedBalloons.size(); ++i) {
    balloons[i] = (Balloon)sortedBalloons.get(i);
    balloons[i].led = i;
  }
 
}

void draw() { 
  background(25);
  
  if (mousePressed && !inAudioSelectors() && !inBalloons()) {
    clearHighlightedBalloons();
  }
  
    // now draw the balloon selectors
  for (int i = 0; i < selectors.length; ++i) {
    selectors[i].draw();
    selectors[i].checkPressed();
  }

  for (int i = 0; i < balloons.length; ++i) {
    balloons[i].draw();   
  } 
  
  // now draw audio stuff
  checkSliders();
  
  
  drawAudio();
  
  drawConfigurations();  
  
}

LoadSaveConfigurationView configViews[];

void drawConfigurations() {
  lscSaveButton.draw();
  lscSaveButton.checkPressed();
  configViews = new LoadSaveConfigurationView[configurations.size()];
  int deltaY = 0;
  for (int i = 0; i < configurations.size(); ++i) {
    configViews[i] = new LoadSaveConfigurationView(800, 40 + deltaY, (LoadSaveConfiguration)configurations.get(i));
    configViews[i].draw();
    configViews[i].checkPressed();
    deltaY += 30;
  }
}

void clearHighlightedBalloons() {
  for (int i = 0; i < balloons.length; ++i) {
    balloons[i].highlight = false;   
  }
}

boolean inAudioSelectors() {
  for (int i = 0; i < audioSelectors.length; ++i) {
    if (audioSelectors[i].isPressed()) {
      return true;
    }
  }
  
  if (audioDeselector.isPressed()) {
   return true; 
  }
  
  return false;
}

// TODO: implement
boolean inBalloons() {
  return mouseY < BALLOON_MAX_Y; 
}

// mouse handling for highlighting

int startX, endX, startY, endY = -1;

void resetHighlightAreaBoundingBox() {
  startX = endX = startY = endY = -1;
};

boolean mouseClicked = false;

void mousePressed() {
  // only remember where the highlighting started if we are in the highlight area
  if (mouseY < BALLOON_MAX_Y) {
    highlightSelectedBalloons();
  }
}

void mouseDragged() {
  //if (inColorPickerArea()) return;
  endX = mouseX;
  endY = mouseY;
}

void mouseReleased() {
  resetHighlightAreaBoundingBox();
}


void highlightBalloonLedCheckMode(int balloonIndex) {
  byte[] data = {'D', byte(balloons[balloonIndex].led), balloons[balloonIndex].highlight ? byte(1) : byte(0)};
  myPort.write(data);  
}

void highlightSelectedBalloons() {
  int mx = mouseX;
  int my = mouseY;
  for (int i = 0; i < balloons.length; ++i) { 
    if (balloons[i].inBalloon(mx, my)) {
      balloons[i].highlight = !balloons[i].highlight;
      if (ledCheckMode) {
        highlightBalloonLedCheckMode(i);
      }
      return;
    }
  }
}

void colorHighlightedBalloons(color c) {
  for (int i = 0; i < balloons.length; ++i) { 
    if (balloons[i].highlight) {
//       balloons[i].c = c;
    }
  }
}

void drawHighlightRectangle() {
  if (startX < 0 || startY <0 || endX < 0 || endY < 0) return;
  noFill();
  rect(min(startX, endX), min(startY, endY), abs(startX - endX), abs(startY - endY));
}





// TODO(omar): right now we send the data for every balloon. It would be easy to mark if a balloon has actually changed since
// last time, and only send its data if it has changed since the last update. BUT not sure if that's needed -- this might
// be fast enough as is.
// The format is [ledId1,Alpha1,ledId2, Alpha2 ..etc] but no comma, since each led Id and alpha is exactly 1 byte, so no comma is
// needed.
void updateLEDBoards() {
  //arduinoPort.write('['); //indicates next serial byte will be a led ID
  for (int i = 0; i< balloons.length; ++i) {
    byte led = (byte)balloons[i].led;
    assert(led == i);
    byte level = (byte)balloons[i].alph;    
    // arduinoPort.write(led);
    //arduinoPort.write(level);
  }
  //arduinoPort.write(']'); //completed filling  array with balloon data, now tell Arduino to update boards
}

// we reserve a special command for telling the arduino to push the data to the LEDs
void refreshLeds() {
  // used L -- where L stands for Load?
  //arduinoPort.write('L');
}


// THIS BUTTON CLASS LOOKS REALLY GHETTO. COULD BE MADE PRETTIER
int globalLastButtonPressMs = 0;
int DELAY_BETWEEN_BUTTON_PRESSES = 500;
public class GenericButton {
  int x, y, w, h;
  int buttonfill = 100;
  String label;
  float text_width;
  
  GenericButton(int x, int y, int w, int h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }
  
  GenericButton(int x, int y, String label) {
    this(x, y, 35, 20, label);
  }
  
  void draw() {
    fill(buttonfill);
    //fill(255);
    rect(x, y, w, h);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text_width = textWidth(label);
    text(label, x + round((w-text_width)/2), y + 18); //center text in labels
    
  }

  boolean isPressed() {
    return (mousePressed && mouseX >= x && 
	mouseX < (x + w) &&
	mouseY >= y &&
	mouseY < (y + h));
  }

  void checkPressed() {
    int now = millis();
    if  (isPressed() && (now - globalLastButtonPressMs > DELAY_BETWEEN_BUTTON_PRESSES)) {
      globalLastButtonPressMs = now;
      fill(150); //hightlight button when clicked
      rect(x, y, w, h);
      execute();
    }
  }
/*  //thought I'd try to have some change in the cursor or at least highlight a button when you mouse over it. doesn't work as is.
//I think a shade change is going to be better than a cursor change
boolean mouseOver() {
   return (mouseX >= x && 
	mouseX < (x + WIDTH) &&
	mouseY >= y &&
	mouseY < (y + HEIGHT));
}

void checkOver() {
  if (mouseOver()) {
    cursor(HAND);
  } else {
    cursor(ARROW);
  }
}
*/
  
  void execute() {
  }
}

public class LayoutUpdateButton extends GenericButton {
  LayoutUpdateButton(int x, int y) {
    super(x, y, "UP");
  }
  void execute() {
    writeLayout();
  }  
}

public class LedCheckButton extends GenericButton {
  LedCheckButton(int x, int y) {
    super(x, y, "CHK");
  }
  void execute() {
    ledCheckMode = !ledCheckMode;
    myPort.write(ledCheckMode ? 'C' : 'E');
  }  
}

public class BalloonTypeSelector extends GenericButton{
  int balloonType;
  BalloonTypeSelector(int balloonType, String label, int x, int y) {
    super(x, y, label);  
    this.balloonType = balloonType;
  }
   
  void execute() {
    for (int i = 0; i < balloons.length; ++i) { 
      balloons[i].highlight = (balloons[i].diameter == balloonType);
    }    
  }
}

public class AudioFrequencySelector extends GenericButton{
  int freqId;
  AudioFrequencySelector(int x, int y, String label, int freqId) {
    super(x, y, label);
    this.freqId = freqId;
  }
   
  void execute() {
    for (int i = 0; i < balloons.length; ++i) { 
      if (balloons[i].highlight) {
        balloons[i].freqId = freqId;
      }
    }    
  }
}
void checkSliders() {
  
  if (sliderDamp.slide || sliderScale.slide || sliderThreshold.slide) {
    byte[] sliderValues = new byte[4];
    sliderValues[0] = byte('S'); //first byte is S to indicate slider data is coming in
    sliderValues[1] = byte(sliderDamp.p);
    sliderValues[2] = byte(sliderScale.p);
    sliderValues[3] = byte(sliderThreshold.p);
    myPort.write(sliderValues);
    //myPort.write(sliderScale.p);
    //myPort.write(sliderThreshold.p);
    
  }
  
  
  
}


int numUploads = 0;
byte[] bandAssign;
void writeLayout() { //write balloon freqIDs to serial port
  
  assert (balloons.length == 66);
  bandAssign = new byte[balloons.length + 1];// + 4]; // + 4 for the checksum
  bandAssign[0] = byte('B'); //first byte is B to indicate balloon assignment data is coming in
  //bandAssign[1] = byte(balloons.length); //second byte is the number of balloons.
  for (int i = 0; i < balloons.length; i++) {
   
    bandAssign[i+1] = byte(balloons[i].freqId);
    
  }
  
  /*
  try {
    CRC32 crc = new java.util.zip.CRC32();
    crc.update(bandAssign, 1, balloons.length);
    int checksum = new Long(crc.getValue()).intValue();
    ByteArrayOutputStream bos = new ByteArrayOutputStream();  
    DataOutputStream dos = new DataOutputStream(bos);
    dos.writeInt(checksum);
    dos.flush();  
    byte[] data = bos.toByteArray(); 
    bandAssign[balloons.length + 1] = data[0];
    bandAssign[balloons.length + 2] = data[1];
    bandAssign[balloons.length + 3] = data[2];
    bandAssign[balloons.length + 4] = data[3];
  } catch (Exception e) {
    assert(false);
  }*/
   myPort.write(bandAssign);
  // useful for getting back what was sent out, to see if everything was written correctly. 
  
  println("Wrote band data! " + numUploads++);
  /*byte[] arduinoBandAssign = new byte[balloons.length];
  String errors = "ERRORS: ";
  while (true) {
    if (myPort.available() >= balloons.length) {
      int numBytes = myPort.readBytes(arduinoBandAssign);
      assert(balloons.length == numBytes);
      println("DATA");
      for (int i = 0; i < balloons.length; ++i) {
        print(i + ": " + bandAssign[i+1] + ", " + arduinoBandAssign[i] + "; ");
        if (arduinoBandAssign[i] != bandAssign[i+1]) {
          errors += "" + i + ": " + bandAssign[i+1] + " vs arduino: " + arduinoBandAssign[i];
        }
      }
      println(errors);
      break;
    }
    
    delay(50);
  }*/
}

void  sendConnectedStatus() { //every interval send a signal indicating that Processing is connected
  int interval = 2000;
  int currentTime = millis();
  
  if (currentTime - elapsedTime > interval) {
    
    elapsedTime = currentTime;
    myPort.write('T');
  }
  
}

void waitforSerial() {
  
  
}

void showSliderValues() {
 fill(150);
  float scaleLevel = (sliderScale.p/255.0)*3;
  text(nf(scaleLevel, 1, 1),  audioX - 80, audioY-2);

  float dampLevel = 255.0/(sliderDamp.p + 255.0);
  
  if (dampLevel < 1.0) {
    text(nf(dampLevel, 0, 2).substring(1,4), audioX-40, audioY-2);
  
  } else {
    text(nf(dampLevel, 0, 2).substring(0,3), audioX-40, audioY-2); 
  }
  
  text(sliderThreshold.p, audioX, audioY-2); 
  
}

void stop() {
  //writeLayout();
  myPort.write('X');
  /*delay(5000);
  myPort.clear();
  myPort.stop();
  myPort = null;*/
}

// saving and loading configurations
class LoadSaveConfiguration implements Serializable {
  String title;
  int[] freqIds;
  int scal, damp, thresh;
  
  LoadSaveConfiguration(String title, int[] freqIds, int scal, int damp, int thresh) {
    this.title = title;
    this.freqIds = freqIds;
    this.scal = scal;
    this.damp = damp;
    this.thresh = thresh;
  }
}

public class LscSaveButton extends GenericButton {
  LscSaveButton(int x, int y) {
    super(x, y, "Save");
  }  
  
  void execute() {
    int[] freqIds = new int[balloons.length];
    for (int i = 0; i < balloons.length; ++i) {
      freqIds[i] = balloons[i].freqId;
    }
    configurations.add(new LoadSaveConfiguration(titleTextField.viewText(), freqIds, sliderScale.p, sliderDamp.p, sliderThreshold.p));
    saveConfigurations();
  }
}

public class LscLoadButton extends GenericButton{
  LoadSaveConfiguration lsc;
  LscLoadButton(int x, int y, int w, int h, LoadSaveConfiguration lsc) {
    super(x, y, w, h, lsc.title);
    this.lsc = lsc;
  }
   
  void execute() {
    // set the LEDs, sliders and title
    println("RESETTING and LOADING");
    for (int i = 0; i < balloons.length; ++i) {
      balloons[i].freqId = lsc.freqIds[i];    
    }
    sliderDamp.p = lsc.damp;
    sliderScale.p = lsc.scal;
    sliderThreshold.p = lsc.thresh;
    // force the sliders to send their data
    sliderDamp.slide = true;
    checkSliders();

    titleTextField.setText(lsc.title);    
    
  }
}

public class LscDeleteButton extends GenericButton{
  LoadSaveConfiguration lsc;
  LscDeleteButton(int x, int y, int w, int h, LoadSaveConfiguration lsc) {
    super(x, y, w, h, "Delete");
    this.lsc = lsc;
  }
   
  void execute() {
    configurations.remove(lsc);
    saveConfigurations();
  }
}

class LoadSaveConfigurationView {
  LoadSaveConfiguration lsc;
  LscLoadButton load;
  LscDeleteButton delete;
  
  LoadSaveConfigurationView(int x, int y, LoadSaveConfiguration lsc) {
    this.lsc = lsc;
    load = new LscLoadButton(x, y, 100, 20, lsc);
    delete = new LscDeleteButton(x + 110, y, 40, 20, lsc);
  }

  void draw() {
    load.draw();
    delete.draw();
  }

  void checkPressed() {
    load.checkPressed();
    delete.checkPressed();
  }  
}

String CONFIGURATION_FILE = "audio_configs.data";

void loadConfigurations() {
  try {
     
    FileInputStream fileIn = new FileInputStream(CONFIGURATION_FILE);
    ObjectInputStream in = new ObjectInputStream(fileIn);
    java.util.ArrayList li = (java.util.ArrayList)in.readObject();
    for (int i = 0; i < li.size(); ++i) {
      java.util.HashMap h = (java.util.HashMap)li.get(i);
      LoadSaveConfiguration lsc = new LoadSaveConfiguration((String)h.get("title"), (int[])h.get("freqIds"), (Integer)(h.get("s")), (Integer) h.get("d"), (Integer)h.get("t"));
      configurations.add(lsc);
    }
    
    in.close();
    fileIn.close();
 
  } catch (ClassNotFoundException e) {
      e.printStackTrace();
  } catch(FileNotFoundException e) {
      e.printStackTrace();
  } catch (IOException e) {
      e.printStackTrace();
  }
}

void saveConfigurations() {
  try{
    FileOutputStream fileOut = new FileOutputStream(CONFIGURATION_FILE);
    ObjectOutputStream out = new ObjectOutputStream(fileOut);
    java.util.ArrayList li = new java.util.ArrayList();
    for (int i = 0; i < configurations.size(); ++i) {
      java.util.HashMap h = new java.util.HashMap();
      LoadSaveConfiguration lsc = (LoadSaveConfiguration)configurations.get(i); 
      h.put("freqIds", lsc.freqIds);
      h.put("d", lsc.damp);
      h.put("s", lsc.scal);
      h.put("t", lsc.thresh);
      h.put("title", lsc.title);
      li.add(h);
    }
    out.writeObject(li);
    out.close();
    fileOut.close();
     
  } catch(FileNotFoundException e) {
    e.printStackTrace();
  } catch (IOException e) {
    e.printStackTrace();
  }
}

