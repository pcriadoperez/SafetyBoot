import controlP5.*;

import processing.serial.*;
import cc.arduino.*;
import org.firmata.*;

//Arduino
Arduino arduino;
int[] pin_motor = {3,5,6,9,10,11};
PImage foot;

//Will create UI using library for size,angle and send wave button
//Values for now

int angleOfWave = 10; // 0 is to the right, 90 is back
int sizeOfWave = 200;
int periodOfWave = 1000; //Time in ms
boolean waveActive = false;
float waveX;
float waveY;
long waveStartTime=0;

float widthOfMotorArray;
float  heightOfMotorArray;

PShape waveCreator;

float motorsCenterX;
float motorsCenterY;


//GUI

ControlP5 cp5;
int angleKnobValue = 100;
int speedSliderValue = 500;
Knob angleKnob;
Knob sizeOfWaveKnob;
Slider speedSlider;

//Processing
Motor[] motors;
ArrowButton leftButton, rightButton, upButton, downButton;
float vibrateLeft_startTime = -100;

void setup()
{
  double timer = millis();
 println("setup() start ");
  //Arudino Setup
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0]);
   

  //Processing Setup
  size(1000, 1000);
  motors= new Motor[6];
  for (int i=0; i<motors.length; i++) {
    if (i%2==0) motors[i] = new Motor(100, 100+110*i, 100);
    else motors[i] = new Motor(210, 100+110*(i-1), 100);
  }
  updateMotorsCenter(); 
  //Wave
  waveCreator = createShape(ELLIPSE, 0 , 0, sizeOfWave, sizeOfWave);
  waveCreator.setVisible(false);
  //Controls
  leftButton = new ArrowButton(500,100,PI/2);
  rightButton = new ArrowButton(600,100,-PI/2);
  upButton = new ArrowButton(550,50,PI);
  downButton = new ArrowButton(550,150,0);
  //Foot image
  foot = loadImage("foot.jpeg");
  
  //GUI
  cp5 = new ControlP5(this);
  
  cp5.addButton("sendWave")
     .setValue(0)
     .setPosition(800,900)
     .setSize(200,50)
     ;
     
     angleKnob = cp5.addKnob("angleKnobValue")
               .setRange(0,360)
               .setValue(270)
               .setPosition(600,700)
               .setRadius(100)
               .setNumberOfTickMarks(360)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
               .setColorForeground(color(255))
               .setColorBackground(color(0, 160, 100))
               .setColorActive(color(255,255,0))
               .setDragDirection(Knob.HORIZONTAL)
               ;
               cp5.addSlider("speedSliderValue")
     .setPosition(500,600)
     .setRange(0,2000)
     .setSize(200,50)
     ;
     
   sizeOfWaveKnob = cp5.addKnob("sizeOfWave")
               .setRange(0,360)
               .setValue(sizeOfWave)
               .setPosition(400,700)
               .setRadius(100)
               .setNumberOfTickMarks(360)
               .setTickMarkLength(4)
               .snapToTickMarks(true)
               .setColorForeground(color(255))
               .setColorBackground(color(0, 160, 100))
               .setColorActive(color(255,255,0))
               .setDragDirection(Knob.HORIZONTAL)
               ;
      println("setup() end: "+ (millis() - timer));
      println("");
      for (int i = 0; i <= 13; i++){
      arduino.pinMode(i, Arduino.OUTPUT);
  }
}


void draw()
{
  double timer = millis();
  println("draw() start");
  background (255, 255, 255);
  image(foot,0,0);
  textSize(14);
  text("frameRate: "+frameRate, 10,10);
  text("frameCount: "+frameCount,10,20);
  text("TimeLapsed: "+frameCount/frameRate,10,30);
  text("Millis: " +millis(),10, 40);
  textSize(32);
  text("Speed: ", 520,580);
  text("Size:", 420, 680);
  text("Angle:", 620,680);
  //Wave Update
  if(waveActive){
    if(millis()- waveStartTime>periodOfWave){
      waveActive = false;
      waveCreator.setVisible(false);
      powerOff();
    }
    else{
      waveCreator.setVisible(true);
      waveCreator.translate(((widthOfMotorArray+2*sizeOfWave)*cos(angleOfWave*PI/180))/(periodOfWave*frameRate/1000), ((heightOfMotorArray+2*sizeOfWave) * sin(angleOfWave*PI/180))/(periodOfWave * frameRate/1000));
      waveX = waveX + ((widthOfMotorArray+2*sizeOfWave)*cos(angleOfWave*PI/180))/(periodOfWave*frameRate/1000);
      waveY = waveY + ((heightOfMotorArray+2*sizeOfWave) * sin(angleOfWave*PI/180))/(periodOfWave * frameRate/1000);
      shape(waveCreator);
      mapPower(waveX, waveY);
    }
  }
  
  //Display Motors
  for (Motor unit : motors) {
    unit.display();
  }
  //Controls
  leftButton.display();
  rightButton.display();
  upButton.display();
  downButton.display();
  
  //UpdateArduino
  updateArduino();
  println("draw() end: "+ (millis()-timer));
  println("");
}

void mouseMoved() {
    mapPower(mouseX, mouseY);
}

void mapPower(float x, float y){
  double timer = millis();
  println("mapPower() start");
 for(Motor unit : motors) {
      float x_distance = x - unit.x;
      float y_distance = y - unit.y;
      float distance = sqrt(sq(x_distance)+sq(y_distance));
      if(distance > sizeOfWave) unit.power = 0;
      else unit.power = 255-int(map(distance, 0 , sizeOfWave, 0, 255));
    } 
    println("mapPower() end: "+ (millis()-timer));
    println("");
}

void mousePressed() {
/*
for (int i=0; i<motors.length; i++) {
    if (overCircle(motors[i].x, motors[i].y, motors[i].size)) {
      arduino.digitalWrite(pin_motor[i], arduino.HIGH);
      motors[i].power=true;
    }
    else {
      arduino.digitalWrite(pin_motor[i], arduino.LOW);
      motors[i].power=false;
    }
  }
  */
  if(overCircle(leftButton.x, leftButton.y, 50)){
     startWave(180,periodOfWave,sizeOfWave);
     
  }
  if(overCircle(upButton.x, upButton.y, 50)){
    startWave(270,periodOfWave,sizeOfWave);
  }
  if(overCircle(downButton.x, downButton.y, 50)){
     startWave(90,periodOfWave,sizeOfWave);
     
  }
  if(overCircle(rightButton.x, rightButton.y, 50)){
    startWave(0,periodOfWave,sizeOfWave);
  }
  if(overCircle(motors[0].x,motors[0].y, 75)){
    
  }
}

void mouseDragged(){
  for(Motor unit:motors){
   if(overCircle(unit.x, unit.y, unit.size)){
     unit.x=mouseX;
     unit.y=mouseY;
     updateMotorsCenter();
  }
  }
}

boolean overRect(float x, float y, float rectWidth, float rectHeight) {
  if(mouseX > x && mouseX <(x+rectWidth) && mouseY>y && mouseY < (rectHeight + y)) return true;
  else return false;
}

boolean overCircle(float x, float y, float diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}
void powerOff(){
  for(Motor unit:motors){
    unit.power=0;
  }
}
void startWave(int angle, int period, int size){
  double timer = millis();
  println("startWave() start");
  waveStartTime = millis();
  waveActive=true;
   angleOfWave = angle;
   periodOfWave = period;
   sizeOfWave = size;
   waveCreator.setVisible(true);
   waveX = motorsCenterX -widthOfMotorArray*cos(angle*PI/180)/2 -sizeOfWave*cos(angle*PI/180);
   waveY=motorsCenterY - heightOfMotorArray*sin(angle*PI/180)/2 - sizeOfWave*sin(angle*PI/180);
   waveCreator = createShape(ELLIPSE,waveX,waveY , size,size);
   println("startWave() end: "+( millis()-timer));
   println("");
}
void delay(int delay){
  double timer = millis();
  println("delay() start");
  int startTime = millis();
  while(millis()-startTime<delay);
  println("delay() end: "+ (millis()-timer));
  println("");
}
void updateArduino(){
  double timer = millis();
  println("supdateArduino() start");
  for(int i=0; i<motors.length; i++){
    arduino.analogWrite(pin_motor[i], motors[i].power);
     //arduino.write(motors[i].power);
    
  }
  
  println("updateArduino() end: "+( millis()-timer));
  println("");
}
void updateMotorsCenter(){
  float mostLeftMotorX = motors[0].x;
  float mostRightMotorX = motors[0].x;
  float mostUpMotorY = motors[0].y;
  float mostDownMotorY = motors[0].y;
  for(Motor unit:motors){
     if(unit.x <mostLeftMotorX) mostLeftMotorX = unit.x;
     if(unit.x>mostRightMotorX) mostRightMotorX = unit.x;
     if(unit.y < mostUpMotorY) mostUpMotorY = unit.y;
     if(unit.y> mostDownMotorY) mostDownMotorY = unit.y;
  }
  motorsCenterX = mostLeftMotorX + (mostRightMotorX-mostLeftMotorX)/2;
  motorsCenterY = mostUpMotorY + (mostDownMotorY - mostUpMotorY)/2;
  widthOfMotorArray = (mostRightMotorX-mostLeftMotorX);
  heightOfMotorArray = (mostDownMotorY - mostUpMotorY);
}
//gUI
public void sendWave(int Event){
 double timer = millis();
  println("sendWave() start");
  startWave(angleKnobValue, speedSliderValue, sizeOfWave);
  println("setup() start: "+ (millis()-timer));
  println("");
}