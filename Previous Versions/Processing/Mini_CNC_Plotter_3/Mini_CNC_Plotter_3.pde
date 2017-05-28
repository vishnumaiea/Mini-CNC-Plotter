
//-----------------------------------------------------------------------//

//   -- Mini CNC Plotter - 03 --
//
//   Completed designing the port selection window
//   For some reason the Serial.list() doesn't work well with Nano.
//
//   Copyright (c) 2017 Vishnu M Aiea
//   E-Mail : vishnumaiea@gmail.com
//   Web : www.vishnumaiea.in
//   Date created : 12:20 PM 27-04-2017, Thursday
//   Last modified : 11:39 PM 29-04-2017, Saturday

//-----------------------------------------------------------------------//

import processing.serial.*;

Serial serialPort;

final int frameWidth = 800;
final int frameHeight = 650;

int imageHeight;
int imageWidth;

int lineCount = 0;

int pixelLocation = 0;
int pixelRed;
int pixelGreen;
int pixelBlue;

int runCount = 0;

boolean pixelColor = false;
boolean prevPixelColor = true;

PImage img;

int lineCountLimit = 5;
int [][][] lineCords = new int [2] [2] [lineCountLimit];


int portValue = 0; //virtual com port value
int mouseStatus = 0; //status of mouse input
int tempInt; //int variable for testing
int comStatusCounter; //to check is the OBU is on and transmitting

String versionNumber = "3.2.45";

boolean startPressed = false; //for start button
boolean quitPressed = false; //for quit button
boolean aboutPressed = false;
boolean serialSuccess = false; //check if com port opening was successful
boolean portError = false; //port error status

String portName = "None"; //name of port selected
String serialBuffer; //string that holds read serial data
String tempString; //string variable for testing
String comStatus = "Disconnected";

color colorWhite = #FFFFFF;
color colorBlue = #006699;
color colorRed = #c55757;
color colorLightGrey = 220;
color colorDarkGrey = 170;

color startButtonColor = colorWhite; //start button color
color quitButtonColor = colorWhite; //quit button color
color aboutButtonColor = colorWhite;
color startButtonTextColor = colorBlue; //start button text color
color quitButtonTextColor  = colorBlue; //quit button txt color
color aboutButtonTextColor = colorBlue;

PFont buttonFont; //font for button
PFont aboutFont; //font for about
PFont aboutTitleFont;
PFont titleFont; //font for bingo title
PFont nameFont; //font for names

PFont robotoFont, poppinsFont, segoeFont, h4Font, h5Font, h6Font, fontAwesome;


//-----------------------------------------------------------------------//

void setup() {
  size(800, 650);
  background(colorDarkGrey);

  surface.setTitle("Processing PNG Image");
  img = loadImage("arduino.png");
  if (img == null) {
    exit();
  }

  buttonFont = loadFont("Calibri-18.vlw"); //font for the button
  aboutFont = createFont("Verdana Bold", 20);
  poppinsFont = createFont("Poppins Medium", 20); //font for about
  segoeFont = createFont("Segoe UI SemiBold", 20);
  titleFont = loadFont("Aharoni-Bold-48.vlw"); //title font
  nameFont = loadFont("Corbel-Bold-48.vlw"); //names font

  fontAwesome = createFont("FontAwesome", 20);

  imageHeight = img.height;
  imageWidth = img.width;
}

//-----------------------------------------------------------------------//

void draw() {  
  if (startPressed) {
    //delay(1);
    background(180);
    //print("Start : ");
    //println(startPressed);
    //print("Serial : ");
    //println(serialSuccess);

    if (!serialSuccess) {
      if (Serial.list().length > 0) {
        background(170);
        portName = Serial.list()[portValue]; //because can't use COM1 and COM2
        serialPort = new Serial(this, portName, 9600);
        println("Serial Communication Established");
        println("Listing ports");
        println(Serial.list()); //list the available ports
        println();
        print("Selected Port is ");
        println(portName); //print selected port name
        print("portValue = ");
        println(portValue); //print the port value use selected
        print("Total no. of ports = ");
        println(Serial.list().length); //total no. of ports
        println();
        serialSuccess = true;
        printVerbose();
      } 
     
      else {
        println("Error : Could not find the port specified");
        println();
        background(170);
        portError = true; //error opening the port
        serialSuccess = false; //serial com error
        startPressed = false; //causes returning to home screen
        printVerbose();
      }
    }  
  }
  
  if(startPressed && serialSuccess) {
    if ((serialSuccess) && ((Serial.list().length) > 0) && (portName.equals(Serial.list()[portValue]))) {
      background(180);
      //print((Serial.list().length));
      printVerbose();
    } 
    
    else {
      //background(170);
      showInitialWindow();
      serialSuccess = false;
      portError = true;
      startPressed = false;
    }
  }

  if (!startPressed) {//if app not started
    showInitialWindow();
  }
}

//----------------------------------------------------------------------//

void establishSerial() {
}


//----------------------------------------------------------------------//

void printVerbose() {
  println("--Start Verbose--");
  print("startPressed : ");
  println(startPressed);
  print("quitPressed : ");
  println(quitPressed);
  print("aboutPressed : ");
  println(aboutPressed);
  print("serialSuccess : ");
  println(serialSuccess);
  print("portError : ");
  println(portError);
  print("portValue : ");
  println(portValue);
  print("portName : ");
  println(portName);
  print("Port Count : ");
  println((Serial.list().length));
  println("--End Verbose--");
  println("\n");
}

//----------------------------------------------------------------------//

void showInitialWindow() {
  smooth();
  noStroke();

  background(colorDarkGrey);

  fill(colorLightGrey);
  rect(125, 450, 550, 95);//third box in starting window

  fill(startButtonColor); //start box color
  rect(220, 480, 80, 35); //start box
  fill(quitButtonColor); //quit box color
  rect(360, 480, 80, 35); //quit box
  fill(aboutButtonColor);
  rect(500, 480, 80, 35); //quit box

  textFont(segoeFont, 14);
  fill(startButtonTextColor); //start box text color
  text("START", 240, 503);
  fill(quitButtonTextColor); //quit box text color
  text("QUIT", 382, 503);
  fill(aboutButtonTextColor); //quit box text color
  text("ABOUT", 518, 503);



  //if quit button pressed
  if (mouseX>=360 && mouseX<=440 && mouseY>=480 && mouseY<=515) {
    if (mousePressed && (mouseButton == LEFT)) {
      exit(); //quit application
    }
    quitButtonColor = colorBlue; //complement quit box colors
    quitButtonTextColor = colorWhite;
  } else {
    quitButtonColor = colorWhite; //reset colors
    quitButtonTextColor = colorBlue;
  }

  //if start button pressed
  if (mouseX>=220 && mouseX<=300 && mouseY>=480 && mouseY<=515) {
    if (mousePressed && (mouseButton == LEFT) && (mouseStatus == 0)) {
      startPressed = true;
      mouseStatus = 1;
    }
    if (!mousePressed) {
      mouseStatus = 0;
    }
    startButtonColor = colorBlue; //complement start box colors
    startButtonTextColor = colorWhite;
  } else { //reset color
    startButtonColor = #FFFFFF;
    startButtonTextColor = #006699;
  }

  //if about button is pressed
  if (mouseX>=500 && mouseX<=580 && mouseY>=480 && mouseY<=515) {
    if (mousePressed && (mouseButton == LEFT) && (mouseStatus == 0)) {
      aboutPressed = true;
      mouseStatus = 1;
    }
    if (!mousePressed) {
      mouseStatus = 0;
    }
    aboutButtonColor = colorBlue; //complement start box colors
    aboutButtonTextColor = colorWhite;
  } else { //reset color
    aboutButtonColor = #FFFFFF;
    aboutButtonTextColor = #006699;
  }


  fill(colorWhite);
  rect(125, 100, 550, 350); //second box in initial window

  fill(colorBlue);
  rect(125, 90, 550, 120); //first box in initial window

  textFont(poppinsFont, 26);
  fill(#FFFFFF);
  text("MINI CNC PLOTTER", 280, 140);

  textFont(poppinsFont, 12);
  fill(200);
  text("Version", 355, 170);
  text(versionNumber, 405, 170);

  textFont(poppinsFont, 12);
  fill(200);
  text("© 2017  Vishnu M Aiea", 332, 195);

  fill(colorBlue);
  textFont(segoeFont, 15);
  text("Connect the Plotter and select the COM port", 246, 375);

  rect(330, 270, 130, 40); //COM port selection
  fill(#FFFFFF);
  rect(360, 272, 70, 36); //small rect for port value

  textFont(fontAwesome, 27);
  fill(#FFFFFF);
  text("", 338, 300); //port select arrow kyes
  text("", 442, 300);

  if (portError) { //only if the selected port is not found
    if((Serial.list().length) <= 0) {
      textFont(segoeFont, 15);
      fill(#c55757);
      text("Error : Could not find the port specified !", 260, 410);
    }
    else {
      rect(260, 410, 300, 20);
    }
  }

  textFont(segoeFont, 12);
  fill(#000000); //com port value color

  if (Serial.list().length > 0) { //check if there is any port
    //decrement com port value
    if (mouseX>=340 && mouseX<=370 && mouseY>=270 && mouseY<=310) {
      if (mousePressed && (mouseButton == LEFT) && (mouseStatus == 0)) {
        if (portValue > 0) {
          portValue--;
          portName = Serial.list()[portValue];
          mouseStatus = 1;
        }
      }
      if (!mousePressed) {
        mouseStatus = 0; //so that there is no indefinite decrement
      }
    } else {
      portValue = 0;
    }

    //increment com port value
    if (mouseX>=430 && mouseX<=460 && mouseY>=270 && mouseY<=310) {
      if (mousePressed && (mouseButton == LEFT) && (mouseStatus == 0)) {
        if (portValue < (Serial.list().length -1 )) {
          portValue++;
          mouseStatus = 1;
        }
      }
      if (!mousePressed) {
        mouseStatus = 0; //so that there is no indefinite increment
      }
    } else {
      portValue = 0;
    }

    portName = Serial.list()[portValue]; //get the port name now selected
    textFont(segoeFont, 12);
    fill(#000000); //com port value color
    text(portName, 375, 295); //then print it
  } 
  
  else {
    textFont(segoeFont, 12);
    fill(#000000); //com port value color
    text("NONE", 378, 295);
  }
}

//------------------------------------------------------------------------//

boolean isPixelBlack(int x, int y) {
  pixelLocation = (x+(y*imageWidth));
  pixelRed = (int) red(img.pixels[pixelLocation]);
  pixelGreen = (int) green(img.pixels[pixelLocation]);
  pixelBlue = (int) blue(img.pixels[pixelLocation]);

  if ((pixelRed > 10) && (pixelGreen > 10) && (pixelBlue > 10)) {
    return false;
  } else if ((pixelRed < 10) && (pixelGreen < 10) && (pixelBlue < 10)) {
    return true;
  }
  return false;
}

//------------------------------------------------------------------------//

void countLines() {
  for (int y=0; y<imageHeight; y++) { //loop until image height or rows
    for (int x=0; x<imageWidth; x++) { //loop until image width or columns
      pixelColor = isPixelBlack(x, y); //get the color of the pixel

      if (x==0) { //if cords are starting of any row
        prevPixelColor = false; //prev pixel color is true = black
      } else if (x != 0) { //if cords are not starting of any row
        prevPixelColor = isPixelBlack((x-1), y); //get the prev pixel's color
      } 

      if (lineCount > (lineCountLimit - 1)) { //double the array size if limit reached
        int [][][] tempArray = new int [2][2][lineCountLimit * 2]; //create new array
        lineCords = (int [][][]) concat(tempArray, lineCords); //concat them
        lineCountLimit *= 2; //increment the current limit
        print("lineCords Length : ");
        println(lineCords[0][0].length);
        //print("tempArray Length : ");
        //println(tempArray[0][0].length);
      }

      if ((pixelColor) && ((x==0) || (!prevPixelColor))) { //if pixel color is black AND (there's no prev pixel OR prev pixel is white)
        lineCords[0][0][lineCount] = x; //x cord of starting of a line
        lineCords[0][1][lineCount] = y; //y cord of starting of a line
      }

      if ((!pixelColor) && (prevPixelColor)) { //if pixel color is white AND prev pixel color is black
        lineCords[1][0][lineCount] = x-1; //x cord of ending of a line
        lineCords[1][1][lineCount] = y; //y cord of ending of a line
        lineCount++; // increase z to store the next line's cords
      }

      if ((pixelColor) && (x==(imageWidth-1))) { //if pixel is black but at the end of any row
        lineCords[1][0][lineCount] = x; //x cord of ending of a line
        lineCords[1][1][lineCount] = y; //y cord of ending of a line
        lineCount++; // increase z to store the next line's cords
      }
    }
  }
  print("Total Lines Found : ");
  println(lineCount);
}

//------------------------------------------------------------------------//