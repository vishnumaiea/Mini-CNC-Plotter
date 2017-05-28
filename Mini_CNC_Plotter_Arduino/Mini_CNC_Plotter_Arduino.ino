
//=========================================================================//
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

int pixelBoundX = 327; //maximum allowed steps
int pixelBoundY = 250;
int pixelBoundZ = 100;

int xRotate = 500; //unit step count
int yRotate = 250;
int zRotate = 100;

int minDelay = 200;
int medDelay = 400;
int longDelay = 700;
int drawDelay = 200;

bool isPenDown = false;

int motorSpeedX = 1000; //stepper motor speeds
int motorSpeedY = 1400;
int motorSpeedZ = 1500;

int stepBoundX = 750; //total steps on each axis
int stepBoundY = 250;
int stepBoundZ = 250;

char incBytes[2]; //serial data buffer
char incByte; //serial char data buffer

int enableX = A5; //enable pins
int enableY = 12;
int enableZ = A4;

int segmentCount = 0;

String tempString;
SoftwareSerial mySerial(2, 3); // RX, TX

Stepper stepperX (sprX, 4, 5, 6, 7);
Stepper stepperY (sprY, 8, 9, 10, 11);
Stepper stepperZ (sprZ, A0, A1, A2, A3);

//=========================================================================//

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

  pinMode(LED_PIN, OUTPUT);
  Serial.begin(9600);
  while (!Serial) {
    ;
  }
  Serial.println("I'm ready!");
  mySerial.begin(9600);
  mySerial.setTimeout(20);
  Serial.setTimeout(20);
}

//=========================================================================//

void loop() {
  if (mySerial.available() > 0) {
    tempString = mySerial.readStringUntil(DELIMITER);

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

bool absMoveTo(int targetCoordX, int targetCoordY, String coordType) {

  bool isCompleted = false;
  int targetStepsX = 0;
  int targetStepsY = 0;

  if(coordType.equals(PIXELS)) {
    targetStepsX = convertToStepsX(targetCoordX);
    targetStepsY = convertToStepsY(targetCoordY);
  }
  else if(coordType.equals(STEPS)) {
    targetStepsX = targetCoordX;
    targetStepsY = targetCoordY;
  }

  if ((targetStepsX <= stepBoundX) && (targetStepsY <= stepBoundY)) { //tarhet coordinates must be within bounds
    if ((targetStepsX != stepCountX) || (targetStepsY != stepCountY)) {
      int relTargetStepsX, relTargetStepsY;
      relTargetStepsX = targetStepsX - stepCountX; //calculate the relative target
      relTargetStepsY = targetStepsY - stepCountY; //by subtracting from current XY

      digitalWrite(enableX, HIGH); //enable the motors
      digitalWrite(enableY, HIGH);

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
    Serial.println("absMoveTo Error : Out of bound.");
    Serial.print("stepCountX = ");
    Serial.println(stepCountX);
    Serial.print("stepCountY = ");
    Serial.println(stepCountY);
    Serial.println(coordType);
    Serial.print("targetCoordX = ");
    Serial.println(targetCoordX);
    Serial.print("targetCoordYX = ");
    Serial.println(targetCoordY);
    Serial.println("targetCoordY = ");
    Serial.println(targetCoordY);
    Serial.print("targetStepsY = ");
    Serial.println(targetStepsY);
    movePen(UP);
    absMoveTo(0, 0, PIXELS);
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

//=========================================================================//
//adds the relative coordinates to current ones to do an abs move
//works for negative values too

bool relMoveTo(int targetPixelX, int targetPixelY) {

  if((targetPixelX == 0) || (targetPixelY == 0)) {
    return true;
  }

  int targetStepsX = convertToStepsX(targetPixelX);
  int targetStepsY = convertToStepsY(targetPixelY);

  if(absMoveTo((targetStepsX + stepCountX), (targetStepsY + stepCountY), STEPS)) { //add the coordinates
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
    Serial.println("movePen Error : Invalid input.");
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
    Serial.println("calibXY Error : Invalid input.");
  }
}

//=========================================================================//

void blinkOnce () {
  digitalWrite(LED_PIN, HIGH);
  delay(100);
  digitalWrite(LED_PIN, LOW);
}

//=========================================================================//

void removeChar (String a, char b) {
  int i = a.indexOf(b);

  if(i >= 0) {
    Serial.println();
    Serial.println("Removing delimiter from" + tempString);
    tempString.remove(i);
  }
}

//=========================================================================//

void executeCommand () {

  //------------------- Initialization starts ----------------------//
  if(tempString.startsWith("READY?")) {
    Serial.println("SW Received : " + tempString);
    sendResponse("READY!");
    Serial.println("SW Sent : READY!");
    Serial.println();
    tempString = "";
  }
  //------------------- Initialization ends ----------------------//

  else if(tempString.startsWith("M30")) {
    Serial.println("M30 Received");
    movePen(UP);
    absMoveTo(0, 0, PIXELS);
  }

  //-------------------------- G251 starts -----------------------//
  //G251 specifies the width and height of the image or drawinf area

  else if(tempString.startsWith("G251")) {
    Serial.println("G251 Received");
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
    Serial.println("G52 Received");
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
    Serial.println("G28 Received");
    if((stepCountX == 0) && (stepCountY == 0)) {
      Serial.println("Already home");
    }
    else {
      absMoveTo(0, 0, PIXELS);
    }
  }
  //--------------------- G28 ends ------------------------//


  //----------------------- G00 starts ----------------------//
  //G00 defines absolute movement

  else if (tempString.startsWith("G00")) {
    Serial.println("G00 Received");
    String commandString = tempString; //make a copy of the command

    if(checkCommand(tempString)) {
      commandString.replace("G00,", ""); //remove the header part

      //Serial.println("Modified String : " + commandString);
      String xSubString = commandString.substring(0, commandString.indexOf(',')); //extract the X part of the string
      //Serial.println(xSubString);
      xSubString.replace("X", ""); //remove X to make integer string
      int xValue = xSubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      String ySubString = commandString.substring(0, commandString.indexOf(',')); //extract the Y part of the string
      //Serial.println(ySubString);
      ySubString.replace("Y", ""); //remove Y to make integer string
      int yValue = ySubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      ySubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the Y part of the string
      commandString.replace(ySubString, ""); //remove the Y part
      String zSubString = commandString;
      //Serial.println(zSubString);
      zSubString.replace("Z", ""); //remove Z to make integer string
      int zValue = zSubString.toInt(); //convert the integer string to int

      Serial.print("X = ");
      Serial.print(xValue);
      Serial.print(", ");
      Serial.print("Y = ");
      Serial.print(yValue);
      Serial.print(", ");
      Serial.print("Z = ");
      Serial.println(zValue);
      Serial.println();

      if(zValue == 1) { //if the command is to move pen down
        if(!isPenDown) { //if pen is not already down
          if(movePen(DOWN)) { //try to move the pen
            Serial.println("Pen is down");
            Serial.println();
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            Serial.println("Couldn't move the pen down!");
          }
        }
        else { //if pen is already down
          Serial.println("Pen is already down");
        }
      }

      else if(zValue == 0) { //if the command is to move pen up
        if(isPenDown) { //only if pen is down
          if(movePen(UP)) { //try to move the pen
            Serial.println("Pen is up");
            Serial.println();
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            Serial.println("Couldn't move the pen up!");
          }
        }
        else { //if pen is already up
          Serial.println("Pen is already up");
        }
      }

      if((stepCountX == convertToStepsX(xValue)) && (stepCountY == convertToStepsY(yValue))) {
        Serial.println("Pen is already at location");
        Serial.println(tempString);
        Serial.println("SW Sent DONE!");
        sendResponse("DONE!");
        Serial.println();
        tempString = ""; //clear command buffer
      }
      else if(absMoveTo(xValue, yValue, PIXELS)) { //try to perform an abolute move
        Serial.println("SW Sent DONE!");
        sendResponse("DONE!"); //send confirmation
        Serial.println();
        tempString = ""; //clear tempString
      }
      else {
        Serial.println("Couldn't complete abs move ");
        Serial.println(tempString);
        Serial.println("SW Sent DONE!");
        sendResponse("DONE!");
        Serial.println();
        tempString = ""; //clear command buffer
      }
    }
  }
  //------------------------ G00 ends -----------------------//


  //----------------------- G01 starts ----------------------//
  //G01 defines relative movement

  else if (tempString.startsWith("G01")) {
    Serial.println("G01 Received");
    String commandString = tempString; //make a copy of the command

    if(checkCommand(tempString)) {
      commandString.replace("G01,", ""); //remove the header part

      //Serial.println("Modified String : " + commandString);
      String xSubString = commandString.substring(0, commandString.indexOf(',')); //extract the X part of the string
      //Serial.println(xSubString);
      xSubString.replace("X", ""); //remove X to make integer string
      int xValue = xSubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      String ySubString = commandString.substring(0, commandString.indexOf(',')); //extract the Y part of the string
      //Serial.println(ySubString);
      ySubString.replace("Y", ""); //remove Y to make integer string
      int yValue = ySubString.toInt(); //convert the integer string to int

      xSubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the X part of the string
      commandString.replace(xSubString, ""); //remove the X part
      ySubString = commandString.substring(0, commandString.indexOf(',') + 1); //extract the Y part of the string
      commandString.replace(ySubString, ""); //remove the Y part
      String zSubString = commandString;
      //Serial.println(zSubString);
      zSubString.replace("Z", ""); //remove Z to make integer string
      int zValue = zSubString.toInt(); //convert the integer string to int

      Serial.print("X = ");
      Serial.print(xValue);
      Serial.print(", ");
      Serial.print("Y = ");
      Serial.print(yValue);
      Serial.print(", ");
      Serial.print("Z = ");
      Serial.println(zValue);
      Serial.println();

      if(zValue == 1) { //if the command is to move pen down
        if(!isPenDown) { //if pen is not already down
          delay(100);
          if(movePen(DOWN)) { //try to move the pen
            Serial.println("Pen is down");
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            Serial.println("Couldn't move the pen down!");
          }
        }
        else { //if pen is already down
          Serial.println("Pen is already down");
        }
      }

      else if(zValue == 0) { //if the command is to move pen up
        if(isPenDown) { //only if pen is down
          delay(100);
          if(movePen(UP)) { //try to move the pen
            Serial.println("Pen is up");
            delay(100); //relaxation time
          }
          else { //if couldn't move the pen
            Serial.println("Couldn't move the pen up!");
          }
        }
        else { //if pen is already up
          Serial.println("Pen is already up");
        }
      }

      if((stepCountX == convertToStepsX(xValue)) && (stepCountY == convertToStepsY(yValue))) {
        Serial.println("Pen is already at location");
      }
      else if(relMoveTo(xValue, yValue)) {
        Serial.println("SW Sent DONE!");
        sendResponse("DONE!");
        Serial.println();
        tempString = "";
      }
      else {
        Serial.println("Couldn't complete rel move " + tempString);
        Serial.println("SW Sent DONE!");
        sendResponse("DONE!");
        Serial.println();
        tempString = "";
      }
    }
    //----------------------- G01 ends ----------------------//

    else {
      Serial.print("Invalid format -> ");
      Serial.println(tempString);
      sendResponse("INVALID!");
      Serial.println("SW Sent INVALID!");
      Serial.println();
      tempString = "";
    }
  }

  else {
    Serial.println("SW Received : " + tempString);
    sendResponse("DONE!");
    Serial.println("SW Sent DONE!");
    Serial.println();
    tempString = "";
  }
}

//=========================================================================//

bool sendResponse (String a) {
  mySerial.print(a);
  mySerial.print(DELIMITER);
  return true;
}

//=========================================================================//

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

bool ifConfirm() {
  String tempString;

  while(1) {
    if(Serial.available() > 0) {
      tempString = Serial.readString();
      if(tempString.equals("NEXT")) {
        return true;
      }
    }
  }
}

//=========================================================================//
