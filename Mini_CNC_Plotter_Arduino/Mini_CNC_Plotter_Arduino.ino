
//=========================================================================//
//
//  -- Plotter from CD Steppers --
//  Code for controlling three stepper drives in a CNC
//  plotter. This uses Arduino Nano 328.
//
//  Swapped software serial ports with hardware serial
//  Software serial is for debugging
//
//  Author : Vishnu M Aiea
//  Web : www.vishnumaiea.in
//  Date created : 10:48 PM 22-04-2017, Saturday
//  Last modified : 01:01:26 AM, 04-06-2017, Sunday
//
//=========================================================================//

#include <Stepper.h>
#include <SoftwareSerial.h>

#define DOWN 1
#define UP 0
#define DELIMITER ';'
#define STEPS "STEPS"
#define PIXELS "PIXELS"

int LED_PIN = 13;

int imageWidth = 0;
int imageHeight = 0;

//if you're using stepper motors for all the 3 axes, then input the step counts
//of each motor here
const int sprX = 48; //steps per revolution
const int sprY = 20; //CD stepper motors
const int sprZ = 20; //CD stepper motors

//stepCount keep track of step increments of each stepper motor
int stepCountX = 0; //current step counts
int stepCountY = 0;
int stepCountZ = 0;

//precision depends on your mechanical setup. it can be found by dividing
//the linear displacement produced by an axis with the total no. of steps
//taken by the motor to achieve it
const float precisionX = 0.06625; //in mm
const float precisionY = 0.152;
const float precisionZ = 0.152;

//this defines the pixel size for your plotting area. your plotting area
//will be divided into a 2D array of pixels just like an image. you need to
//determine the precision you want for the pixel
const float pixelSize = 0.152; //size of one pixel square in mm

//defines the single step equivalent for each motors.
int singleStepX = 1; //single step equivalent
int singleStepY = 1;
int singleStepZ = 1;

//plotting area bundary interms of pixels. equivalent to image width and height
int pixelBoundX = 327; //maximum allowed steps
int pixelBoundY = 250;
int pixelBoundZ = 100;

int minDelay = 200;
int medDelay = 400;
int longDelay = 700;
int drawDelay = 200;

//defines the initial speed for each stepper motors
int motorSpeedX = 1000; //stepper motor speeds
int motorSpeedY = 1400;
int motorSpeedZ = 1500;

//defines the max displacements for each axis in terms of motor steps
int stepBoundX = 750; //total steps on each axis
int stepBoundY = 250;
int stepBoundZ = 250;

int xRotate = 500; //unit step count
int yRotate = 250;
int zRotate = 100;

int enableX = A5; //enable pins
int enableY = 12;
int enableZ = A4;

int segmentCount = 0;
bool isPenDown = false;

String tempString;

//software serial is used for debugging
SoftwareSerial mySerial(2, 3); // RX, TX

//define each steppers
//you can reduce pins to half by using two transistors
Stepper stepperX (sprX, 4, 5, 6, 7);
Stepper stepperY (sprY, 8, 9, 10, 11);
Stepper stepperZ (sprZ, A0, A1, A2, A3);

//=========================================================================//

void setup() {
  stepperX.setSpeed (motorSpeedX);
  stepperY.setSpeed (motorSpeedY);
  stepperZ.setSpeed (motorSpeedZ);

  pinMode (enableX, OUTPUT); //pin modes for motor enabel pins
  pinMode (enableY, OUTPUT);
  pinMode (enableZ, OUTPUT);

  digitalWrite (enableX, LOW); //disable the motors
  digitalWrite (enableY, LOW);
  digitalWrite (enableZ, LOW);

  pinMode(LED_PIN, OUTPUT); //for debugging

  Serial.begin(9600);
  while (!Serial) {
    ;
  }

  mySerial.begin(9600);
  mySerial.setTimeout(20); //set timeout for each serial port
  Serial.setTimeout(20);
  mySerial.println("I'm ready!");
}

//=========================================================================//

void loop() {
  if (Serial.available() > 0) {
    tempString = Serial.readStringUntil(DELIMITER);

    if(tempString != NULL) {
      executeCommand();
    }
  }
}

//=========================================================================//
//draws line between two points

bool line (int X1, int Y1, int X2, int Y2) {
  movePen(UP);
  absMoveTo(X1, Y1, PIXELS); //move to starting coordinate of line
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

//=========================================================================//
//absMoveTo take the head (pen) to the exact location in the plotting area
//we have two types of abs movement here : in terms of pixels and in terms
//of steps

bool absMoveTo(int targetCoordX, int targetCoordY, String coordType) {

  bool isCompleted = false;
  int targetStepsX = 0;
  int targetStepsY = 0;

  if(coordType.equals(PIXELS)) {
    targetStepsX = convertToStepsX(targetCoordX); //pixels need to be converted to steps
    targetStepsY = convertToStepsY(targetCoordY);
  }
  else if(coordType.equals(STEPS)) {
    targetStepsX = targetCoordX; //steps only need assignments
    targetStepsY = targetCoordY;
  }

  if ((targetStepsX <= stepBoundX) && (targetStepsY <= stepBoundY)) { //tarhet coordinates must be within bounds
    if ((targetStepsX != stepCountX) || (targetStepsY != stepCountY)) {
      int relTargetStepsX, relTargetStepsY;

      //relative target is calculated from where the plotter head is right now
      relTargetStepsX = targetStepsX - stepCountX; //calculate the relative target
      relTargetStepsY = targetStepsY - stepCountY; //by subtracting from current XY

      digitalWrite(enableX, HIGH); //enable the motors
      digitalWrite(enableY, HIGH);

      //uses pseudo simultaneous stepper driving
      while (!isCompleted) { //loop each step until completion
        if ((relTargetStepsX > 0) && (stepCountX != targetStepsX)) { //positive X movement (further from origin)
          stepperX.step(singleStepX); //perform a single step movement
          stepCountX++; //track the steps (always important)
        }
        if ((relTargetStepsX < 0) && (stepCountX != targetStepsX)) { //negative X movement (closer to origin)
          stepperX.step(-singleStepX); //counter rotation
          stepCountX--; //track the steps (always important)
        }
        if ((relTargetStepsY > 0) && (stepCountY != targetStepsY)) { //positive Y movement
          stepperY.step(singleStepY); //perform a single step movement
          stepCountY++; //track the steps (always important)
        }
        if ((relTargetStepsY < 0) && (stepCountY != targetStepsY)) { //negative Y movement
          stepperY.step(-singleStepY); //perform a single step movement
          stepCountY--; //track the steps (always important)
        }
        if ((stepCountX == targetStepsX) && (stepCountY == targetStepsY)) { //if completed the operation
          isCompleted = true; //set flag
          digitalWrite(enableX, LOW); //disable enable pins
          digitalWrite(enableY, LOW);
        }
      }
    }
  }

  else {
    mySerial.println("absMoveTo Error : Out of bound.");
    mySerial.print("stepCountX = ");
    mySerial.println(stepCountX);
    mySerial.print("stepCountY = ");
    mySerial.println(stepCountY);
    mySerial.println(coordType);
    mySerial.print("targetCoordX = ");
    mySerial.println(targetCoordX);
    mySerial.print("targetCoordYX = ");
    mySerial.println(targetCoordY);
    mySerial.println("targetCoordY = ");
    mySerial.println(targetCoordY);
    mySerial.print("targetStepsY = ");
    mySerial.println(targetStepsY);
    movePen(UP);
    absMoveTo(0, 0, PIXELS); //return home
    return false;
  }

  if (isCompleted) {
    mySerial.print('\n');
    mySerial.println("- absMoveTo -");
    mySerial.print("stepCountX : ");
    mySerial.println(stepCountX);
    mySerial.print("stepCountY : ");
    mySerial.println(stepCountY);
    return true;
  }
  else {
    return false;
  }
}

//=========================================================================//
//adds the relative coordinates to current ones to do an abs move
//works for negative values too

bool relMoveTo(int targetPixelX, int targetPixelY) {

  if((targetPixelX == 0) || (targetPixelY == 0)) { //no need of movement if coord are zero
    return true;
  }

  int targetStepsX = convertToStepsX(targetPixelX); //convert pixels to steps
  int targetStepsY = convertToStepsY(targetPixelY);

  if(absMoveTo((targetStepsX + stepCountX), (targetStepsY + stepCountY), STEPS)) { //add the coordinates and do absMove
    return true;
  }
  else return false;
}

//=========================================================================//

int convertToStepsX (int pixelCountX) {
  return ((pixelSize * pixelCountX) / precisionX); //convert to steps
}

//=========================================================================//

int convertToStepsY (int pixelCountY) {
  return ((pixelSize * pixelCountY) / precisionY); //convert to steps
}

//=========================================================================//

int convertToPixelX (int stepsCountX) {
  return ((stepsCountX * precisionX) / pixelSize);
}

//=========================================================================//

int convertToPixelY (int stepsCountY) {
  return ((stepsCountY * precisionY) / pixelSize);
}

//=========================================================================//

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
    mySerial.println("movePen Error : Invalid input.");
    return false;
  }
}

//=========================================================================//

bool calibXY (bool startCalib) {
  if (startCalib) {
    delay(50);
    movePen(UP);
    absMoveTo(pixelBoundX, 0, PIXELS);
    delay(50);
    movePen(DOWN);
    delay(50);
    movePen(UP);
    delay(drawDelay);
    absMoveTo(pixelBoundX, pixelBoundY, PIXELS);
    delay(50);
    movePen(DOWN);
    delay(50);
    movePen(UP);
    delay(drawDelay);
    absMoveTo(0, pixelBoundY, PIXELS);
    delay(50);
    movePen(DOWN);
    delay(50);
    movePen(UP);
    delay(drawDelay);
    absMoveTo(0, 0, PIXELS);
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
    mySerial.println("calibXY Error : Invalid input.");
  }
}

//=========================================================================//
//removes a specified char from a string

void removeChar (String a, char b) {
  int i = a.indexOf(b);

  if(i >= 0) {
    mySerial.println();
    mySerial.println("Removing delimiter from" + tempString);
    tempString.remove(i);
  }
}

//=========================================================================//

void executeCommand () {

  //------------------- Initialization starts ----------------------//
  if(tempString.startsWith("READY?")) {
    mySerial.println("SW Received : " + tempString);
    sendResponse("READY!");
    mySerial.println("SW Sent : READY!");
    mySerial.println();
    tempString = "";
  }
  //------------------- Initialization ends ----------------------//

  //------------------- M30 starts ----------------------//
  //M30 = stop plotting and return to home

  else if(tempString.startsWith("M30")) {
    mySerial.println("M30 Received");
    movePen(UP);
    absMoveTo(0, 0, PIXELS);
  }
  //------------------- M30 ends ----------------------//

  //-------------------------- G251 starts -----------------------//
  //G251 specifies the width and height of the image or drawing area

  else if(tempString.startsWith("G251")) {
    mySerial.println("G251 Received");
    if(checkCommand(tempString)) { //check the command
      String commandString = tempString; //create copy

      String wSubString = commandString.substring(0, commandString.indexOf(','));
      wSubString.replace("W", ""); //remove W to make integer string
      int wValue = wSubString.toInt(); //convert to integer

      wSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the W part of the string
      commandString.replace(wSubString, ""); //remove the W part

      String hSubString = commandString.substring(0, commandString.indexOf(','));
      hSubString.replace("H", ""); //remove H to make integer string
      int hValue = hSubString.toInt(); //convert to integer

      imageWidth = wValue;
      imageHeight = hValue;
    }
  }
  //----------------------- G251 ends ---------------------------//


  //----------------------- G252 ends --------------------------//
  //G252 specifies the type of drawing operation and segments
  //to draw

  else if (tempString.startsWith("G252")) {
    mySerial.println("G52 Received");
    String commandString = tempString; //make a copy of the command

    if(checkCommand(tempString)) {
      commandString.replace("G252,", "");
      String typeSubString = commandString.substring(0, commandString.indexOf(','));
      typeSubString = commandString.substring(0, commandString.indexOf(',') + 1);
      commandString.replace(typeSubString, "");
      String nSubString = commandString.substring(0, commandString.indexOf(','));
      nSubString.replace("N", "");
      int nValue = nSubString.toInt();
    }
  }
  //----------------------- G252 ends ----------------------//


  //--------------------- G28 starts -----------------------//
  //G28 specifies homing
  else if (tempString.startsWith("G28")) {
    mySerial.println("G28 Received");
    if((stepCountX == 0) && (stepCountY == 0)) {
      mySerial.println("Already home");
    }
    else {
      absMoveTo(0, 0, PIXELS);
    }
  }
  //--------------------- G28 ends ------------------------//


  //----------------------- G00 starts ----------------------//
  //G00 defines absolute movement

  else if (tempString.startsWith("G00")) {
    mySerial.println("G00 Received");
    String commandString = tempString; //make a copy of the command

    if(checkCommand(tempString)) {
      commandString.replace("G00,", ""); //remove the header part

      //mySerial.println("Modified String : " + commandString);
      String xSubString = commandString.substring(0, commandString.indexOf(',')); //extract the X part of the string
      //mySerial.println(xSubString);
      xSubString.replace("X", ""); //remove X to make integer string
      int xValue = xSubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      String ySubString = commandString.substring(0, commandString.indexOf(',')); //extract the Y part of the string
      //mySerial.println(ySubString);
      ySubString.replace("Y", ""); //remove Y to make integer string
      int yValue = ySubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      ySubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the Y part of the string
      commandString.replace(ySubString, ""); //remove the Y part
      String zSubString = commandString;
      //mySerial.println(zSubString);
      zSubString.replace("Z", ""); //remove Z to make integer string
      int zValue = zSubString.toInt(); //convert the integer string to int

      mySerial.print("X = ");
      mySerial.print(xValue);
      mySerial.print(", ");
      mySerial.print("Y = ");
      mySerial.print(yValue);
      mySerial.print(", ");
      mySerial.print("Z = ");
      mySerial.println(zValue);
      mySerial.println();

      if(zValue == 1) { //if the command is to move pen down
        if(!isPenDown) { //if pen is not already down
          if(movePen(DOWN)) { //try to move the pen
            mySerial.println("Pen is down");
            mySerial.println();
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            mySerial.println("Couldn't move the pen down!");
          }
        }
        else { //if pen is already down
          mySerial.println("Pen is already down");
        }
      }

      else if(zValue == 0) { //if the command is to move pen up
        if(isPenDown) { //only if pen is down
          if(movePen(UP)) { //try to move the pen
            mySerial.println("Pen is up");
            mySerial.println();
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            mySerial.println("Couldn't move the pen up!");
          }
        }
        else { //if pen is already up
          mySerial.println("Pen is already up");
        }
      }

      if((stepCountX == convertToStepsX(xValue)) && (stepCountY == convertToStepsY(yValue))) {
        mySerial.println("Pen is already at location");
        mySerial.println(tempString);
        mySerial.println("SW Sent DONE!");
        sendResponse("DONE!");
        mySerial.println();
        tempString = ""; //clear command buffer
      }
      else if(absMoveTo(xValue, yValue, PIXELS)) { //try to perform an abolute move
        mySerial.println("SW Sent DONE!");
        sendResponse("DONE!"); //send confirmation
        mySerial.println();
        tempString = ""; //clear tempString
      }
      else {
        mySerial.println("Couldn't complete abs move ");
        mySerial.println(tempString);
        mySerial.println("SW Sent DONE!");
        sendResponse("DONE!");
        mySerial.println();
        tempString = ""; //clear command buffer
      }
    }
  }
  //------------------------ G00 ends -----------------------//


  //----------------------- G01 starts ----------------------//
  //G01 defines relative movement

  else if (tempString.startsWith("G01")) {
    mySerial.println("G01 Received");
    String commandString = tempString; //make a copy of the command

    if(checkCommand(tempString)) {
      commandString.replace("G01,", ""); //remove the header part

      //mySerial.println("Modified String : " + commandString);
      String xSubString = commandString.substring(0, commandString.indexOf(',')); //extract the X part of the string
      //mySerial.println(xSubString);
      xSubString.replace("X", ""); //remove X to make integer string
      int xValue = xSubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      String ySubString = commandString.substring(0, commandString.indexOf(',')); //extract the Y part of the string
      //mySerial.println(ySubString);
      ySubString.replace("Y", ""); //remove Y to make integer string
      int yValue = ySubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      ySubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the Y part of the string
      commandString.replace(ySubString, ""); //remove the Y part
      String zSubString = commandString;
      //mySerial.println(zSubString);
      zSubString.replace("Z", ""); //remove Z to make integer string
      int zValue = zSubString.toInt(); //convert the integer string to int

      mySerial.print("X = ");
      mySerial.print(xValue);
      mySerial.print(", ");
      mySerial.print("Y = ");
      mySerial.print(yValue);
      mySerial.print(", ");
      mySerial.print("Z = ");
      mySerial.println(zValue);
      mySerial.println();

      if(zValue == 1) { //if the command is to move pen down
        if(!isPenDown) { //if pen is not already down
          delay(100);
          if(movePen(DOWN)) { //try to move the pen
            mySerial.println("Pen is down");
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            mySerial.println("Couldn't move the pen down!");
          }
        }
        else { //if pen is already down
          mySerial.println("Pen is already down");
        }
      }

      else if(zValue == 0) { //if the command is to move pen up
        if(isPenDown) { //only if pen is down
          delay(100);
          if(movePen(UP)) { //try to move the pen
            mySerial.println("Pen is up");
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            mySerial.println("Couldn't move the pen up!");
          }
        }
        else { //if pen is already up
          mySerial.println("Pen is already up");
        }
      }

      if((stepCountX == convertToStepsX(xValue)) && (stepCountY == convertToStepsY(yValue))) {
        mySerial.println("Pen is already at location");
      }
      else if(relMoveTo(xValue, yValue)) {
        mySerial.println("SW Sent DONE!");
        sendResponse("DONE!");
        mySerial.println();
        tempString = "";
      }
      else {
        mySerial.println("Couldn't complete rel move " + tempString);
        mySerial.println("SW Sent DONE!");
        sendResponse("DONE!");
        mySerial.println();
        tempString = "";
      }
    }
    //----------------------- G01 ends ----------------------//

    else {
      mySerial.print("Invalid format -> ");
      mySerial.println(tempString);
      sendResponse("INVALID!");
      mySerial.println("SW Sent INVALID!");
      mySerial.println();
      tempString = "";
    }
  }

  else {
    mySerial.println("SW Received : " + tempString);
    sendResponse("DONE!");
    mySerial.println("SW Sent DONE!");
    mySerial.println();
    tempString = "";
  }
}

//=========================================================================//
//send responses back to control software

bool sendResponse (String a) {
  Serial.print(a);
  Serial.print(DELIMITER);
  return true;
}

//=========================================================================//
//checks each commands received for validity

bool checkCommand (String a) {
  //--------------------------------//
  if(a.startsWith("G00")) {
    int commaCount = 0;

    for(int i = 0; i < a.length(); i++) { //loop until the end of string
      if(a[i] == ',') //count commas
      commaCount++;
    }
    if((commaCount == 3) || (commaCount == 2)) //if proper string
    return true;

    else return false; //if otherwise
  }
  //--------------------------------//

  if(a.startsWith("G01")) {
    int commaCount = 0;

    for(int i = 0; i < a.length(); i++) { //loop until the end of string
      if(a[i] == ',') //count commas
      commaCount++;
    }
    if((commaCount == 3) || (commaCount == 2)) //if proper string
    return true;

    else return false; //if otherwise
  }
  //--------------------------------//

  if(a.startsWith("G251")) {
    int commaCount = 0;

    for(int i = 0; i < a.length(); i++) { //loop until the end of string
      if(a[i] == ',') //count commas
      commaCount++;
    }
    if(commaCount == 2) //if proper string
    return true;

    else return false; //if otherwise
  }
  //--------------------------------//

  else return false;
}

//=========================================================================//
