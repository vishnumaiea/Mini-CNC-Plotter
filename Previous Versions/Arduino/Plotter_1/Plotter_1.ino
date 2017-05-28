
//-------------------------------------------------------//
//  -- Plotter from CD Steppers --
//  Code for controlling three stepper drives in a CNC 
//  plotter. This uses Arduino Nano 328.
//  
//  Created by : Vishnu M Aiea
//  Web : www.vishnumaiea.in
//  Date created : 10:48 PM 22-04-2017, Saturday
//  Last modified : 10:48 PM 22-04-2017, Saturday
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

char incBytes[2];   // for incoming serial data
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
    Serial.readBytes(incBytes,2);

    //incBytes[2] = '\0';
    
    if(incBytes[0] == 'x' && incBytes[1] == 'r') {
      Serial.println("Stepper X - Right");
      stepperX.step(-xRotate);
    }

    else if(incBytes[0] == 'x' && incBytes[1] == 'l') {
      Serial.println("Stepper X - Left");
      stepperX.step(xRotate);
    }

    else if(incBytes[0] == 'y' && incBytes[1] == 'f') {
      Serial.println("Stepper Y - Forward");
      stepperY.step(yRotate);
    }
    
    else if(incBytes[0] == 'y' && incBytes[1] == 'r') {
      Serial.println("Stepper Y - Reverse");
      stepperY.step(-yRotate);
    }

    else if(incBytes[0] == 'z' && incBytes[1] == 'd') {
      Serial.println("Stepper Z - Down");
      stepperZ.step(zRotate);
    }

    else if(incBytes[0] == 'z' && incBytes[1] == 'u') {
      Serial.println("Stepper Z - Up");
      stepperZ.step(-zRotate);
    }
    
    else {
      Serial.println("Invalid");
      Serial.print(incBytes);
      Serial.print("Done");
    }
  }
}


