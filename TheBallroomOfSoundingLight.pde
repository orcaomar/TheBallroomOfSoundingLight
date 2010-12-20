// AUDIO STUFF
//
//

import krister.Ess.*;        // import audio library
int NUM_FREQS = 7;  //number of frequency bands - this could eventally be an input parameter with a default value
int AUDIO_X = 300, AUDIO_Y = 450;
FFT myfft;           // create new FFT object (audio spectrum)
AudioInput myinput;  // create input object
int bufferSize=256;  // variable for number of frequency bands
int audioScale;      // variable to control scaing

PFont fontA; //global variable for the font



int BALLOON_MAX_Y = AUDIO_Y - 45;

// create two slider objects
slider s1;   //Audio Scaling slider
slider s2;   //Damping slider

AudioFrequencySelector[] audioSelectors;

void setupAudio() {

  Ess.start(this);  // start audio
  myinput=new AudioInput(bufferSize); // define input
  myfft=new FFT(bufferSize*2);        // define fft
  myinput.start();

  myfft.damp(.01);        // damping creates smoother motion
  myfft.equalizer(true);
  myfft.limits(.005,.01);
  myfft.averages(NUM_FREQS);      // controls number of averages
  
  // create selectors for each average
  audioSelectors = new AudioFrequencySelector[NUM_FREQS];
  for (int i = 0; i < NUM_FREQS; ++i) {
    audioSelectors[i] = new AudioFrequencySelector(AUDIO_X + ((NUM_FREQS-i)*43)+50, AUDIO_Y + 255, str(NUM_FREQS-i), i);
  }

  //println("Available serial ports:");  // define 'port' as first
  //println(Serial.list());              // ...available serial port
  //port = new Serial(this, Serial.list()[0], 9600);

  s1=new slider(AUDIO_X,AUDIO_Y,255, color(255,255,255)); // define slider objects
  s2=new slider(AUDIO_X + 50,AUDIO_Y,255, color(255,255,255));
  s1.p=50;   // default position of sliders
  s2.p=200;
}

int getAlpha(int freqId) {
  return int(constrain(myfft.averages[freqId]*audioScale,0,255));
}

void drawAudio() {
  pushStyle();
  s1.render();  // render sliders
  s2.render();
  popStyle();

  // draw selectors
  for (int i = 0; i < audioSelectors.length; ++i) {
    audioSelectors[i].draw();
    audioSelectors[i].checkPressed();
  }

  audioScale=s1.p*20; // adjust audio scale according to slider
  myfft.damp(map(s2.p,0,255,.01,.1)); // adjust daming

  //for (int i=0; i<bufferSize;i++) {  // draw frequency spectrum
    //rect((i*1)+50,330,1,myfft.spectrum[i]*(-audioScale));
  //}
  pushStyle();
  for (int i=0; i<NUM_FREQS; i++) { // draw averages
    int alph = getAlpha(i);
    fill(255,0,0,alph);
    stroke(255,0,0, 100); 
    rect(AUDIO_X + ((NUM_FREQS-i)*43)+50, AUDIO_Y + 255 ,43, -int(constrain(myfft.averages[i]*(audioScale),0,255)));
    //fill(255,0,0);
    //rect((i*43)+50,330+a,43,1);
  }
  
  for (int i = 0; i < balloons.length; ++i) {
    int id = balloons[i].freqId;
    if (id >= 0) {
      balloons[i].alph =  getAlpha(id);
    }
  }
  
  popStyle();
  // write each average to the serial port followed by indicator character
  // the values are constrained from 0 to 255 so the arduino can handle them
  // values above 255 would start back at zero
  //port.write(int(constrain(myfft.averages[0]*audioScale,0,255)));
//  port.write('A');
//  port.write(int(constrain(myfft.averages[1]*audioScale,0,255)));
//  port.write('B');
//  port.write(int(constrain(myfft.averages[2]*audioScale,0,255)));
//  port.write('C');
//  port.write(int(constrain(myfft.averages[3]*audioScale,0,255)));
//  port.write('D');
//  port.write(int(constrain(myfft.averages[4]*audioScale,0,255)));
//  port.write('E');
//  port.write(int(constrain(myfft.averages[5]*audioScale,0,255)));
//  port.write('F');
}

// sets up audio input
public void audioInputData(AudioInput theInput) {
  myfft.getSpectrum(myinput);
}

class slider {
  int x, y, s, p;  //x pos, y pos, slider maximum value, slider position
  boolean slide;
  color c, cb;
  slider (int x, int y, int s, color c) {
    this.x=x;
    this.y=y;
    this.s=s;
    p=0;
    slide=true;
    this.c=c;
    cb=color(red(c),green(c),blue(c),150);
  }

  void render() {
    stroke(100);
    strokeWeight(1);
    noFill();
    //line(x,y,x,y+s);
    rect(x-10, y, 20, s+14); //slider body

//    stroke(80);
//    strokeWeight(2);
//    noFill();
//    line(xpos,ypos,xpos,ypos+thesize);

    //noStroke();
    fill(150);
    rect(x-10, s-p+y, 20, 14);  //slider button
    //fill(c);
    //ellipse(x, s-p+y, 13, 13);

    //text(thesize-dialy,xpos+10,dialy+ypos+5);

    // replace the +'s with double ampersands (web display issues)
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

// used to send data to the arduino
import processing.serial.*;

//println(Serial.list());

// TODO(jeff/omar): add better coordinates and all the balloons, along with their associated LED id, here
int TINY = 30;
int SMALL = 45;
int MEDIUM = 60;
int LARGE = 75;
int X = 36;
int Y = 28;
int YMID = 178;
int XMID = 330;


Balloon[] leftTopBalloons = { 
  // small
  new Balloon(136, 0, SMALL),  new Balloon(68, 82, SMALL),   new Balloon(260, 51, SMALL), new Balloon(52, 140, SMALL),
  // top tiny
  new Balloon(283, 2, TINY),  new Balloon( 214,  71, TINY),   new Balloon( 116,  125, TINY), new Balloon( 172,  131, TINY), 
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
  new Balloon(XMID, 11, SMALL),  new Balloon(XMID, 86, LARGE)
};

// TODO(omar): add the two extra balloons on the right?

Balloon[] balloons = new Balloon[leftTopBalloons.length * 4 + xAxisBalloons.length * 2 + yAxisBalloons.length * 2];

BalloonTypeSelector[] selectors = {new BalloonTypeSelector(TINY, "Tiny", 30, 560), 
                                   new BalloonTypeSelector(SMALL, "Small", 90, 560), 
                                   new BalloonTypeSelector(MEDIUM, "Med", 150, 560), 
                                   new BalloonTypeSelector(LARGE, "Large", 210, 560)};

static byte NEXT_BALLOON_LED = 0;

public class Balloon {
  int x, y, diameter;
  int led;
  int freqId = -1;
  int alph = 0;
  int text_width;
  int text_height;
  
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
    if (freqId >= 0) {
    text(str(NUM_FREQS - freqId), X + x, Y + y);
    }
    
    
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

void setup() {
  //println(Serial.list());
  //arduinoPort = new Serial(this, Serial.list()[0], 115200);
  size(XMID*2+100, 1000);
  frameRate(30);
  background(0);
  //fill(255);
  
  fontA = loadFont("Arial-BoldMT-14.vlw");//load font you want from data directory
  textFont(fontA, 14); //all fonts are 14 point Arial
  
  smooth();
  
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

  sortBalloonsArrayByLed();
  
  // now setup the audio
  setupAudio();
  
}

// this is an inefficient sorting algorithm for making sure the balloons are sorted by LED id. this way, we don't
// need to send the LED id, since we'll always be sending them in order.
void sortBalloonsArrayByLed() {
 ArrayList allBalloons = new ArrayList(balloons.length);
  for (int i = 0; i < balloons.length; ++i) {
    allBalloons.add(balloons[i]);
  }
  
  ArrayList sortedBalloons = new ArrayList(balloons.length);
  while (allBalloons.size() > 0) {
    // find the minimum LED id in the array
    int  minLed = balloons.length + 1;
    int minIndex = balloons.length + 1;
    for (byte i = 0; i < allBalloons.size(); ++i) {
      Balloon b = (Balloon)allBalloons.get(i);
      if (minLed > b.led) {
        minLed = b.led;
        minIndex = i;
      }
    }
    sortedBalloons.add(allBalloons.get(minIndex));
    allBalloons.remove(minIndex);    
  }
  
  for (int i = 0; i < sortedBalloons.size(); ++i) {
    balloons[i] = (Balloon)sortedBalloons.get(i);
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
  
  /*if (mousePressed & mouseY < BALLOON_MAX_Y) {
    drawHighlightRectangle();
  }*/
  
  // now draw audio stuff
  drawAudio();
  if (arduinoPort != null) {
    updateLEDBoards();
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

void highlightSelectedBalloons() {
  int mx = mouseX;
  int my = mouseY;
  for (int i = 0; i < balloons.length; ++i) { 
    if (balloons[i].inBalloon(mx, my)) {
      balloons[i].highlight = !balloons[i].highlight;
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


// code to send the screen representation of the balloons to the arduino via a serial interface
// see http://processing.org/reference/libraries/serial/Serial.html
Serial arduinoPort = null;


// List all the available serial ports:
//println(Serial.list());

// which port has the arduino? right now we comment this out
// arduinoPort = new Serial(this, Serial.list()[0], 9600);


// TODO(omar): right now we send the data for every balloon. It would be easy to mark if a balloon has actually changed since
// last time, and only send its data if it has changed since the last update. BUT not sure if that's needed -- this might
// be fast enough as is.
// The format is [ledId1,Alpha1,ledId2, Alpha2 ..etc] but no comma, since each led Id and alpha is exactly 1 byte, so no comma is
// needed.
void updateLEDBoards() {
  arduinoPort.write('['); //indicates next serial byte will be a led ID
  for (int i = 0; i< balloons.length; ++i) {
    byte led = (byte)balloons[i].led;
    assert(led == i);
    byte level = (byte)balloons[i].alph;    
    // arduinoPort.write(led);
    arduinoPort.write(level);
  }
  arduinoPort.write(']'); //completed filling  array with balloon data, now tell Arduino to update boards
}

// we reserve a special command for telling the arduino to push the data to the LEDs
void refreshLeds() {
  // used L -- where L stands for Load?
  arduinoPort.write('L');
}


// THIS BUTTON CLASS LOOKS REALLY GHETTO. COULD BE MADE PRETTIER
public class GenericButton {
  int x, y;
  int buttonfill = 100;
  String label;
  int WIDTH = 43, HEIGHT = 20;
  float text_width;
  
  

   
  
  GenericButton(int x, int y, String label) {
    this.x = x;
    this.y = y;
    this.label = label;
    
  }
  
  void draw() {
    fill(buttonfill);
    //fill(255);
    rect(x, y, WIDTH, HEIGHT);
    fill(0);
    textAlign(LEFT, BOTTOM);
    text_width = textWidth(label);
    text(label, x + round((WIDTH-text_width)/2), y + 18); //center text in labels
    
  }

  boolean isPressed() {
    return (mousePressed && mouseX >= x && 
	mouseX < (x + WIDTH) &&
	mouseY >= y &&
	mouseY < (y + HEIGHT));
  }

  void checkPressed() {
    if  (isPressed()) {
      fill(150); //hightlight button when clicked
      rect(x, y, WIDTH, HEIGHT);
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
   
