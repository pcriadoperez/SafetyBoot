import controlP5.*;

import processing.serial.*;


//Arduino
Serial myPort;
PImage leftBoot;
PImage rightBoot;

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

PShape[] waveCreator;
float motorsCenterX;
float motorsCenterY;

int distanceBetweenShoes= 550;

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
  myPort = new Serial(this, Serial.list()[1], 9600);

  //Processing Setup
  size(1200, 1000);
  motors= new Motor[12];
  for (int i=0; i<motors.length; i++) {
    if (i%2==0) motors[i] = new Motor(100, 100+80*i, 75);
    else motors[i] = new Motor(210, 100+80*(i-1), 75);
  }
  updateMotorsCenter(); 
  //Wave
  waveCreator = new PShape[2];
  waveCreator[0] = createShape(ELLIPSE, 0, 0, sizeOfWave, sizeOfWave);
  waveCreator[0].setVisible(false);
  waveCreator[1] = createShape(ELLIPSE, 600, 0, sizeOfWave, sizeOfWave);
  waveCreator[1].setVisible(false);
  //Controls
  leftButton = new ArrowButton(500, 100, PI/2);
  rightButton = new ArrowButton(600, 100, -PI/2);
  upButton = new ArrowButton(550, 50, PI);
  downButton = new ArrowButton(550, 150, 0);
  //Foot image
  rightBoot = loadImage("rightBoot.png");
  leftBoot = loadImage("leftBoot.png");
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
  cp5.addSlider("speedSliderValue")
    .setPosition(500, 600)
    .setRange(0, 2000)
    .setSize(200, 50)
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
  if (myPort.available()>0) println(myPort.readBytes());
  double timer = millis();
  println("draw() start");
  background (255, 255, 255);
  image(rightBoot, width/2, 0, width/2, rightBoot.height*width/(2*rightBoot.width));
  image(leftBoot, 0, 0, width/2, leftBoot.height*width/(2*leftBoot.width));
  textSize(14);
  text("frameRate: "+frameRate, 10, 10);
  text("frameCount: "+frameCount, 10, 20);
  text("TimeLapsed: "+frameCount/frameRate, 10, 30);
  text("Millis: " +millis(), 10, 40);
  textSize(32);
  text("Speed: ", 520, 580);
  text("Size:", 420, 680);
  text("Angle:", 620, 680);
  //Wave Update
  if (waveActive) {
    if (millis()- waveStartTime>periodOfWave) {
      waveActive = false;
      waveCreator[0].setVisible(false);
      waveCreator[1].setVisible(false);
      powerOff();
    } else {
      waveCreator[0].setVisible(true);
      waveCreator[0].translate(((widthOfMotorArray+2*sizeOfWave)*cos(angleOfWave*PI/180))/(periodOfWave*frameRate/1000), ((heightOfMotorArray+2*sizeOfWave) * sin(angleOfWave*PI/180))/(periodOfWave * frameRate/1000));
      waveCreator[1].setVisible(true);
      waveCreator[1].translate(((widthOfMotorArray+2*sizeOfWave)*cos(angleOfWave*PI/180))/(periodOfWave*frameRate/1000), ((heightOfMotorArray+2*sizeOfWave) * sin(angleOfWave*PI/180))/(periodOfWave * frameRate/1000));
      waveX = waveX + ((widthOfMotorArray+2*sizeOfWave)*cos(angleOfWave*PI/180))/(periodOfWave*frameRate/1000);
      waveY = waveY + ((heightOfMotorArray+2*sizeOfWave) * sin(angleOfWave*PI/180))/(periodOfWave * frameRate/1000);
      shape(waveCreator[0]);
      shape(waveCreator[1]);
      mapDoublePower(waveX, waveY);
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

void mapPower(float x, float y) {
  for (Motor unit : motors) {
    float x_distance = x - unit.x;
    float y_distance = y - unit.y;
    float distance =sqrt(sq(x_distance)+sq(y_distance)) ;
    if (distance > sizeOfWave) unit.power = 0;
    else unit.power = 255-int(map(distance, 0, sizeOfWave, 0, 255));
  }
}
void mapDoublePower(float x, float y) {
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
  /*
for (int i=0; i<motors.lengupload
th; i++) {
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
  if (overCircle(leftButton.x, leftButton.y, 50)) {
    startWave(180, periodOfWave, sizeOfWave);
  }
  if (overCircle(upButton.x, upButton.y, 50)) {
    startWave(270, periodOfWave, sizeOfWave);
  }
  if (overCircle(downButton.x, downButton.y, 50)) {
    startWave(90, periodOfWave, sizeOfWave);
  }
  if (overCircle(rightButton.x, rightButton.y, 50)) {
    startWave(0, periodOfWave, sizeOfWave);
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
  double timer = millis();
  println("startWave() start");
  waveStartTime = millis();
  waveActive=true;
  angleOfWave = angle;
  periodOfWave = period;
  sizeOfWave = size;
  waveCreator[0].setVisible(true);
  waveCreator[1].setVisible(true);
  waveX = motorsCenterX -widthOfMotorArray*cos(angle*PI/180)/2 -sizeOfWave*cos(angle*PI/180);
  waveY=motorsCenterY - heightOfMotorArray*sin(angle*PI/180)/2 - sizeOfWave*sin(angle*PI/180);
  waveCreator[0] = createShape(ELLIPSE, waveX, waveY, size, size);
  waveCreator[1] = createShape(ELLIPSE, waveX+distanceBetweenShoes, waveY, size, size);
  println("startWave() end: "+( millis()-timer));
  println("");
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