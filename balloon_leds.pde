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

public class Balloon {
  int x, y, radius, led;
  color c;
  Balloon(int x, int y, int radius, int led) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.led = led;
    
    c = 0xffffffff;
  }

  public boolean highlight = false;

  void draw() {
    fill(c);
    ellipse(X + x, Y + y, radius, radius);  
    fill(0);
    text(str(led), X + x - 5, Y + y + 5);
    
    // we use a black dot to indicate a balloon is highlighted
    if (highlight) {
      fill(0);
      ellipse(X + x, Y + y, 5, 5);
    }
  }

}

void setup() {
  size(XMID*2+100, 600);
//  frameRate(30);
  frameRate( 100 );
  
  // create the balloons array
  arrayCopy(leftBalloons, 0, balloons, 0, leftBalloons.length);
  arrayCopy(centerBalloons, 0, balloons, leftBalloons.length * 2, centerBalloons.length);
  
  // now fix up the right balloons by mirroring in the center axis
  for (int i = 0; i < leftBalloons.length; ++i) {
    balloons[i + leftBalloons.length] = new Balloon(balloons[i].x + (XMID - balloons[i].x) * 2, balloons[i].y, balloons[i].radius, balloons[i].led + leftBalloons.length);
  }
  
  cp = new ColorPicker( 400, 400, 200, 200, 255 );

}

void draw() { 
  background(204);
  
  cp.render();
  
  highlightSelectedBalloons();
  for (int i = 0; i < balloons.length; ++i) {
    balloons[i].draw();   
  } 
  
  if (mousePressed) {
    drawHighlightRectangle();
  }
}

// mouse handling for highlighting

int startX, endX, startY, endY = 0;
void mousePressed() {
  if (inColorPickerArea()) return;
  startX = mouseX;
  startY = mouseY;
}

void mouseDragged() {
  if (inColorPickerArea()) return;
  endX = mouseX;
  endY = mouseY;
}

void mouseReleased() {
  if (inColorPickerArea()) return;
  endX = mouseX;
  endY = mouseY;
}

void highlightSelectedBalloons() {
  int minX = min(startX, endX);
  int maxX = max(startX, endX);
  int minY = min(startY, endY);
  int maxY = max(startY, endY);
  for (int i = 0; i < balloons.length; ++i) { 
    int x = balloons[i].x;
    int y = balloons[i].y;
    balloons[i].highlight = (x >= minX && x <= maxX && y >= minY && y <= maxY);
  } 
}

void colorHighlightedBalloons(color c) {
  for (int i = 0; i < balloons.length; ++i) { 
    if (balloons[i].highlight) {
       balloons[i].c = c;
    }
  }
}

void drawHighlightRectangle() {
  noFill();
  rect(min(startX, endX), min(startY, endY), abs(startX - endX), abs(startY - endY));
}

boolean inColorPickerArea() {
  return (mouseX >= cp.x && 
	mouseX < (cp.x + cp.w) &&
	mouseY >= cp.y &&
	mouseY < (cp.y + cp.h) );
}

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
    int r = int(red(balloons[i].c));
    int g = int(green(balloons[i].c));
    int b = int(blue(balloons[i].c));
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

// TODO(omar): this color picker is likely overkill -- probably want a more restricted palette
// ColorPicker code from http://www.julapy.com/processing/ColorPicker.pde

ColorPicker cp;

public class ColorPicker 
{
  int x, y, w, h, c;
  PImage cpImage;
  int SELECTED_COLOR_BOX_DIM = 10;
	
  public ColorPicker ( int x, int y, int w, int h, int c )
  {
    
    this.x = x;
    this.y = y + SELECTED_COLOR_BOX_DIM;
    this.w = w;
    this.h = h - SELECTED_COLOR_BOX_DIM;
    this.c = c;
		
    cpImage = new PImage( w, h );
		
    init();
  }
	
  private void init ()
  {
    // draw color.
    int cw = w - 60;
    for( int i=0; i<cw; i++ ) 
    {
      float nColorPercent = i / (float)cw;
      float rad = (-360 * nColorPercent) * (PI / 180);
      int nR = (int)(cos(rad) * 127 + 128) << 16;
      int nG = (int)(cos(rad + 2 * PI / 3) * 127 + 128) << 8;
      int nB = (int)(Math.cos(rad + 4 * PI / 3) * 127 + 128);
      int nColor = nR | nG | nB;
			
      setGradient( i, 0, 1, h/2, 0xFFFFFF, nColor );
      setGradient( i, (h/2), 1, h/2, nColor, 0x000000 );
    }
		
    // draw black/white.
    drawRect( cw, 0,   30, h/2, 0xFFFFFF );
    drawRect( cw, h/2, 30, h/2, 0 );
		
    // draw grey scale.
    for( int j=0; j<h; j++ )
    {
      int g = 255 - (int)(j/(float)(h-1) * 255 );
      drawRect( w-30, j, 30, 1, color( g, g, g ) );
    }
  }

  private void setGradient(int x, int y, float w, float h, int c1, int c2 )
  {
    float deltaR = red(c2) - red(c1);
    float deltaG = green(c2) - green(c1);
    float deltaB = blue(c2) - blue(c1);

    for (int j = y; j<(y+h); j++)
    {
      int c = color( red(c1)+(j-y)*(deltaR/h), green(c1)+(j-y)*(deltaG/h), blue(c1)+(j-y)*(deltaB/h) );
      cpImage.set( x, j, c );
    }
  }
	
  private void drawRect( int rx, int ry, int rw, int rh, int rc )
  {
    for(int i=rx; i<rx+rw; i++) 
    {
      for(int j=ry; j<ry+rh; j++) 
      {
        cpImage.set( i, j, rc );
      }
    }
  }
	
  public void render ()
  {
    image( cpImage, x, y );
    if( mousePressed &&
	mouseX >= x && 
	mouseX < x + w &&
	mouseY >= y &&
	mouseY < y + h )
    {
      c = get( mouseX, mouseY );
      // TODO(omar): the color picker shouldn't be intimately aware of balloons -- rather, when a new color is picked, it should signal to listeners that
      // a new color has been selected. But that is more work than we want to get into for this small project
      colorHighlightedBalloons(c);
    }
    fill( c );
    rect( x, y - SELECTED_COLOR_BOX_DIM, SELECTED_COLOR_BOX_DIM, SELECTED_COLOR_BOX_DIM);
  }
}
