
//--------------------------------------------------------------//

//   -- Mini CNC Plotter - 02 --
//
//   Successfully implemented the line counting function with
//   variable array length.
//
//   Copyright (c) 2017 Vishnu M Aiea
//   E-Mail : vishnumaiea@gmail.com
//   Web : www.vishnumaiea.in
//   Date created : 12:20 PM 27-04-2017, Thursday
//   Last modified : 7:51 PM 28-04-2017, Friday

//--------------------------------------------------------------//

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

//-------------------------------------------------------------//

void setup() {
  size(800, 650);
  background(170);
  surface.setTitle("Processing PNG Image");
  img = loadImage("arduino.png");
  imageHeight = img.height;
  imageWidth = img.width;
}

//-------------------------------------------------------------//

void draw() {
  background(255);
  image(img, 250, 150);

  if (runCount == 0) {
    for (int y=0; y<imageHeight; y++) { //loop until image height or rows
      for (int x=0; x<imageWidth; x++) { //loop until image width or columns
        pixelColor = isPixelBlack(x, y); //get the color of the pixel
        
        if (x==0) { //if cords are starting of any row
          prevPixelColor = false; //prev pixel color is true = black
        }
        
        else if (x != 0) { //if cords are not starting of any row
          prevPixelColor = isPixelBlack((x-1), y); //get the prev pixel's color
        } 
        
        if(lineCount > (lineCountLimit - 1)) { //double the array size if limit reached
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
    runCount++;
  }
}

//-----------------------------------------------------------//

boolean isPixelBlack(int x, int y) {
  pixelLocation = (x+(y*imageWidth));
  pixelRed = (int) red(img.pixels[pixelLocation]);
  pixelGreen = (int) green(img.pixels[pixelLocation]);
  pixelBlue = (int) blue(img.pixels[pixelLocation]);

  if ((pixelRed > 10) && (pixelGreen > 10) && (pixelBlue > 10)) {
    return false;
  } 
  
  else if ((pixelRed < 10) && (pixelGreen < 10) && (pixelBlue < 10)) {
    return true;
  }
  return false;
}