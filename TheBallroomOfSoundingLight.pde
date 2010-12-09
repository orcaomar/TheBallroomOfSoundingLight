// AUDIO STUFF
//
//

import krister.Ess.*;        // import audio library
int NUM_FREQS = 7;  //number of frequency bands - this could eventally be an input parameter with a default value
int AUDIO_X = 300, AUDIO_Y = 580;
FFT myfft;           // create new FFT object (audio spectrum)
AudioInput myinput;  // create input object
int bufferSize=256;  // variable for number of frequency bands
int audioScale;      // variable to control scaing

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
    int a=int(myfft.averages[i]*(-audioScale));
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
    stroke(40);
    strokeWeight(1);
    noFill();
    //line(x,y,x,y+s);
    rect(x-10, y, 20, s+14); //slider body

//    stroke(80);
//    strokeWeight(2);
//    noFill();
//    line(xpos,ypos,xpos,ypos+thesize);

    //noStroke();
    fill(cb);
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
int SMALL = 50;
int MEDIUM = 80;
int LARGE = 100;
int X = 36;
int Y = 28;
int YMID = 240;
int XMID = 410;

Balloon[] leftBalloons = { 
  // small
  new Balloon(0, 140, SMALL, 0),  new Balloon(26, YMID, SMALL, 1),   new Balloon(0, 140 + (YMID - 140)*2, SMALL, 2),
  // top tiny
  new Balloon(140, 0, TINY, 3),  new Balloon( 97,  48, TINY, 4),   new Balloon( 77,  110, TINY, 5), 
  new Balloon(57, 174, TINY, 6),  new Balloon( 157,  53, TINY, 7),   new Balloon( 130,  103, TINY, 8),
  // bottom tiny
  // here i deduced the center line at 240, and reflected the above in that center line
  new Balloon(140, (YMID - 0)*2, TINY, 9),  new Balloon( 97,  48 + (YMID - 48)*2 , TINY, 10),   new Balloon( 77,  110 + (YMID - 110)*2, TINY, 11), 
  new Balloon(57, 174 + (YMID - 174)*2, TINY, 12),  new Balloon( 157,  53 + (YMID - 53)*2, TINY, 13),   new Balloon( 130,  103 + (YMID - 103)*2, TINY, 14),

  // medium
  new Balloon(111, YMID, MEDIUM, 15),
  // small
  new Balloon(144, 166, SMALL, 16), new Balloon( 214,  35, SMALL, 17), 
  // bottom smalls, reflected
  new Balloon(144, 166 + (YMID - 166) * 2, SMALL, 18), new Balloon( 214,  35 + (YMID - 35) * 2, SMALL, 19), 
  // medium
  new Balloon(314, 64, MEDIUM, 20), new Balloon(214, 122, MEDIUM, 21), new Balloon(217, YMID, MEDIUM, 22),
  // bottom mediums
  new Balloon(314, 64 + (YMID - 64)*2, MEDIUM, 23), new Balloon(214, 122 + (YMID-122)*2, MEDIUM, 24),
  // large
  new Balloon(307, 179, LARGE, 25), 
  // bottom large
  new Balloon(307, 179 + (YMID - 179) * 2, LARGE, 26), 
  // tiny
  new Balloon(345, -10, TINY, 27),
  // bottom tiny
  new Balloon(345, -10 + (YMID - (-10))*2, TINY, 28),
};

int LEFT_NUM_BALLOONS = leftBalloons.length;

// center balloons
Balloon[] centerBalloons = { 
  new Balloon(XMID, 12, SMALL, 0 + LEFT_NUM_BALLOONS * 2), new Balloon(XMID, 117, LARGE, 1 + LEFT_NUM_BALLOONS*2),
  // bottom
    new Balloon(XMID, 12 + (YMID - 12)*2, SMALL, 2 + LEFT_NUM_BALLOONS * 2), new Balloon(XMID, 117 + (YMID- 117) * 2, LARGE, 3 + LEFT_NUM_BALLOONS * 2),
};

// TODO(omar): add the two extra balloons on the right?

Balloon[] balloons = new Balloon[leftBalloons.length * 2 + centerBalloons.length];

BalloonTypeSelector[] selectors = {new BalloonTypeSelector(TINY, "Tiny", 30, 560), 
                                   new BalloonTypeSelector(SMALL, "Small", 90, 560), 
                                   new BalloonTypeSelector(MEDIUM, "Medium", 150, 560), 
                                   new BalloonTypeSelector(LARGE, "Large", 210, 560)};

public class Balloon {
  int x, y, diameter, led;
  int freqId = -1;
  int alph = 0;
  Balloon(int x, int y, int diameter, int led) {
    this.x = x;
    this.y = y;
    this.diameter = diameter;
    this.led = led;
  }

  public boolean highlight = false;

  void draw() {
    fill(255, 0, 0, alph);
    ellipse(X + x, Y + y, diameter, diameter);  
    fill(0);
    text(str(led), X + x - 5, Y + y + 5);
    
    // we use a black dot to indicate a balloon is highlighted
    if (highlight) {
      fill(0, 0, 0, 100);
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
  size(XMID*2+100, 1000);
  frameRate(30);
  background(255);
  fill(255);
  smooth();
  
  // create the balloons array
  arrayCopy(leftBalloons, 0, balloons, 0, leftBalloons.length);
  arrayCopy(centerBalloons, 0, balloons, leftBalloons.length * 2, centerBalloons.length);
  
  // now fix up the right balloons by mirroring in the center axis
  for (int i = 0; i < leftBalloons.length; ++i) {
    balloons[i + leftBalloons.length] = new Balloon(balloons[i].x + (XMID - balloons[i].x) * 2, balloons[i].y, balloons[i].diameter, balloons[i].led + leftBalloons.length);
  }
  
  // now setup the audio
  setupAudio();
  
}

void draw() { 
  background(255);
  
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

/*
boolean inColorPickerArea() {
  return (mouseX >= cp.x && 
	mouseX < (cp.x + cp.w) &&
	mouseY >= cp.y &&
	mouseY < (cp.y + cp.h) );
}
*/
// code to send the screen representation of the balloons to the arduino via a serial interface
// see http://processing.org/reference/libraries/serial/Serial.html
Serial arduinoPort;       

// List all the available serial ports:
//println(Serial.list());

// which port has the arduino? right now we comment this out
// arduinoPort = new Serial(this, Serial.list()[0], 9600);


// TODO(omar): right now we send the data for every balloon. It would be easy to mark if a balloon has actually changed since
// last time, and only send its data if it has changed since the last update. BUT not sure if that's needed -- this might
// be fast enough as is.
void sendBalloonData() {
  for (int i = 0; i< balloons.length; ++i) {
    int led = balloons[i].led;
    int r = 0;
    int g = 0;
    int b = 0;
    // write to the arduino in the form [led ID, red, green, blue]
    arduinoPort.write('[');
    arduinoPort.write(led);
    arduinoPort.write(',');
    arduinoPort.write(r);
    arduinoPort.write(',');
    arduinoPort.write(g);
    arduinoPort.write(',');
    arduinoPort.write(b);
    arduinoPort.write(']');
  }
}

// we reserve a special command for telling the arduino to push the data to the LEDs
void refreshLeds() {
  // used L -- where L stands for Load?
  arduinoPort.write('L');
}


// THIS BUTTON CLASS LOOKS REALLY GHETTO. COULD BE MADE PRETTIER
public class GenericButton {
  int x, y;
  String label;
  int WIDTH = 43, HEIGHT = 30;
  
  GenericButton(int x, int y, String label) {
    this.x = x;
    this.y = y;
    this.label = label;
  }
  
  void draw() {
    fill(0xffffff);
    //fill(255);
    rect(x, y, WIDTH, HEIGHT);
    fill(0);
    text(label, x+5, y + 15);
  }

  boolean isPressed() {
    return (mousePressed && mouseX >= x && 
	mouseX < (x + WIDTH) &&
	mouseY >= y &&
	mouseY < (y + HEIGHT));
  }

  void checkPressed() {
    if  (isPressed()) {
      execute();
    }
  }
  
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
   
