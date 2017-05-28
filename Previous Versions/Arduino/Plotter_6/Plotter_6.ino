
//-------------------------------------------------------//
//  -- Plotter from CD Steppers --
//  Code for controlling three stepper drives in a CNC
//  plotter. This uses Arduino Nano 328.
//
//  Plotter 6 - Test Versiont
//
//  Demonstrate how absMoveTo and relMoveTo work.
//
//  Created by : Vishnu M Aiea
//  Web : www.vishnumaiea.in
//  Date created : 10:48 PM 22-04-2017, Saturday
//  Last modified : 10:31 PM 23-04-2017, Sunday
//-------------------------------------------------------//

#include <Stepper.h>

const int sprX = 48; //steps per revolution
const int sprY = 20;
const int sprZ = 20;

int stepCountX = 0;
int stepCountY = 0;
int stepCountZ = 0;

int singleStepX = 3;
int singleStepY = 1;
int singleStepZ = 1;

int stepBoundX = 250;
int stepBoundY = 250;
int stepBoundZ = 50;

int minDelay = 200;
int medDelay = 400;
int longDelay = 500;

//bool isCompleted = false;

int motorSpeedX = 1300;
int motorSpeedY = 1400;
int motorSpeedZ = 1300;

int totalStepsX = 750;
int totalStepsY = 250;
int totalStepsZ = 50;

char incBytes[2];
char incByte;
int stepsToRotate = 500;
int stepsCount = 0;

Stepper stepperX(sprX, 2, 3, 4, 5);
Stepper stepperY(sprY, 6, 7, 8, 9);
Stepper stepperZ(sprZ, 10, 11, 12, 13);

void setup() {
  stepperX.setSpeed(motorSpeedX);
  stepperY.setSpeed(motorSpeedY);
  stepperZ.setSpeed(motorSpeedZ);

  Serial.begin(9600);
}

void loop() {
  if (Serial.available() > 0) {
    incByte = Serial.read();

    if (incByte == 't') {
      absMoveTo(50, 100);
      delay(1000);
      relMoveTo(50, 0);
      delay(1000);
      relMoveTo(0, 50);
      delay(1000);
      relMoveTo(-50, 0);
      delay(1000);
      relMoveTo(0,-50);
      delay(1000);
      absMoveTo(0, 0);
    }

    else {
      Serial.println("Invalid");
      //Serial.print(incBytes);
      //Serial.print("Done");
    }
  }
}

bool absMoveTo(int targetX, int targetY) {
  bool isCompleted = false;

  if ((targetX <= stepBoundX) && (targetY <= stepBoundY)) {
    if ((targetX != stepCountX) || (targetY != stepCountY)) {
      int relTargetX, relTargetY;
      relTargetX = targetX - stepCountX; //relative target
      relTargetY = targetY - stepCountY;

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
