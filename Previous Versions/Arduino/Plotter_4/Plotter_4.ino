
//-------------------------------------------------------//
//  -- Plotter from CD Steppers --
//  Code for controlling three stepper drives in a CNC 
//  plotter. This uses Arduino Nano 328.
//  
//  Plotter 4 - Test Version
//
//  Draws a line from origin to the opposite corner.
//  This is achieved by "pseudo simultaneous" drive. 
//  
//  Created by : Vishnu M Aiea
//  Web : www.vishnumaiea.in
//  Date created : 10:48 PM 22-04-2017, Saturday
//  Last modified : 10:42 AM 23-04-2017, Sunday
//-------------------------------------------------------//

#include <Stepper.h>

const int sprX = 48; //steps per revolution
const int sprY = 20;
const int sprZ = 20;

int stepCountX = 0;
int stepCountY = 0;
int stepCountZ = 0;

int timeDelay = 200;
bool isCompleted = false;

int motorSpeedX = 1300;
int motorSpeedY = 1400;
int motorSpeedZ = 1300;

int totalStepsX = 800;
int totalStepsY = 250;
int totalStepsZ = 50;

char incBytes[2];
char incByte;
int stepsToRotate = 500;
int stepsCount = 0;

Stepper stepperX(sprX, 2,3,4,5);
Stepper stepperY(sprY, 6,7,8,9);
Stepper stepperZ(sprZ, 10,11,12,13);

void setup() {
  stepperX.setSpeed(motorSpeedX);
  stepperY.setSpeed(motorSpeedY);
  stepperZ.setSpeed(motorSpeedZ);
  
  Serial.begin(9600);
}

void loop() {
  if(Serial.available() > 0) {
    //Serial.readBytes(incBytes,2);
    incByte = Serial.read();

    //incBytes[2] = '\0';
    
    if(incByte == 't') {

      isCompleted = false;
      
      if(!isCompleted) {
        while(!(isCompleted)) {
          if(!(stepCountX >= totalStepsX)) {
            stepperX.step(3);
            stepCountX++;
          }
          if(!(stepCountY >= totalStepsY)) {
            stepperY.step(1);
            stepCountY++;
          }
          if((stepCountX >= totalStepsX) || (stepCountY >= totalStepsY)) {
            isCompleted = true;
          }
        }

        delay(200);

        isCompleted = false;

        while(!(isCompleted)) {
          if(!(stepCountX == 0)) {
            stepperX.step(-3);
            stepCountX--;
          }
          if(!(stepCountY == 0)) {
            stepperY.step(-1);
            stepCountY--;
          }
          if((stepCountX == 0) || (stepCountY == 0)) {
            isCompleted = true;
          }
        }
      }
    }
    
    else {
      Serial.println("Invalid");
      //Serial.print(incBytes);
      //Serial.print("Done");
    }
  }
}


