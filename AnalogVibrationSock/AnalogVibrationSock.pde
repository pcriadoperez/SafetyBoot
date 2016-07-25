import controlP5.*;

import processing.serial.*;


//Arduino
Serial myPort;
PImage leftBoot;
PImage rightBoot;
PImage manIcon;

//Will create UI using library for size,angle and send wave button
//Values for now

int angleOfWave = 10; // 0 is to the right, 90 is back
int sizeOfWave = 200;
int periodOfWave = 1000; //Time in ms
boolean waveActive = false;
float waveX;
float waveY;
long waveStartTime=0;
float mouseAngle;
float angleThreshold = HALF_PI;
PVector manIconLocation = new PVector(600, 350);

double squareTimeChange=0;
int squareDurationOn=150;
int squareDurationOff=75;
boolean squareHigh=false;

float widthOfMotorArray;
float  heightOfMotorArray;

PShape waveCreator;
float motorsCenterX;
float motorsCenterY;

PVector wavePoint, waveRect, waveNormal , translation;
int distanceBetweenShoes= 550;

//GUI

ControlP5 cp5;
int angleKnobValue = 100;
int speedSliderValue = 500;
Knob angleKnob;
Knob sizeOfWaveKnob;
Slider speedSlider;
boolean radialMode = true;
//Processing
Motor[] motors;
ArrowButton leftButton, rightButton, upButton, downButton, upLeftButton, upRightButton;
float vibrateLeft_startTime = -100;

void setup()
{
  translation = new PVector();
  double timer = millis();
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);

  //Processing Setup
  size(1200, 1000);
  motors= new Motor[12];
  for (int i=0; i<motors.length; i++) {
    if (i%2==0) motors[i] = new Motor(100, 100+80*i, 75);
    else motors[i] = new Motor(210, 100+80*(i-1), 75);
  }
  updateMotorsCenter(); 
  //Wave
  waveCreator= createShape(RECT, 0, 0, sizeOfWave, sizeOfWave);
  waveCreator.setVisible(false);
  //Controls
  leftButton = new ArrowButton(500, 100, PI/2);
  upLeftButton = new ArrowButton(550, 75, PI*3/4);
  rightButton = new ArrowButton(700, 100, -PI/2);
  upRightButton = new ArrowButton(650, 75, -PI*3/4);
  upButton = new ArrowButton(600, 50, PI);
  downButton = new ArrowButton(600, 150, 0);
  //Foot image
  rightBoot = loadImage("rightBoot.png");
  leftBoot = loadImage("leftBoot.png");
  manIcon = loadImage("man-icon.png");
  //GUI
  cp5 = new ControlP5(this);

  cp5.addButton("sendWave")
    .setValue(0)
    .setPosition(800, 900)
    .setSize(200, 50)
    ;

  angleKnob = cp5.addKnob("angleKnobValue")
    .setRange(0, 360)
    .setValue(270)
    .setPosition(600, 700)
    .setRadius(100)
    .setNumberOfTickMarks(360)
    .setTickMarkLength(4)
    .snapToTickMarks(true)
    .setColorForeground(color(255))
    .setColorBackground(color(0, 160, 100))
    .setColorActive(color(255, 255, 0))
    .setDragDirection(Knob.HORIZONTAL)
    ;
    angleKnob = cp5.addKnob("squareDurationOff")
    .setRange(0, 1000)
    .setValue(250)
    .setPosition(825, 700)
    .setRadius(50)
    .setNumberOfTickMarks(360)
    .setTickMarkLength(4)
    .snapToTickMarks(true)
    .setColorForeground(color(255))
    .setColorBackground(color(0, 160, 100))
    .setColorActive(color(255, 255, 0))
    .setDragDirection(Knob.HORIZONTAL)
    ;
    angleKnob = cp5.addKnob("squareDurationOn")
    .setRange(0, 1000)
    .setValue(250)
    .setPosition(950, 700)
    .setRadius(50)
    .setNumberOfTickMarks(360)
    .setTickMarkLength(4)
    .snapToTickMarks(true)
    .setColorForeground(color(255))
    .setColorBackground(color(0, 160, 100))
    .setColorActive(color(255, 255, 0))
    .setDragDirection(Knob.HORIZONTAL)
    ;
  cp5.addSlider("speedSliderValue")
    .setPosition(500, 600)
    .setRange(0, 10000)
    .setSize(200, 50)
    ;
    cp5.addToggle("radialMode")
     .setPosition(800,600)
     .setSize(50,20)
     .setValue(true)
   ;

  sizeOfWaveKnob = cp5.addKnob("sizeOfWave")
    .setRange(0, 360)
    .setValue(sizeOfWave)
    .setPosition(400, 700)
    .setRadius(100)
    .setNumberOfTickMarks(360)
    .setTickMarkLength(4)
    .snapToTickMarks(true)
    .setColorForeground(color(255))
    .setColorBackground(color(0, 160, 100))
    .setColorActive(color(255, 255, 0))
    .setDragDirection(Knob.HORIZONTAL)
    ;
  println("setup() end: "+ (millis() - timer));
  println("");
}


void draw()
{
  println(waveCreator.getVertexCount());
  if (myPort.available()>0) println(myPort.readBytes());
  double timer = millis();
  println("draw() start");
  background (255, 255, 255);
  image(rightBoot, width/2, 0, width/2, rightBoot.height*width/(2*rightBoot.width));
  image(leftBoot, 0, 0, width/2, leftBoot.height*width/(2*leftBoot.width));
  fill(100,100);
  noStroke();
  if(radialMode) {
    arc(manIconLocation.x, manIconLocation.y , 1000,1000, mouseAngle - angleThreshold, mouseAngle + angleThreshold);
    image(manIcon, manIconLocation.x-25, manIconLocation.y-25, 50,50);
  }
  textSize(14);
  text("frameRate: "+frameRate, 10, 10);
  text("frameCount: "+frameCount, 10, 20);
  text("TimeLapsed: "+frameCount/frameRate, 10, 30);
  text("Millis: " +millis(), 10, 40);
  textSize(32);
  text("Speed: ", 520, 580);
  text("Size:", 420, 680);
  text("Angle:", 620, 680);
  text("HZ OFF:", 800, 680);
  text("HZ ON:", 1000, 680);
  //Wave Update
  if (waveActive) {
    if (millis()- waveStartTime>periodOfWave) {
      waveActive = false;
      waveCreator.setVisible(false);
      powerOff();
    } else {
      waveCreator.setVisible(true);
      waveCreator.translate(0, width/(periodOfWave * frameRate/1000));
      wavePoint.add(PVector.mult(waveNormal, width/(periodOfWave * frameRate/1000)));
      shape(waveCreator, width/2, height/2);
      mapWavePower();
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
  upRightButton.display();
  upLeftButton.display();

  //UpdateArduino
  updateArduino();
  println("draw() end: "+ (millis()-timer));
  println("");
}

void mouseMoved() {
  if(radialMode){
    mouseAngle = PVector.angleBetween(new PVector(mouseX - manIconLocation.x, mouseY- manIconLocation.y), new PVector(1,0));
    if(mouseY<manIconLocation.y)mouseAngle = -mouseAngle;
    //anglePower();
  }
  else mapPower(mouseX, mouseY);
  println(radialMode);
}


void mapPower(float x, float y) {
  for (Motor unit : motors) {
    float x_distance = x - unit.x;
    float y_distance = y - unit.y;
    float distance =sqrt(sq(x_distance)+sq(y_distance)) ;
    if (distance > sizeOfWave) unit.power = 0;
    else unit.power = 255-int(map(distance, 0, sizeOfWave, 0, 255));
  }
}

void anglePower(){
 for(Motor unit : motors){
  PVector relativeLocation = new PVector ( unit.x - manIconLocation.x, unit.y - manIconLocation.y);
  if(PVector.angleBetween(relativeLocation, new PVector(mouseX - manIconLocation.x, mouseY- manIconLocation.y))< angleThreshold) unit.power = 255;
  else unit.power = 0;
 }
 
}
int squareWave(Motor unit){
  println(unit.power);
  println("millis: "+millis()+" Change time: "+squareTimeChange);
   if(unit.power==0 && millis()-squareTimeChange>squareDurationOff){
   println("changeON");
   return 255;
   }
   if(unit.power==0) {println("stayOff");return 0;}
  if(unit.power==255 && millis()-squareTimeChange>squareDurationOn){
    println("changeOFF");
    return 0;
  }
  println("stayOn");
  return 255;
}
void mapRectPower(float x, float y) {
  for (int i=0; i<motors.length; i++) {
    Motor unit = motors[i];
    float x_distance = x - unit.x;
    float x_distance1 = x_distance + distanceBetweenShoes;
    float y_distance = y - unit.y;
    float distance;
    if (abs(x_distance)>abs(x_distance1))distance = sqrt(sq(x_distance1)+sq(y_distance));
    else distance = sqrt(sq(x_distance)+sq(y_distance));
    if (distance > sizeOfWave) unit.power = 0;
    else unit.power = 255-int(map(distance, 0, sizeOfWave, 0, 255));
  }
}
void mousePressed() {
  if (overCircle(leftButton.x, leftButton.y, 50)) {
    startWave(90, periodOfWave, sizeOfWave);
  }
  if (overCircle(upButton.x, upButton.y, 50)) {
    startWave(180, periodOfWave, sizeOfWave);
  }
  if (overCircle(downButton.x, downButton.y, 50)) {
    startWave(0, periodOfWave, sizeOfWave);
  }
  if (overCircle(rightButton.x, rightButton.y, 50)) {
    startWave(270, periodOfWave, sizeOfWave);
  }
   if (overCircle(upRightButton.x, upRightButton.y, 50)) {
    startWave(225, periodOfWave, sizeOfWave);
  }
   if (overCircle(upLeftButton.x, upLeftButton.y, 50)) {
    startWave(135, periodOfWave, sizeOfWave);
  }
  if (overCircle(motors[0].x, motors[0].y, 75)) {
  }
}

void mouseDragged() {
  for (Motor unit : motors) {
    if (overCircle(unit.x, unit.y, unit.size)) {
      unit.x=mouseX;
      unit.y=mouseY;
      updateMotorsCenter();
    }
  }
}
void keyPressed() {
  if (key == 'a') {
     for (Motor unit : motors) {
       unit.power=squareWave(unit);
     }
     if((!squareHigh && millis()-squareTimeChange>squareDurationOff) ||(squareHigh && millis()-squareTimeChange>squareDurationOn)){ println("Square Change"); squareTimeChange = millis(); squareHigh=!squareHigh;}
  }
  if(key =='s'){
    for (Motor unit : motors) {
       unit.power=0;
     }
  }
  if(key =='8' || keyCode == UP){
   motors[4].power=255;
   motors[5].power=255;
   motors[8].power=255;
    motors[9].power=255;
  }
  if(key =='5' || keyCode == DOWN){
    motors[0].power=255;
     motors[1].power=255;
     motors[10].power=255;
    motors[11].power=255;
  }
  if(key =='4' || keyCode == LEFT){
    motors[6].power=255;
    motors[7].power=255;
  }
  if(key =='6'  || keyCode == RIGHT){
   motors[2].power=255;
   motors[3].power=255;
  }
}
void keyReleased(){
   for (Motor unit : motors) {
       unit.power=0;
     }
  }

boolean overRect(float x, float y, float rectWidth, float rectHeight) {
  if (mouseX > x && mouseX <(x+rectWidth) && mouseY>y && mouseY < (rectHeight + y)) return true;
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
void powerOff() {
  for (Motor unit : motors) {
    unit.power=0;
  }
}
void startWave(int angle, int period, int size) {
  waveStartTime = millis();
  waveActive=true;
  angleOfWave = angle;
  periodOfWave = period;
  sizeOfWave = size;
  waveCreator.setVisible(true);
  wavePoint = new PVector(width/2, height/2);
  waveRect = PVector.fromAngle(angle*PI/180);
  waveNormal = PVector.fromAngle((angle+90)*PI/180);
  // Rotate
  waveCreator = createShape(RECT, 0, 0, width, size);
  waveCreator.rotate(angle*PI/180);
  waveCreator.translate(-width/2,-width/2);
  //Translate
  PVector.mult(waveNormal, -width/2, translation);
  wavePoint.add(translation);
  PVector.mult(waveRect, -width/2, translation);
  wavePoint.add(translation);
}
void delay(int delay) {
  double timer = millis();
  println("delay() start");
  int startTime = millis();
  while (millis()-startTime<delay);
  println("delay() end: "+ (millis()-timer));
  println("");
}
void updateArduino() {
  // -128 is reserved to indicate Start of payload
  //patload[1] Indicates boot to activate 0 -Left, 1- Right
  byte payloadRight[] = {-128, 1, 62, 63, 64, 115, 116, 117};
  byte payloadLeft[] = {-128, 0, 2, 3, 4, 5, 6, 7};
  double timer = millis();
  if(radialMode){
    for(Motor unit:motors){
      PVector relativeLocation = new PVector ( unit.x - manIconLocation.x, unit.y - manIconLocation.y);
      if(PVector.angleBetween(relativeLocation, new PVector(mouseX - manIconLocation.x, mouseY- manIconLocation.y))< angleThreshold) unit.power = squareWave(unit);
      else unit.power=0;
    }
    if((!squareHigh && millis()-squareTimeChange>squareDurationOff) ||(squareHigh && millis()-squareTimeChange>squareDurationOn)){ println("Square Change"); squareTimeChange = millis(); squareHigh=!squareHigh;}
  }
  
  println("updateArduino() start");
  for (int i=0; i<motors.length/2; i++) {
    payloadRight[i+2] = byte(motors[i].power);
    payloadLeft[i+2] = byte(motors[i+6].power);
  }
  myPort.write(payloadRight);
  println("payloadRightSent:");
  myPort.write(payloadLeft);
  println("payloadLeftSent");
  println("updateArduino() end: "+( millis()-timer));
  println("");
}
void updateMotorsCenter() {
  float mostLeftMotorX = motors[6].x;
  float mostRightMotorX = motors[6].x;
  float mostUpMotorY = motors[6].y;
  float mostDownMotorY = motors[6].y;
  for (int i=6; i<12; i++) {
    Motor unit = motors[i];
    if (unit.x <mostLeftMotorX) mostLeftMotorX = unit.x;
    if (unit.x>mostRightMotorX) mostRightMotorX = unit.x;
    if (unit.y < mostUpMotorY) mostUpMotorY = unit.y;
    if (unit.y> mostDownMotorY) mostDownMotorY = unit.y;
  }
  motorsCenterX = mostLeftMotorX + (mostRightMotorX-mostLeftMotorX)/2;
  motorsCenterY = mostUpMotorY + (mostDownMotorY - mostUpMotorY)/2;
  widthOfMotorArray = (mostRightMotorX-mostLeftMotorX);
  heightOfMotorArray = (mostDownMotorY - mostUpMotorY);
}
//gUI
public void sendWave(int Event) {
  double timer = millis();
  println("sendWave() start");
  startWave(angleKnobValue, speedSliderValue, sizeOfWave);
  println("setup() start: "+ (millis()-timer));
  println("");
}
void mapWavePower(){
  for (Motor unit : motors) {
    PVector position = new PVector ( unit.x, unit.y);
    float distance = abs(PVector.dot(PVector.sub(position, wavePoint), waveNormal));
    if (distance > sizeOfWave) unit.power = 0;
    else unit.power = 255-int(map(distance, 0, sizeOfWave, 0, 255));
  }
}