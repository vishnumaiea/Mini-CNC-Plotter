
//===================================================================//
//
//  -- Plotter from CD Steppers --
//  Code for controlling three stepper drives in a CNC
//  plotter. This uses Arduino Nano 328.
//
//  Plotter_Calib_2 - Test Version
//
//  Creates points in all four corners in a loop. Helps
//  to check accuracy or consistency.
//
//  Author : Vishnu M Aiea
//  Web : www.vishnumaiea.in
//  Date created : 10:48 PM 22-04-2017, Saturday
//  Last modified : 10:42:26 PM, 17-05-2017, Wednesday
//
//===================================================================//

#include <Stepper.h>

#define DOWN 1
#define UP 0

const int sprX = 48; //steps per revolution
const int sprY = 20;
const int sprZ = 20;

int stepCountX = 0; //current step counts
int stepCountY = 0;
int stepCountZ = 0;

const float precisionX = 0.06625;
const float precisionY = 0.152;
const float precisionZ = 0.152;

const float pixelSize = 0.152; //size of one pixel square

int singleStepX = 1; //single step equivalent
int singleStepY = 1;
int singleStepZ = 1;

int pixelsX = 327; //maximum allowed steps
int pixelsY = 250;
int pixelsZ = 100;

int xRotate = 500; //unit step count
int yRotate = 250;
int zRotate = 100;

int minDelay = 200;
int medDelay = 400;
int longDelay = 1000;
int drawDelay = 200;

bool isPenDown = false;

int motorSpeedX = 1300; //stepper motor speeds
int motorSpeedY = 1400;
int motorSpeedZ = 1500;

int totalStepsX = 750; //total steps on each axis
int totalStepsY = 250;
int totalStepsZ = 250;

char incBytes[2]; //serial data buffer
char incByte; //serial char data buffer

int enableX = 6; //enable pins
int enableY = 12;
int enableZ = A4;

Stepper stepperX (sprX, 2, 3, 4, 5);
Stepper stepperY (sprY, 8, 9, 10, 11);
Stepper stepperZ (sprZ, A0, A1, A2, A3);

//===================================================================//

void setup() {
  stepperX.setSpeed (motorSpeedX);
  stepperY.setSpeed (motorSpeedY);
  stepperZ.setSpeed (motorSpeedZ);

  pinMode (enableX, OUTPUT);
  pinMode (enableY, OUTPUT);
  pinMode (enableZ, OUTPUT);

  digitalWrite (enableX, LOW);
  digitalWrite (enableY, LOW);
  digitalWrite (enableZ, LOW);

  Serial.begin (9600);
}

//===================================================================//

void loop() {
  if (Serial.available() > 0) {
    incByte = Serial.read();

    if (incByte == 't') {
      calibXY(true);
    }
    else if (incByte == 's') {
      calibXY(false);
    }
    else {
      Serial.println("Invalid input.");
    }
  }
}

//===================================================================//
//draws line between two points

bool line (int X1, int Y1, int X2, int Y2) {
  movePen(UP);
  absMoveTo(X1, Y1); //move to starting coordinate of line
  delay(50);
  movePen(DOWN); //move the pen down
  X2 -= X1; //subtract the absolute values from the starting coordinates
  Y2 -= Y1; //so as to calculate the relative distance to the end point
  delay(drawDelay);
  relMoveTo(X2, Y2); //relative movement
  delay(50);
  movePen(UP); //move the pen up
  return true;
}

//===================================================================//

bool absMoveTo(int targetX, int targetY) {

  bool isCompleted = false;

  //target co-ordinates are translated to steps in the
  //following two lines

  targetX = int ((pixelSize * targetX) / precisionX); //convert to steps
  targetY = int ((pixelSize * targetY) / precisionY);

  if ((targetX <= totalStepsX) && (targetY <= totalStepsY)) {
    if ((targetX != stepCountX) || (targetY != stepCountY)) {
      int relTargetX, relTargetY;
      relTargetX = targetX - stepCountX; //calculate the relative target
      relTargetY = targetY - stepCountY; //by subtracting from current XY

      digitalWrite(enableX, HIGH); //enable the motors
      digitalWrite(enableY, HIGH);

      while (!isCompleted) { //loop each step until completion
        if ((relTargetX > 0) && (stepCountX != targetX)) { //positive X movement (further from origin)
          stepperX.step(singleStepX); //perform a single step movement
          stepCountX++; //track the steps (always important)
        }
        if ((relTargetX < 0) && (stepCountX != targetX)) { //negative X movement (closer to origin)
          stepperX.step(-singleStepX); //counter rotation
          stepCountX--; //track the steps (always important)
        }
        if ((relTargetY > 0) && (stepCountY != targetY)) { //positive Y movement
          stepperY.step(singleStepY); //perform a single step movement
          stepCountY++; //track the steps (always important)
        }
        if ((relTargetY < 0) && (stepCountY != targetY)) { //negative Y movement
          stepperY.step(-singleStepY); //perform a single step movement
          stepCountY--; //track the steps (always important)
        }
        if ((stepCountX == targetX) && (stepCountY == targetY)) { //if completed the operation
          isCompleted = true; //set flag
          digitalWrite(enableX, LOW); //disable enable pins
          digitalWrite(enableY, LOW);
        }
      }
    }
  }

  else {
    Serial.println("absMoveTo Error : Out of bound.");
    movePen(UP);
    absMoveTo(0, 0);
    return false;
  }

  if (isCompleted) {
    Serial.print('\n');
    Serial.println("- absMoveTo -");
    Serial.print("stepCountX : ");
    Serial.println(stepCountX);
    Serial.print("stepCountY : ");
    Serial.println(stepCountY);
    //delay(toDelay);
    return true;
  }
  else {
    return false;
  }
}

//===================================================================//
//adds the relative coordinates to current ones to do an abs move
//works for negative values too

bool relMoveTo(int targetX, int targetY) {
  absMoveTo((targetX + stepCountX), (targetY + stepCountY)); //add the coordinates
}

//===================================================================//

bool movePen(int x) {
  if (x == UP) {
    if (isPenDown) { //only do if pen is already down
      digitalWrite(enableZ, HIGH); //enable pin
      stepperZ.step(-zRotate);
      stepCountZ -= zRotate; //track the steps
      isPenDown = false; //set the flag to current state
      digitalWrite(enableZ, LOW);
      return true;
    }
  }

  else if (x == DOWN) {
    if (!isPenDown) { //only do if pen is up
      digitalWrite(enableZ, HIGH); //enable pin
      stepperZ.step(zRotate);
      stepCountZ += zRotate; //track steps
      isPenDown = true; //set the falg to current state
      digitalWrite(enableZ, LOW);
      return true;
    }
  }
  else {
    Serial.println("movePen Error : Invalid input.");
    return false;
  }
}

//===================================================================//

bool calibXY (bool startCalib) {
  if (startCalib) {
    delay(50);
    movePen(UP);
    absMoveTo(pixelsX, 0);
    delay(50);
    movePen(DOWN);
    delay(50);
    movePen(UP);
    delay(drawDelay);
    absMoveTo(pixelsX, pixelsY);
    delay(50);
    movePen(DOWN);
    delay(50);
    movePen(UP);
    delay(drawDelay);
    absMoveTo(0, pixelsY);
    delay(50);
    movePen(DOWN);
    delay(50);
    movePen(UP);
    delay(drawDelay);
    absMoveTo(0, 0);
    delay(50);
    movePen(DOWN);
    delay(50);
    movePen(UP);
    delay(50);
    return true;
  }
  else if (!startCalib) {
    return false;
  }
  else {
    Serial.println("calibXY Error : Invalid input.");
  }
}

//===================================================================//
