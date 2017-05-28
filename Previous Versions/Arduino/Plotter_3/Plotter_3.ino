
//-------------------------------------------------------//
//  -- Plotter from CD Steppers --
//  Code for controlling three stepper drives in a CNC 
//  plotter. This uses Arduino Nano 328.
//  
//  Plotter 2 - Test Version
//
//  Creates a square wave on the paper.
//  
//  Created by : Vishnu M Aiea
//  Web : www.vishnumaiea.in
//  Date created : 10:48 PM 22-04-2017, Saturday
//  Last modified : 9:29 AM 23-04-2017, Sunday
//-------------------------------------------------------//

#include <Stepper.h>

const int stepCountX = 48;
const int stepCountY = 20;
const int stepCountZ = 20;

int timeDelay = 200;

int motorSpeedX = 1300;
int motorSpeedY = 1400;
int motorSpeedZ = 1300;

int xRotate = 800;
int yRotate = 250;
int zRotate = 50;

char incBytes[2];
char incByte;
int stepsToRotate = 500;
int stepsCount = 0;

Stepper stepperX(stepCountX, 2,3,4,5);
Stepper stepperY(stepCountY, 6,7,8,9);
Stepper stepperZ(stepCountZ, 10,11,12,13);

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
      for (int i=0;i<4;i++) {
        stepperX.step(100);
        delay(100);
        stepperY.step(250);
        delay(100);
        stepperX.step(100);
        delay(100);
        stepperY.step(-250);
        delay(100);
      }
      stepperX.step(-800);
    }
    
    else {
      Serial.println("Invalid");
      //Serial.print(incBytes);
      //Serial.print("Done");
    }
  }
}


