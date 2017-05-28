
//-----------------------------------------------------------------------//

//   -- Mini CNC Plotter - 07 --
//
//   I'm tired of this hurdle of manipulating button. In the next version,
//   I'll use buttons as objects.
//
//   Author : Vishnu M Aiea
//   E-Mail : vishnumaiea@gmail.com
//   Web : www.vishnumaiea.in
//   Date created : 12:20 PM 27-04-2017, Thursday
//   Last modified : 11:11 PM 01-05-2017, Monday

//-----------------------------------------------------------------------//

import processing.serial.*;

Serial serialPort;


String [] serialStatusList= {"Error : Could not find the port specified !",
                             "Error : Device disconnected !"};

int serialStatus = -1;

final int frameWidth = 800;
final int frameHeight = 650;

int imageHeight;
int imageWidth;

int imageBoxWidth = 337;
int imageBoxHeight = 260;
int imageBoxX = 437;
int imageBoxY= 120;

int infoBoxWidth = 386;
int infoBoxHeight = 260;
int infoBoxX = 25;
int infoBoxY= imageBoxY;

int controlBoxWidth = infoBoxWidth;
int controlBoxHeight = 210;
int controlBoxX = infoBoxX;
int controlBoxY= 425;

int consoleBoxWidth = imageBoxWidth;
int consoleBoxHeight = controlBoxHeight;
int consoleBoxX = imageBoxX;
int consoleBoxY= controlBoxY;

int boxTitleHeight = 25;
int boxTitleFontSize = 13;

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

int globalI, globalJ, globalK;

String serialPortStatus;
String serialComStatus;

boolean isMainWindowStarted = false;
boolean isInitialWindowStarted = false;
boolean startMonitorSerial = false;
boolean startMainWindow = false;
boolean portSelectError;

boolean isImageLoaded = false;
boolean imageLoadError = false;
boolean ifLoadimage = false;
boolean isPlottingStarted = false;
boolean isPlottingPaused = false;
boolean isPlotterActive = false;
boolean isPlottingFinished = false;
boolean ifCalibratePlotter = false;
boolean isSerialActive = false;
boolean ifCloseMainWindow = false;
boolean isUpPressed = false;
boolean isDownPressed = false;
boolean isleftPressed = false;
boolean isRightPressed = false;
boolean isPenDown = false;
boolean ifLines = false;
boolean ifPoints = false;
boolean ifFreehand = false;

int selectPortValue = -1; //virtual com port value
int portCount = 0;
int prevPortCount = 0;
int portIndexLimit = -1;
int activePortValue = -1;
int mouseStatus = 0; //status of mouse input
int tempInt; //int variable for testing
int comStatusCounter; //to check is the OBU is on and transmitting

String versionNumber = "3.2.45";

boolean startPressed = false; //for start button
boolean quitPressed = false; //for quit button
boolean aboutPressed = false;
boolean serialSuccess = false; //check if com port opening was successful
boolean isPortError = false; //port error status
boolean serialDisconnected = false;

String selectPortName = "NONE"; //name of port selected
String activePortName = "NONE";
String serialBuffer; //string that holds read serial data
String tempString; //string variable for testing
String comStatus = "Disconnected";

color colorWhite = #FFFFFF;
color colorBlue = #006699;
color colorRed = #c55757;
color colorLightGrey = 220;
color colorMediumGrey = 200;
color colorDarkGrey = 170;
color colorBlack = #000000;
color colorMediumBlack = 80;
color colorTextField = 240;

color startButtonColor = colorWhite; //start button color
color quitButtonColor = colorWhite; //quit button color
color aboutButtonColor = colorWhite;
color startButtonTextColor = colorBlue; //start button text color
color quitButtonTextColor  = colorBlue; //quit button txt color
color aboutButtonTextColor = colorBlue;

PFont robotoFont, poppinsFont, segoeFont, h4Font, h5Font, h6Font, fontAwesome;

//-----------------------------------------------------------------------//

void setup() {
  size(800, 655);
  //background(colorDarkGrey);

  surface.setTitle("Processing PNG Image");
  img = loadImage("arduino.png");
  if (img == null) {
    exit();
  }

  poppinsFont = createFont("Poppins Medium", 20); //font for about
  segoeFont = createFont("Segoe UI SemiBold", 20);
  fontAwesome = createFont("FontAwesome", 20);

  imageHeight = img.height;
  imageWidth = img.width;
}

//-----------------------------------------------------------------------//

void draw() {
  if ((!startPressed) && (!aboutPressed)) {
    showInitialWindow();
  }

  if (startPressed) {
    showMainWindow();
  }

  if (aboutPressed) {
    showAboutWindow();
  }
}

//-----------------------------------------------------------------------//

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
      //background(colorDarkGrey);
      mouseStatus = 1;
    }
    if (!mousePressed) {
      mouseStatus = 0;
    }
    startButtonColor = colorBlue; //complement start box colors
    startButtonTextColor = colorWhite;
  } else { //reset color
    startButtonColor = colorWhite;
    startButtonTextColor = colorBlue;
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
    aboutButtonColor = colorWhite;
    aboutButtonTextColor = colorBlue;
  }


  fill(colorWhite);
  rect(125, 100, 550, 350); //second box in initial window

  fill(colorBlue);
  rect(125, 90, 550, 120); //first box in initial window

  textFont(poppinsFont, 26);
  fill(colorWhite);
  text("MINI CNC PLOTTER", 280, 140);

  textFont(poppinsFont, 12);
  fill(colorMediumGrey);
  text("Version", 355, 170);
  text(versionNumber, 405, 170);

  textFont(poppinsFont, 12);
  fill(colorMediumGrey);
  text("© 2017  Vishnu M Aiea", 332, 195);

  fill(colorBlue);
  textFont(segoeFont, 15);
  text("Connect the Plotter and select the COM port", 246, 375);

  rect(330, 270, 130, 40); //COM port selection
  fill(colorWhite);
  rect(360, 272, 70, 36); //small rect for port value

  textFont(fontAwesome, 27);
  fill(colorWhite);
  text("", 338, 300); //port select arrow kyes
  text("", 442, 300);
  
  if (serialStatus == 0){
    textFont(segoeFont, 15);
    fill(colorRed);
    text(serialStatusList[serialStatus], 260, 410);
  }
  
  else if (serialStatus == 1) {
    textFont(segoeFont, 15);
    fill(colorRed);
    text(serialStatusList[serialStatus], 305, 410);
  }
  
  else {
    fill(colorWhite);
    rect(260, 410, 300, 20);
  }
  
  getSerialPortInfo();

  if (portCount != 0) { //check if there is any port
    //serialStatus = -1;
    if ((selectPortValue == -1) || (portCount < prevPortCount)) {
      selectPortValue = 0;
    }
    //decrement com port value
    if (mouseX>=330 && mouseX<=360 && mouseY>=270 && mouseY<=340) {
      if (mousePressed && (mouseButton == LEFT) && (mouseStatus == 0)) {
        if (selectPortValue > 0) {
          selectPortValue--;
          selectPortName = Serial.list()[selectPortValue];
          mouseStatus = 1;
          printVerbose("Port Decrement");
        }
      }
      if (!mousePressed) {
        mouseStatus = 0; //so that there is no indefinite decrement
      }
    } else {
      selectPortName = Serial.list()[selectPortValue];
    }

    //increment com port value
    if (mouseX>=430 && mouseX<=460 && mouseY>=270 && mouseY<=340) {
      if (mousePressed && (mouseButton == LEFT) && (mouseStatus == 0)) {
        if ((selectPortValue < (Serial.list().length -1 )) && (selectPortValue > -1)) {
          selectPortValue++;
          selectPortName = Serial.list()[selectPortValue];
          mouseStatus = 1;
          printVerbose("Port Increment");
        }
      }
      if (!mousePressed) {
        mouseStatus = 0; //so that there is no indefinite increment
      }
    } else {
      selectPortName = Serial.list()[selectPortValue];
    }

    textFont(segoeFont, 12);
    fill(colorBlack); //com port value color
    text(selectPortName, 375, 295); //then print it
    prevPortCount = portCount;
  } 
  
  if (portCount == 0) {
    textFont(segoeFont, 12);
    fill(colorBlack); //com port value color
    text("NONE", 378, 295);
    selectPortName = "NONE";
    selectPortValue = -1;
    //serialStatus = 0;
  }
}

//-----------------------------------------------------------------------//

void getSerialPortInfo() {
  portCount = Serial.list().length;
  portIndexLimit = portCount - 1;
}

//-----------------------------------------------------------------------//

void printVerbose(String verboseLocation) {
  println("--Start Verbose at " + verboseLocation + "--");
  println("startPressed : " + startPressed);
  println("quitPressed : " + quitPressed);
  println("aboutPressed : " + aboutPressed);
  println("serialSuccess : " + serialSuccess);
  println("isMainWindowStarted : " + isMainWindowStarted);
  println("serialDisconnected : " + serialDisconnected);
  println("isPortError : " + isPortError);
  println("portCount : " + portCount);
  println("selectPortValue : " + selectPortValue);
  println("selectPortName : " + selectPortName);
  //println("isPortAlive : " + isPortAlive());
  println("activePortValue : " + activePortValue);
  println("activePortName : " + activePortName);
  println("--End Verbose--");
  println("\n");
}

//-----------------------------------------------------------------------//

void showMainWindow() {
  getSerialPortInfo();
  
  if ((startPressed) && (portCount != 0) && (!isPortError)) {
    //printVerbose("Main Window");
    
    if(!serialSuccess) {
      establishSerial();
    }

    if (serialSuccess) {
      startMainWindow = true;
    } 
    
    else {
      startMainWindow = false;
      startPressed = false;
    }
  }
  
  if ((startMainWindow) && (!isPortError) && (serialPort.active())) {
    
    //------ Main Window Contents Start Here -------//
    background(colorMediumGrey);
    
    fill(colorBlue);
    rect(0, 0, 800, 75);
    
    smooth();
    noStroke();
    //println(serialPort.active());
    
    textFont(poppinsFont, 25);
    fill(colorWhite);
    text("MINI CNC PLOTTER", 280, 37);
    
    textFont(poppinsFont, 12);
    fill(colorMediumGrey);
    text("Version", 345, 62);
    text(versionNumber, 395, 62);
    
    fill(colorWhite);
    rect(imageBoxX, imageBoxY, imageBoxWidth, imageBoxHeight);
    image(img, (imageBoxX+5), (imageBoxY+5));
    fill(colorBlue);
    rect(imageBoxX, imageBoxY-boxTitleHeight, imageBoxWidth, boxTitleHeight);
    fill(colorWhite);
    textFont(segoeFont, boxTitleFontSize);
    text("Progress", imageBoxX+10, imageBoxY-8);
    
    fill(colorWhite);
    rect(infoBoxX, infoBoxY, infoBoxWidth, infoBoxHeight);
    fill(colorBlue);
    rect(infoBoxX, infoBoxY-boxTitleHeight, infoBoxWidth, boxTitleHeight);
    fill(colorWhite);
    textFont(segoeFont, boxTitleFontSize);
    text("Info", infoBoxX+10, infoBoxY-8);
    
    fill(colorWhite);
    rect(controlBoxX, controlBoxY, controlBoxWidth, controlBoxHeight);
    fill(colorBlue);
    rect(controlBoxX, controlBoxY-boxTitleHeight, controlBoxWidth, boxTitleHeight);
    fill(colorWhite);
    textFont(segoeFont, boxTitleFontSize);
    text("Control", controlBoxX+10, controlBoxY-8);
    
    fill(colorWhite);
    rect(consoleBoxX, consoleBoxY, consoleBoxWidth, consoleBoxHeight);
    fill(colorBlue);
    rect(consoleBoxX, consoleBoxY-boxTitleHeight, consoleBoxWidth, boxTitleHeight);
    fill(colorWhite);
    textFont(segoeFont, boxTitleFontSize);
    text("Console", consoleBoxX+10, consoleBoxY-8);
    
    fill(colorMediumBlack);
    text("Filename", infoBoxX+20, infoBoxY+32);
    fill(colorTextField);
    rect(infoBoxX+85, infoBoxY+14, 280, boxTitleHeight);
    
    fill(colorTextField);
    rect(infoBoxX+23, infoBoxY+62, 100, boxTitleHeight+5);
    fill(colorMediumBlack);
    text("Load Image", infoBoxX+38, infoBoxY+82);
    
    fill(colorTextField);
    rect(infoBoxX+23, infoBoxY+112, 100, boxTitleHeight+5);
    fill(colorMediumBlack);
    text("Lines", infoBoxX+56, infoBoxY+132);
    
    fill(colorTextField);
    rect(infoBoxX+23, infoBoxY+162, 100, boxTitleHeight+5);
    fill(colorMediumBlack);
    text("Points", infoBoxX+53, infoBoxY+182);
    
    fill(colorTextField);
    rect(infoBoxX+23, infoBoxY+212, 100, boxTitleHeight+5);
    fill(colorMediumBlack);
    text("Freehand", infoBoxX+46, infoBoxY+232);
    
    fill(colorMediumBlack);
    text("Port", infoBoxX+160, infoBoxY+75);
    text("Serial Status", infoBoxX+160, infoBoxY+115);
    text("Plotter Status", infoBoxX+160, infoBoxY+155);
    text("Position", infoBoxX+160, infoBoxY+195);
    text("Current Task", infoBoxX+160, infoBoxY+235);
    
    fill(colorTextField);
    rect(infoBoxX+254, infoBoxY+57, 110, boxTitleHeight);
    rect(infoBoxX+254, infoBoxY+97, 110, boxTitleHeight);
    rect(infoBoxX+254, infoBoxY+137, 110, boxTitleHeight);
    rect(infoBoxX+254, infoBoxY+177, 110, boxTitleHeight);
    rect(infoBoxX+254, infoBoxY+217, 110, boxTitleHeight);
    
    fill(#018ec6);
    rect(748, 25, 25,25);
    fill(200);
    textFont(fontAwesome, 22);
    text("", 752, 45);
    
    //fill(colorMediumGrey);
    //rect(55, 455, 150, 150);
    
    
    //rect(55, 455, 50, 50);
    
    //fill(colorLightGrey);
    //rect(105, 455, 50, 50);
    fill(colorMediumGrey);
    textFont(fontAwesome, 40);
    text("", 113, 492); //up arrow
    
    //rect(155, 455, 50, 50);
    
    //fill(colorLightGrey);
    //rect(55, 505, 50, 50);
    fill(colorMediumGrey);
    textFont(fontAwesome, 40);
    text("", 63, 542); //left arrow
    
    //fill(colorLightGrey);
    //rect(105, 505, 50, 50);
    fill(colorMediumGrey);
    textFont(fontAwesome, 42);
    text("", 112, 543); //center arrow
    
    fill(colorWhite);
    textFont(fontAwesome, 27);
    text("", 122, 538);
    
    //fill(colorLightGrey);
    //rect(155, 505, 50, 50);
    fill(colorMediumGrey);
    textFont(fontAwesome, 40);
    text("", 163, 542); //right arrow
    
    //rect(55, 555, 50, 50);
    
    //fill(colorLightGrey);
    //rect(105, 555, 50, 50);
    fill(colorMediumGrey);
    textFont(fontAwesome, 40);
    text("", 113, 592); //down arrow
    
    //rect(155, 555, 50, 50);
    
    fill(colorTextField-5);
    rect(controlBoxX+240, controlBoxY+20, 115, boxTitleHeight+5); //start button
    rect(controlBoxX+240, controlBoxY+65, 115, boxTitleHeight+5); //pause button
    rect(controlBoxX+240, controlBoxY+110, 115, boxTitleHeight+5); //stop button
    rect(controlBoxX+240, controlBoxY+155, 115, boxTitleHeight+5); //calibrate button
    
    textFont(segoeFont, boxTitleFontSize);
    fill(colorMediumBlack);
    text("START", controlBoxX+290, controlBoxY+40);
    text("PAUSE", controlBoxX+290, controlBoxY+85);
    text("STOP", controlBoxX+290, controlBoxY+130);
    text("CALIBRATE", controlBoxX+265, controlBoxY+175);
    
    textFont(fontAwesome, 16);
    text("", controlBoxX+258, controlBoxY+41); //start icon
    text("", controlBoxX+258, controlBoxY+86); //pause icon
    text("", controlBoxX+258, controlBoxY+131); //stop icon
    
    if((serialPort.active()) && (activePortName != "NONE")) {
      textFont(segoeFont, boxTitleFontSize);
      fill(colorMediumBlack);
      text(activePortName, infoBoxX+290, infoBoxY+75);
    }
    
    
    
    //------ Main Window Contents End Here -------//
  }
  
  if((portCount == 0) || (!serialPort.active())) {
    //serialPort.stop();
    serialSuccess = false;
    startPressed = false;
    startMainWindow = false;
    isPortError = true;
    serialStatus = 0;
    printVerbose("Main Window Port 0");
  }
}

//----------------------------------------------------------------------//

void establishSerial() {
  if (!serialSuccess) {
    getSerialPortInfo();
    
    if ((portCount> 0) && (selectPortValue > -1) && (selectPortValue < portCount)) {
      //background(colorDarkGrey);
      printVerbose("establishSerial");
      activePortName = Serial.list()[selectPortValue];
      printVerbose("establishSerial-2");
      serialPort = new Serial(this, activePortName, 9600);
      activePortValue = selectPortValue;
      println("Serial Communication Established");
      println("Listing ports");
      println(Serial.list()); //list the available ports
      println();
      print("Selected Port is ");
      println(activePortName); //print selected port name
      print("portValue = ");
      println(activePortValue); //print the port value use selected
      print("Total no. of ports = ");
      println(Serial.list().length); //total no. of ports
      println();
      serialSuccess = true;
      isPortError = false;
      printVerbose("Serial Success");
    } 
    
    else {
      serialStatus = 0;
      println("Error : Could not find the port specified");
      println();
      //background(colorDarkGrey);
      isPortError = true; //error opening the port
      //isMainWindowStarted = false;
      serialSuccess = false; //serial com error
      startPressed = false; //causes returning to home screen
      //printVerbose("Error Serial");
    }
  }
}

//----------------------------------------------------------------------//

void showAboutWindow() {
}

//-----------------------------------------------------------------------//