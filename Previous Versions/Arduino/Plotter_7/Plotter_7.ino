
//-------------------------------------------------------//
//  -- Plotter from CD Steppers --
//  Code for controlling three stepper drives in a CNC
//  plotter. This uses Arduino Nano 328.
//
//  Plotter 7 - Test Versiont
//
//  Added Z Stepper. Function 'line()' can be used to
//  draw line from one coordinate point to another.
//
//  Created by : Vishnu M Aiea
//  Web : www.vishnumaiea.in
//  Date created : 10:48 PM 22-04-2017, Saturday
//  Last modified : 5:23 PM 25-04-2017, Tuesday
//-------------------------------------------------------//

#include <Stepper.h>

#define DOWN 1
#define UP 0

const int sprX = 48; //steps per revolution
const int sprY = 20;
const int sprZ = 20;

int stepCountX = 0; //current step counts
int stepCountY = 0;
int stepCountZ = 0;

int singleStepX = 2; //single step equivalent
int singleStepY = 1;
int singleStepZ = 1;

int stepBoundX = 250; //maximum allowed steps
int stepBoundY = 250;
int stepBoundZ = 50;

int xRotate = 500; //unit step count
int yRotate = 250;
int zRotate = 100;

int minDelay = 200;
int medDelay = 400;
int longDelay = 1000;
int drawDelay = 200;

bool isPenDown = false;

int motorSpeedX = 1300;
int motorSpeedY = 1400;
int motorSpeedZ = 1500;

int totalStepsX = 750;
int totalStepsY = 250;
int totalStepsZ = 250;

char incBytes[2];
char incByte;
int stepsToRotate = 500;
int stepsCount = 0;

int enableX = 6;
int enableY = 12;
int enableZ = A4;

Stepper stepperX(sprX, 2, 3, 4, 5);
Stepper stepperY(sprY, 8, 9, 10, 11);
Stepper stepperZ(sprZ, A0, A1, A2, A3);

void setup() {
  stepperX.setSpeed(motorSpeedX);
  stepperY.setSpeed(motorSpeedY);
  stepperZ.setSpeed(motorSpeedZ);

  pinMode(enableX, OUTPUT);
  pinMode(enableY, OUTPUT);
  pinMode(enableZ, OUTPUT);

  digitalWrite(enableX, LOW);
  digitalWrite(enableY, LOW);
  digitalWrite(enableZ, LOW);

  Serial.begin(9600);
}

void loop() {
  if (Serial.available() > 0) {
    incByte = Serial.read();

    if (incByte == 't') {
      relMoveTo(100, 100);
      delay(longDelay);
      
      movePen(DOWN);
      relMoveTo(50, 0);
      delay(drawDelay);
      relMoveTo(0, 50);
      delay(drawDelay);
      relMoveTo(-50, 0);
      delay(drawDelay);
      relMoveTo(0,-50);
      delay(drawDelay);
      movePen(UP);
      
      absMoveTo(0, 0);
      movePen(UP);
      delay(400);
      line(100,10, 200, 10);
      delay(400);
      absMoveTo(0, 0);
    }

    else {
      Serial.println("Invalid");
      //Serial.print(incBytes);
      //Serial.print("Done");
    }
  }
}

//--------------------------------------------------------

bool line (int X1, int Y1, int X2, int Y2) {
  movePen(UP);
  absMoveTo(X1, Y1);
  delay(50);
  movePen(DOWN);
  X2 -= X1;
  Y2 -= Y1;
  delay(drawDelay);
  relMoveTo(X2, Y2);
  delay(50);
  movePen(UP);
  return true;
}

//--------------------------------------------------------

bool absMoveTo(int targetX, int targetY) {
  bool isCompleted = false;

  if ((targetX <= stepBoundX) && (targetY <= stepBoundY)) {
    if ((targetX != stepCountX) || (targetY != stepCountY)) {
      int relTargetX, relTargetY;
      relTargetX = targetX - stepCountX; //relative target
      relTargetY = targetY - stepCountY;

      digitalWrite(enableX, HIGH);
      digitalWrite(enableY, HIGH);

      while (!(isCompleted)) {
        if ((relTargetX > 0) && (stepCountX != targetX)) {
          stepperX.step(singleStepX);
          stepCountX++;
        }
        if ((relTargetX < 0) && (stepCountX != targetX)) {
          stepperX.step(-singleStepX);
          stepCountX--;
        }
        if ((relTargetY > 0) && (stepCountY != targetY)) {
          stepperY.step(singleStepY);
          stepCountY++;
        }
        if ((relTargetY < 0) && (stepCountY != targetY)) {
          stepperY.step(-singleStepY);
          stepCountY--;
        }
        if ((stepCountX == targetX) && (stepCountY == targetY)) {
          isCompleted = true;
          digitalWrite(enableX, LOW);
          digitalWrite(enableY, LOW);
        }
      }
    }
  }
  else {
    Serial.println("Error : Out of bound.");
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

//---------------------------------------------------------

bool relMoveTo(int targetX, int targetY) {
  absMoveTo((targetX + stepCountX), (targetY + stepCountY));
}

//----------------------------------------------------------

bool movePen(int x) {
  if (x == UP) {
    if (isPenDown) {
      digitalWrite(enableZ, HIGH);
      stepperZ.step(-zRotate);
      stepCountZ -= zRotate;
      isPenDown = false;
      digitalWrite(enableZ, LOW);
      return true;
    }
  }

  else if (x == DOWN) {
    if (!isPenDown) {
      digitalWrite(enableZ, HIGH);
      stepperZ.step(zRotate);
      stepCountZ += zRotate;
      isPenDown = true;
      digitalWrite(enableZ, LOW);
      return true;
    }
  }
  else {
    Serial.println("Invalid input for movePen.");
    return false;
  }
}

//---------------------------------------------------------
