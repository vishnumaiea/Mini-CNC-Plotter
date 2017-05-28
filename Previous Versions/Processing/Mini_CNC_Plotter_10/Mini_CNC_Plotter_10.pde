
//-----------------------------------------------------------------------//

//   -- Mini CNC Plotter - 10 --
//
//   I've replaced all the Font Awesome icons with objects.
//
//   Author : Vishnu M Aiea
//   E-Mail : vishnumaiea@gmail.com
//   Web : www.vishnumaiea.in
//   Date created : 12:20 PM 27-04-2017, Thursday
//   Last modified : 12:23 PM 03-05-2017, Wednesday

//-----------------------------------------------------------------------//

import processing.serial.*;

Serial serialPort;

//-----------------------------------------------------------------------//

//class definitons

public class uiButton {
  int buttonWidth;
  int buttonHeight;
  int buttonX;
  int buttonY;
  color buttonColor;
  color buttonDefaultColor;
  color buttonHoverColor;
  color labelColor;
  color labelDefaultColor;
  color labelHoverColor;
  String buttonLabel;
  boolean ifPressed;
  boolean ifClicked;

  uiButton (int a, int b, int c, int d, String e, color f, color g, color h, color i) {
    buttonX = a;
    buttonY = b;
    buttonWidth = c;
    buttonHeight = d;
    buttonLabel = e;
    buttonColor = f;
    buttonDefaultColor = buttonColor;
    buttonHoverColor = g;
    labelColor = h;
    labelDefaultColor = labelColor;
    labelHoverColor = i;
    ifPressed = false;
    ifClicked = false;
  }
  void displayButton () {
    fill(this.buttonColor);
    rect(this.buttonX, this.buttonY, this.buttonWidth, this.buttonHeight);
  }

  boolean isHover () {
    if ((mouseX>=this.buttonX) && (mouseX<=(this.buttonX + this.buttonWidth)) 
      && (mouseY>=this.buttonY) && (mouseY<=(this.buttonY + this.buttonHeight))) {
      buttonColor = buttonHoverColor;
      labelColor = labelHoverColor;
      return true;
    } else {
      buttonColor = buttonDefaultColor;
      labelColor = labelDefaultColor;
      return false;
    }
  }

  boolean isPressed () {
    if (isHover()) {
      if (mousePressed && (mouseButton == LEFT)) {
        ifPressed = true;
        //println(buttonLabel + " is pressed");
        return true;
      }
    }
    return false;
  }

  boolean isClicked () {
    if (isHover()) {
      if (mousePressed && (mouseButton == LEFT) && (!mouseStatus)) {
        ifClicked = true;
        mouseStatus = true;
        return true;
      }
      if ((!mousePressed) && (mouseStatus)) {
        //println(buttonLabel + " is clicked");
        mouseStatus = false;
        return true;
      }
    }

    if ((!isHover()) && (mouseStatus)) {
      mouseStatus = false;
    }
    return false;
  }
} //uiButton class ends


public class fontIcon {
  int iconX;
  int iconY;
  int fontSize;
  PFont iconFont;
  String iconChar;
  color iconColor;
  color iconDefaultColor;
  color iconHoverColor;
  color iconPressedColor;
  
  fontIcon (int a, int b, String c, PFont d, int e, color f, color g, color h) {
    iconX = a;
    iconY = b;
    iconChar = c;
    iconFont = d;
    fontSize = e;
    iconColor = f;
    iconDefaultColor = iconColor;
    iconHoverColor = g;
    iconPressedColor = h;
  }
  
  public void display () {
    fill(iconColor);
    textFont(iconFont, fontSize);
    text(iconChar, iconX, iconY);
  }
  
}//fontIcon class ends

//-----------------------------------------------------------------------//


String [] serialStatusList= {"Error : Could not find the port specified !", 
  "Error : Device disconnected !",
  "Serial ended !",
  "No ports available !"};

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
int mouseStatusTemp = 0;
boolean mouseStatus = false; //status of mouse input
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
color colorOrange = #F07A3F;
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


//instantiating buttons
//(X, Y, W, H, Label, buttonColor, buttonHoverColor, buttonLabelColor, buttonLabelHoverColor
uiButton startMainButton = new uiButton (220, 480, 80, 35, "Main Start Button", colorWhite, colorBlue, colorBlue, colorWhite);
uiButton quitAppButton = new uiButton (360, 480, 80, 35, "Quit Main Button", colorWhite, colorBlue, colorBlue, colorWhite);
uiButton startAboutButton = new uiButton (500, 480, 80, 35, "About Button", colorWhite, colorBlue, colorBlue, colorWhite);
uiButton portDecButton = new uiButton (330, 270, 30, 40, "Port Decrement Button", colorWhite, colorBlue, colorBlue, colorWhite);
uiButton portIncButton = new uiButton (430, 270, 30, 40, "Port Increment Button", colorWhite, colorBlue, colorBlue, colorWhite);
uiButton quitMainButton = new uiButton (748, 25, 25, 25, "Quit Main Button", #018ec6, 240, 200, colorBlue);
uiButton loadImageButton = new uiButton (100, 100, 150, 130, "My Button", 220, #006699, 50, 250);
uiButton startPlotterButton = new uiButton (100, 100, 150, 130, "My Button", 220, #006699, 50, 250);
uiButton pausePlotterButton = new uiButton (100, 100, 150, 130, "My Button", 220, #006699, 50, 250);
uiButton stopPlotterButton = new uiButton (100, 100, 150, 130, "My Button", 220, #006699, 50, 250);
uiButton plotterUpButton = new uiButton (105, 455, 50, 50, "Plotter Up Button", colorMediumGrey, colorBlue, 50, 250);
uiButton plotterDownButton = new uiButton (105, 555, 50, 50, "Plotter Down Button", colorMediumGrey, colorBlue, 50, 250);
uiButton plotterLeftButton = new uiButton (55, 505, 50, 50, "Plotter Left Button", colorMediumGrey, colorBlue, 50, 250);
uiButton plotterRightButton = new uiButton (155, 505, 50, 50, "Plotter Right Button", colorMediumGrey, colorBlue, 50, 250);
uiButton plotterPenButton = new uiButton (105, 505, 50, 50, "Plotter Pen Button", colorMediumGrey, colorBlue, 50, 250);

fontIcon plotterUpArrow;
fontIcon plotterDownArrow;
fontIcon plotterLeftArrow;
fontIcon plotterRightArrow;
fontIcon plotterPenArrow;
fontIcon plotterPenCircle;


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
  
  //instantiating character icons
  //(X, Y, char, font, fontSize, color, hoverColor, pressedColor)
  fontIcon upArrow = new fontIcon (113, 492, "", fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange);
  fontIcon downArrow = new fontIcon (113, 592, "", fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange);
  fontIcon leftArrow = new fontIcon (63, 542, "", fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange);
  fontIcon rightArrow = new fontIcon (163, 542, "", fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange);
  fontIcon penArrow = new fontIcon (122, 538, "", fontAwesome, 27, colorWhite, colorBlue, colorOrange);
  fontIcon penCircle = new fontIcon (112, 543, "", fontAwesome, 42, colorMediumGrey, colorBlue, colorOrange);
  
  plotterUpArrow = upArrow;
  plotterDownArrow = downArrow;
  plotterLeftArrow = leftArrow;
  plotterRightArrow = rightArrow;
  plotterPenArrow = penArrow;
  plotterPenCircle = penCircle;
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
  showInitialStaticInfo();
  
  if(isPortError) { //check wether a port error ocured in main window
    isPortError = false;
  }
  else {
    isPortError = false;
  }
  
  startMainButton.isHover();
  quitAppButton.isHover();
  startAboutButton.isHover();

  if (quitAppButton.isClicked()) {
    exit();
  }

  if (startMainButton.isClicked()) {
    startPressed = true;
  }

  if (startAboutButton.isClicked()) {
    aboutPressed = true;
  }
  
  if (serialStatus == 0) { //could not find the port error
    textFont(segoeFont, 15);
    fill(colorRed);
    text(serialStatusList[serialStatus], 260, 410);
  } 
  
  else if (serialStatus == 1) { // device disconnected
    textFont(segoeFont, 15);
    fill(colorRed);
    text(serialStatusList[serialStatus], 300, 410);
  } 
  
  else if(serialStatus == 2){ //serial ended by user
    textFont(segoeFont, 15);
    fill(colorRed);
    text(serialStatusList[serialStatus], 350, 410);
  }
  
  else if(serialStatus == 3) { //no ports available
    textFont(segoeFont, 15);
    fill(colorRed);
    text(serialStatusList[serialStatus], 330, 410);
  }
  
  else {
    fill(colorWhite);
    rect(260, 410, 300, 20);
  }

  getSerialPortInfo();

  if (portCount != 0) { //check if there is any port

    if ((selectPortValue == -1) || (portCount < prevPortCount)) {
      selectPortValue = 0;
    }

    if (portDecButton.isPressed()) {
      if (selectPortValue > 0) {
        selectPortValue--;
        selectPortName = Serial.list()[selectPortValue];
        mouseStatusTemp = 1;
        printVerbose("Port Decrement");
      }
    } else {
      selectPortName = Serial.list()[selectPortValue];
    }

    if (portIncButton.isPressed()) {
      if ((selectPortValue < (Serial.list().length -1 )) && (selectPortValue > -1)) {
        selectPortValue++;
        selectPortName = Serial.list()[selectPortValue];
        mouseStatusTemp = 1;
        printVerbose("Port Increment");
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
    serialStatus = 3; //no ports available
  }
  
  else if(portCount >0) {
    
    if(serialStatus == 3) {
      serialStatus = -1;
    }
  }
}

//-----------------------------------------------------------------------//

void showInitialStaticInfo () {
  smooth();
  noStroke();
  background(colorDarkGrey);
  fill(colorLightGrey);
  rect(125, 450, 550, 95); //third box in starting window
  
  startMainButton.displayButton();
  startAboutButton.displayButton();
  quitAppButton.displayButton();
  
  textFont(segoeFont, 14);
  fill(startMainButton.labelColor);
  text("START", 240, 503);
  fill(quitAppButton.labelColor);
  text("QUIT", 382, 503);
  fill(startAboutButton.labelColor);
  text("ABOUT", 518, 503);
  
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
  
  if (portCount == 0) {
    //serialPort.stop();
    serialSuccess = false;
    startPressed = false;
    startMainWindow = false;
    isPortError = true;
    serialStatus = 3; //device disconnected
    activePortName = "NONE";
    activePortValue = -1;
    selectPortName = "NONE";
    selectPortValue = -1;
    printVerbose("Zero Ports Available");
  }
  
  if ((startPressed) && (portCount != 0) && (!isPortError)) {
    if (!serialSuccess) {
      establishSerial();
    }

    if (serialSuccess) {
      startMainWindow = true;
    } 
    
    else {
      startMainWindow = false;
      startPressed = false;
      serialSuccess = false;
    }
  }
  
  if((serialSuccess) && (!isPortActive(activePortName))) {
    serialSuccess = false;
    startPressed = false;
    isPortError = true;
    startMainWindow = false;
    serialStatus = 1;
    activePortName = "NONE";
    activePortValue = -1;
    selectPortName = "NONE";
    selectPortValue = -1;
    printVerbose("Active Port Error");
  }
  
  if ((startMainWindow) && (!isPortError) && (isPortActive(activePortName))) {

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
    
    quitMainButton.displayButton();
    quitMainButton.isHover();
    fill(quitMainButton.labelColor);
    textFont(fontAwesome, 22);
    text("", 752, 45); //quit main window button
    
    if (quitMainButton.isClicked()) {
      startPressed = false;
      isPortError = false;
      serialSuccess = false;
      startMainWindow = false;
      serialStatus = 2;
      activePortName = "NONE";
      activePortValue = -1;
      selectPortName = "NONE";
      selectPortValue = -1;
      printVerbose("Connection ended by user.");
      
      if(serialPort.active()) {
        serialPort.stop();
      }
    }
    
    //--------------------------------//
    
    if (plotterUpButton.isHover()) {
       plotterUpArrow.iconColor = plotterUpArrow.iconHoverColor;
    } else {
      plotterUpArrow.iconColor = plotterUpArrow.iconDefaultColor;
    }
    
    if (plotterUpButton.isPressed()){
      plotterUpArrow.iconColor = plotterUpArrow.iconPressedColor;
    }
    
    plotterUpArrow.display();
    
    //-------------------------------//
    
    if (plotterLeftButton.isHover()) {
       plotterLeftArrow.iconColor = plotterLeftArrow.iconHoverColor;
    } else {
      plotterLeftArrow.iconColor = plotterLeftArrow.iconDefaultColor;
    }
    
    if (plotterLeftButton.isPressed()){
      plotterLeftArrow.iconColor = plotterLeftArrow.iconPressedColor;
    }
    
    plotterLeftArrow.display();
    
    //-------------------------------//
    
    if (plotterPenButton.isHover()) {
       plotterPenCircle.iconColor = plotterPenCircle.iconHoverColor;
    } else {
      plotterPenCircle.iconColor = plotterPenCircle.iconDefaultColor;
    }
    
    if (plotterPenButton.isPressed()){
      plotterPenCircle.iconColor = plotterPenCircle.iconPressedColor;
    }
    
    plotterPenCircle.display();
    plotterPenArrow.display();
    
    //------------------------------//
    
    if (plotterRightButton.isHover()) {
       plotterRightArrow.iconColor = plotterRightArrow.iconHoverColor;
    } else {
      plotterRightArrow.iconColor = plotterRightArrow.iconDefaultColor;
    }
    
    if (plotterRightButton.isPressed()){
      plotterRightArrow.iconColor = plotterRightArrow.iconPressedColor;
    }
    
    plotterRightArrow.display();
    
    //------------------------------//
    
    if (plotterDownButton.isHover()) {
       plotterDownArrow.iconColor = plotterDownArrow.iconHoverColor;
    } else {
      plotterDownArrow.iconColor = plotterDownArrow.iconDefaultColor;
    }
    
    if (plotterDownButton.isPressed()){
      plotterDownArrow.iconColor = plotterDownArrow.iconPressedColor;
    }
    
    plotterDownArrow.display();
    
    //------------------------------//

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

    if ((serialPort.active()) && (activePortName != "NONE")) {
      textFont(segoeFont, boxTitleFontSize);
      fill(colorMediumBlack);
      text(activePortName, infoBoxX+290, infoBoxY+75);
    }



    //------ Main Window Contents End Here -------//
  }
}

//----------------------------------------------------------------------//

void establishSerial() {
  if (!serialSuccess) {
    getSerialPortInfo();

    if ((portCount> 0) && (selectPortValue > -1) && (selectPortValue < portCount)) {
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
      printVerbose("Serial Establish Success");
    } 
    
    else {
      serialStatus = 0;
      println("Error : Could not find the port specified");
      println();
      serialSuccess = false; //serial com error
      startPressed = false; //causes returning to home screen
      printVerbose("Serial Establish Error");
    }
  }
}

//----------------------------------------------------------------------//

boolean isPortActive (String portTocheck) {
  boolean portActiveStatus = false;
  if (portCount > 0) {
    for (int i=0; i<portCount; i++) {
      if (portTocheck.equals(Serial.list()[i])) {
        //println(Serial.list()[i]);
        portActiveStatus = true;
        isPortError = false;
        break;
      }
      if ((i == (portCount-1))) {
        portActiveStatus = false;
        isPortError = true;
      }
    }
  }
  return portActiveStatus;
}

//----------------------------------------------------------------------//

void showAboutWindow() {
}

//-----------------------------------------------------------------------//