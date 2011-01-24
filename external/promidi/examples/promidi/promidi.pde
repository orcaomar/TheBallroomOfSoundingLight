import promidi.*;

MidiIO midiIO;

void setup(){
  size(128,128 + 20);
  smooth();
  background(0);
  
  //get an instance of MidiIO
  midiIO = MidiIO.getInstance(this);
  println("printPorts of midiIO");
  
  //print a list of all available devices
  midiIO.printDevices();
  
  //open the first midi channel of the first device
  midiIO.openInput(0,0);
}

void draw(){
  //nothing to do here

}
/*
void noteOn(Note note, int device, int channel){
  int vel = note.getVelocity();
  int pit = note.getPitch();
  
  fill(255,vel*2,pit*2,vel*2);
  stroke(255,vel);
  ellipse(vel*5,pit*5,30,30);
}

void noteOff(Note note, int device, int channel){
  int pit = note.getPitch();
  
  fill(255,pit*2,pit*2,pit*2);
  stroke(255,pit);
  ellipse(pit*5,pit*5,30,30);
}
*/
void controllerIn(Controller controller, int device, int channel){
  background(0);
  int num = controller.getNumber();
  int val = controller.getValue();
  //pushStyle();
  //fill(255,num*2,val*2,num*2);
  stroke(255);
  //rect(num,val,5,5);
  text(num + " " + val, num, val+15);
  
  //popStyle();
}
/*
void programChange(ProgramChange programChange, int device, int channel){
  int num = programChange.getNumber();
  
  fill(255,num*2,num*2,num*2);
  stroke(255,num);
  ellipse(num*5,num*5,30,30);
}
*/
