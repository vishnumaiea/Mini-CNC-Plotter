
//=========================================================================//

//   -- Mini CNC Plotter --
//
//   Added all the required fonts to data folder.
//
//
//   Author : Vishnu M Aiea
//   E-Mail : vishnumaiea@gmail.com
//   Web : www.vishnumaiea.in
//   Date created : 12:20 PM 27-04-2017, Thursday
//   Last modified : 12:00:44 PM, 29-06-2017, Thursday

//=========================================================================//

import processing.serial.*;
Serial serialPort;

//=========================================================================//
//freehand algorithm specific definitons

static final int EDGE_MARKER = 120; //pixel markers
static final int END_MARKER = 50;
static final int NIB_MARKER = 57;
static final int START_MARKER = 68;
static final int CORNER_MARKER = 70;
static final int ISOLATED_MARKER = 87;
static final int POINT_MARKER = 93;
static final int INVALID = -1;

static final int DEFAULT_IMAGE_WIDTH = 600;
static final int DEFAULT_IMAGE_HEIGHT = 600;

//debug and error severity levels
static final int SEVERITY_CRITICAL = 10;
static final int SEVERITY_HIGH = 9;
static final int SEVERITY_MEDIUM = 8;
static final int SEVERITY_INFO = 7;
static final int SEVERITY_WARNING = 6;
static final int SEVERITY_MESSAGE = 5;
static final int SEVERITY_VERBOSE = 4;

imgObject selectedImage; //array for image
imgObject outlineImage;
imgObject solidImage;

int iterationCount;
int EXIT_AT_ERROR = 1;
int DEBUG_LEVEL = SEVERITY_CRITICAL;

int L = -1;
int TL = -1 * (DEFAULT_IMAGE_WIDTH + 1); //assuming opened image has default W and H
int T = -1 * (DEFAULT_IMAGE_WIDTH);
int TR = -1 * (DEFAULT_IMAGE_WIDTH - 1);
int R = 1;
int BR = (DEFAULT_IMAGE_WIDTH + 1);
int B = DEFAULT_IMAGE_WIDTH;
int BL = (DEFAULT_IMAGE_WIDTH - 1);

//scanning pattern for array postitions
int [] scanningPattern = new int [] {L, TL, T, TR, R, BR, B, BL}; //square pattern
//int [] scanningPattern = new int [L, T, R, B, TL, TR, BR, BL]; //diamond pattern
//int [] scanningPattern = new int [TL, TR, BR, BL, L, T, R, B]; //star pattern

//scanning pattern for XY coordinates
//int [] scanningPatternX = new int [] {-1, -1, 0, 1, 1, 1, 0, -1}; //L, TL, T, TR, R, BR, B, BL - cyclic pattern
//int [] scanningPatternY = new int [] {0, -1, -1, -1, 0, 1, 1, 1}; //L, TL, T, TR, R, BR, B, BL

int [] scanningPatternX = new int [] {-1, 0, 1, 0, -1, -1, 1, 1}; //L, T, R, B, BL, TL, TR, BR - diamond pattern (friends first)
int [] scanningPatternY = new int [] {0, -1, 0, 1, 1, -1, -1, 1}; //L, T, R, B, BL, TL, TR, BR

//=========================================================================//
//class definitons

//-------------------------------------------------------------------------//
//image object class

public class imgObject {

  public class pixelObject {
    int X, Y, position;
    int [] adjacentPixels = new int[8];

    //=========================================================================//
    pixelObject () { //empty constructor
      X = 0;
      Y = 0;
      position = 0;
    }
    //-------------------------------------------------------------------------//

    pixelObject (int a) { //takes pixel postion in array
      position = a;
      X = (position % imageWidth);
      Y = (position - (position % imageWidth)) / imageWidth;
    }
    //-------------------------------------------------------------------------//

    pixelObject (pixelObject sourceObject) { //copy constructor
      this.X = sourceObject.X;
      this.Y = sourceObject.Y;
      sourceObject.position = (sourceObject.X + (sourceObject.Y * imageWidth));
      this.position = sourceObject.position;
    }
    //=========================================================================//

    int getPosition() {
      calculatePosition(); //find the pixel location in PImage from coords
      return position;
    }
    //=========================================================================//
    //sets values of the pixel object

    void set(int a) { //takes array position
      if(a >= 0) {
        position = a;
        calculateXY();
        findAdjacentPixels();
      }
      else if(a == INVALID) {
        position = INVALID;
        X = INVALID;
        Y = INVALID;
      }
      else {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at set(int) : Negative input : " + a);
          println("Current Pixel : Position = " + currentPixel.position + " X = " + currentPixel.X + " Y = " + currentPixel.Y);
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }
    }
    //-------------------------------------------------------------------------//

    void set(pixelObject sourceObject) { //takes a pixel object
      this.X = sourceObject.X; //copy X value
      this.Y = sourceObject.Y; //copy Y value
      sourceObject.position = (sourceObject.X + (sourceObject.Y * imageWidth)); //recalculate both positions
      this.position = sourceObject.position;
      findAdjacentPixels();
    }
    //-------------------------------------------------------------------------//

    void set(int x, int y) {
      if((x >= 0) && (y >= 0) && (x < imageWidth) && (y < imageHeight)) {
        X = x;
        Y = y;
        calculatePosition();
        findAdjacentPixels();
      }
      else {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at set(int, int) : XY out of bound");
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }
    }
    //=========================================================================//

    void calculateXY() {
      X = (position % imageWidth); //calculate X from position
      Y = (position - (position % imageWidth)) / imageWidth; //calculate Y from position
    }
    //=========================================================================//

    void calculatePosition() {
      position = (X + (Y * imageWidth)); //find the pixel location in PImage from coords
    }

    //=========================================================================//
    //finds all the 8 (excpet boundary pixels) adjacent pixels of a pixel

    void findAdjacentPixels () {
      calculateXY();
      int x, y;

      for(int i=0; i<8; i++) {
        x = X + scanningPatternX[i]; //calculate the adjacent pixel's x
        y = Y + scanningPatternY[i]; //calculate the adjacent pixel's y

        if((x>=0) && (y>=0) && (x < imageWidth) && (y < imageHeight)) { //if within limits
          adjacentPixels[i] = (x + (y * imageWidth)); //save as positions
        }
        else {
          adjacentPixels[i] = INVALID;
        }
      }
    }
    //=========================================================================//
    //determines if a pixel is friend of the pixel object

    boolean isFriend (int pos) { //position in image array
      if((pos < 0) || (pos > ((imageWidth * imageHeight)-1))) {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at isFriend(int) : invalid position parameter");
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }

      int x = (pos % imageWidth); //calculate X from position
      int y = (pos - (pos % imageWidth)) / imageWidth; //calculate Y from position
      calculateXY(); //recalculate pixel objects coordinates
      if(!isPixelBlack(pos)) return false;

      else {
        if((x == X) && (y == (Y-1))) return true; //top
        else if((x == (X+1)) && (y == Y)) return true; //right
        else if((x == X) && (y == (Y+1))) return true; //bottom
        else if((x == (X-1)) && (y == Y)) return true; //left
        else return false;
      }
    }
    //-------------------------------------------------------------------------//
    //overloaded version

    boolean isFriend (int x, int y) {
      if((x<0) || (y<0) || (x > (imageWidth-1)) || (y > (imageHeight-1))) {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at isFriend(int, int) : invalid input coordinates");
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }
      calculateXY(); //recalculate pixel objects coordinates
      if(!isPixelBlack(x, y)) return false;

      else {
        if((x == X) && (y == (Y-1))) return true; //top
        else if((x == (X+1)) && (y == Y)) return true; //right
        else if((x == X) && (y == (Y+1))) return true; //bottom
        else if((x == (X-1)) && (y == Y)) return true; //left
        else return false;
      }
    }
    //=========================================================================//
    //checks if a pixel is neighbor of the pixel object

    boolean isNeighbor (int pos) {
      if((pos < 0) || (pos > ((imageWidth * imageHeight)-1))) {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at isNeighbor(int) : invalid position parameter");
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }

      int x = (pos % imageWidth); //calculate X from position
      int y = (pos - (pos % imageWidth)) / imageWidth; //calculate Y from position
      calculateXY(); //recalculate pixel objects coordinates
      if(!isPixelBlack(pos)) return false;

      else {
        if((x == (X-1)) && (y == (Y-1))) return true; //top-left
        else if((x == (X+1)) && (y == (Y-1))) return true; //top-right
        else if((x == (X+1)) && (y == (Y+1))) return true; //bottom-right
        else if((x == (X-1)) && (y == (Y+1))) return true; //bottom-left
        else return false;
      }
    }

    //-------------------------------------------------------------------------//
    //overloaded version

    boolean isNeighbor (int x, int y) {
      if((x<0) || (y<0) || (x > (imageWidth-1)) || (y > (imageHeight-1))) {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at isNeighbor(int, int) : invalid input coordinates");
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }
      calculateXY(); //recalculate pixel objects coordinates
      if(!isPixelBlack(x, y)) return false;

      else {
        if((x == (X-1)) && (y == (Y-1))) return true; //top-left
        else if((x == (X+1)) && (y == (Y-1))) return true; //top-right
        else if((x == (X+1)) && (y == (Y+1))) return true; //bottom-right
        else if((x == (X-1)) && (y == (Y+1))) return true; //bottom-left
        else return false;
      }
    }
    //=========================================================================//
    //determines if a pixel is either a neighbor or friend of the pixel object

    boolean isAdjacent (int pos) {
      if((pos < 0) || (pos > ((imageWidth * imageHeight)-1))) {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at isAdjacent(int) : invalid position parameter");
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }

      calculateXY(); //recalculate pixel objects coordinates
      if(!isPixelBlack(pos)) return false;

      else if(isFriend(pos) || isNeighbor(pos)) return true;
      else return false;
    }

    //-------------------------------------------------------------------------//

    boolean isAdjacent (int x, int y) {
      if((x<0) || (y<0) || (x > (imageWidth-1)) || (y > (imageHeight-1))) {
        if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
          println("Error at isNeighbor(int, int) : invalid input coordinates");
        }
        if(EXIT_AT_ERROR == 1) System.exit(-1);
      }

      calculateXY(); //recalculate pixel objects coordinates
      if(!isPixelBlack(x, y)) return false;

      else if(isFriend(x, y) || isNeighbor(x, y)) return true;
      else return false;
    }
    //=========================================================================//
  } //pixelObject ends

  //=========================================================================//
  //imgObject declarations and functions

  PImage imageArray;
  int imageWidth, imageHeight;
  int blackPixelCount, edgePixelCount, nibPixelCount, nibPixelUsedCount, segmentCount;
  int [] edgePixelArray;
  int [] nibPixelArray;
  int [] segmentArray;
  int [] segmentMarkerArray;
  int [] ignoredPixelArray;
  int segmentMarkerCount, segmentEndMarkerCount, segmentStartMarkerCount, segmentPointMarkerCount, redundantMarkerCount;
  int ignoredPixelCount, imageXIndexLimit, imageYIndexLimit, segmentArrayLength;
  int [] loopCounter = new int [10];
  pixelObject currentPixel, prevPixel, lastStartPixel, lastEndPixel, lastPointPixel, lastNibPixel;
  boolean isTracingCompleted, scanningFinished, scanningError, edgeDetected, nibDetected;

  //=========================================================================//
  //accepts image path

  imgObject (String imageName) {
    imageArray = loadImage(imageName);
    initImgObject();
  }

  //-------------------------------------------------------------------------//
  //acceptss an inbuilt PImage object

  imgObject (PImage sourceImageArray) {
    imageArray = sourceImageArray;
    initImgObject();
  }

  //-------------------------------------------------------------------------//
  //accepts another imgObject

  imgObject (imgObject sourceImage) {
    imageArray = sourceImage.imageArray;
    initImgObject();
  }

  //-------------------------------------------------------------------------//
  //creates image with default sizes
  imgObject () {
    imageArray = createImage(DEFAULT_IMAGE_WIDTH, DEFAULT_IMAGE_HEIGHT, RGB);
    initImgObject();
  }
  //=========================================================================//
  //initialize rest of the object elements

  void initImgObject () {
    imageHeight = imageArray.height;
    imageWidth = imageArray.width;
    edgePixelArray = new int [imageWidth * imageHeight]; //array for outline
    nibPixelArray = new int [imageWidth * imageHeight]; //array for EOF pixels
    segmentArray = new int [imageWidth * imageHeight]; //array for segments
    segmentMarkerArray = new int [imageWidth * imageHeight];
    imageXIndexLimit = imageWidth - 1;
    imageYIndexLimit = imageHeight - 1;
    blackPixelCount = 0;
    edgePixelCount = 0;
    nibPixelCount = 0;
    nibPixelUsedCount = 0;
    segmentCount = 0;
    segmentMarkerCount = 0;
    segmentStartMarkerCount = 0;
    segmentEndMarkerCount = 0;
    segmentPointMarkerCount = 0;
    segmentArrayLength = 0;
    isTracingCompleted = true;
    scanningFinished = false;
    scanningError = false;
    edgeDetected = false;
    nibDetected = false;
    lastStartPixel = new pixelObject();
    lastEndPixel = new pixelObject();
    lastPointPixel = new pixelObject();
    currentPixel = new pixelObject();
    prevPixel = new pixelObject();
    findBlackPixels();
  }
  //=========================================================================//
  //finds edge pixels from a bitmap/png image and stores them to an array

  public int findEdgePixels () {
    edgePixelCount = 0;
    edgeDetected = false;
    for(int y=0; y<imageHeight; y++) {
      for(int x=0; x<imageWidth; x++) {
        if(isEdgePixel(x, y)) { //edge of a solid fill
          edgePixelArray [edgePixelCount] = convertToPosition(x, y); //mark that pixel
          edgePixelCount++;
          //println("Edge pixel found : " + "X = " + x + ", Y = " + y + ", N = " + getNeighborsCount(x,y) + ", F = " + getFriendsCount(x,y));
        }
      }
    }
    if(DEBUG_LEVEL <= SEVERITY_INFO) {
      println("Edge pixel count = " + edgePixelCount);
      if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
        printVerbose();
      }
    }
    edgeDetected = true;
    return edgePixelCount;
  }
  //=========================================================================//
  //finds end of line pixels from a bitmap/png image and stores them to an array

  public int findNibPixels () {
    nibPixelCount = 0;
    nibDetected = false;
    for(int y=0; y<imageHeight; y++) {
      for(int x=0; x<imageWidth; x++) {
        if(isNibPixel(x, y)) { //edge of a solid fill
          nibPixelArray [nibPixelCount] = convertToPosition(x, y);
          nibPixelCount++;
          //println("End pixel found : " + "X = " + x + ", Y = " + y + ", N = " + getNeighborsCount(x,y) + ", F = " + getFriendsCount(x,y));
        }
      }
    }
    if(DEBUG_LEVEL <= SEVERITY_INFO) {
      println("End pixel count = " + nibPixelCount);
    }
    nibDetected = true;
    return nibPixelCount;
  }

  //=========================================================================//
  //finds all the black pixels in an image

  public int findBlackPixels () {
    blackPixelCount = 0;
    for(int y=0; y<imageHeight; y++) {
      for(int x=0; x<imageWidth; x++) {
        if(isPixelBlack(x, y)) { //edge of a solid fill
          blackPixelCount++;
        }
      }
    }
    if(DEBUG_LEVEL <= SEVERITY_INFO) {
      println("Black pixel count = " + blackPixelCount);
    }
    return blackPixelCount; //total count
  }
  //=========================================================================//
  //finds curved and straight lines, loops and other segments in the image
  //saves them to a 1D array ready to be processed by the plotting function

  public int findSegments () {
    segmentCount = 0;
    findNibPixels();
    findEdgePixels();
    if(DEBUG_LEVEL <= SEVERITY_INFO) {
      println("Finding segments..");
    }

    while((segmentArrayLength < (edgePixelCount+redundantMarkerCount)) && (!scanningError) && (!scanningFinished)) { //loop until all the black pixels are fetched
      if((isTracingCompleted) && (!scanningError) && (!scanningFinished)) { //we only need to do this if an end marker was set or we're just starting scanning
        if((nibPixelCount > nibPixelUsedCount) && (!scanningError) && (!scanningFinished)) { //nibs are used as start pixels
          currentPixel.set(nibPixelArray[nibPixelUsedCount]); //set current as one of the nib pixes
          if(DEBUG_LEVEL <= SEVERITY_MESSAGE) {
            println();
            println("Pixel update 01 : P = " + currentPixel.position + ", X = " + currentPixel.X + ", Y = " + currentPixel.Y);
          }
          segmentArray[segmentArrayLength] = nibPixelArray[nibPixelUsedCount]; //copy the nib pixel to segment array
          segmentMarkerArray[segmentArrayLength] = START_MARKER; //add marker to segment marker array
          prevPixel.set(segmentArray[segmentArrayLength]); //set the current pixel as prev pixel
          lastStartPixel.set(segmentArray[segmentArrayLength]); //last start position is now current pixel
          segmentArrayLength++; //segment array has advanced one position
          segmentStartMarkerCount++; //so these
          segmentMarkerCount++;
          nibPixelUsedCount += 2; //becasue nib pixel array stores start and end pixels as [S, E, S, E..]
          if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
            printVerbose();
          }


          //if((segmentArray[segmentArrayLength-1] < 0) || (segmentArray[segmentArrayLength-1] > ((imageWidth * imageHeight)-1))) {
          if(segmentArray[segmentArrayLength-1] < 0) { //segmentArrayLength can now be greater than total number of pixels
            if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
              println("Error : Corrupted segment array!");
              println("Invalid co-ordinates found in segment array.");
              println("Program will now terminate.");
            }
            if(EXIT_AT_ERROR == 1) System.exit(-1);
          }
        }

        //when there's no more black pixels to scan
        else if((!scanningError) && (!scanningFinished)){
          if(getFirstBlackPixel() == INVALID) {
            scanningFinished = true; //finish the scanning
            isTracingCompleted = true;
            if(segmentMarkerArray[segmentMarkerCount] != END_MARKER) {
              segmentMarkerArray[segmentMarkerCount] = END_MARKER; //mark the end of segment
              lastEndPixel.set(segmentArray[segmentArrayLength]);
              segmentMarkerCount++;
              segmentEndMarkerCount++;
              segmentArrayLength++;
              segmentCount++;
            }
            if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
              printVerbose();
            }
          }

          else { //if there are still black pixels
            //if there are no nib pixels, we could use the first unmarked pixel from the edge pixel array
            currentPixel.set(getFirstBlackPixel()); //find the first black pixel which need not to be a nib pixel
            if(DEBUG_LEVEL <= SEVERITY_MESSAGE) {
              println();
              println("Pixel update 02 : P = " + currentPixel.position + ", X = " + currentPixel.X + ", Y = " + currentPixel.Y);
            }
            segmentArray[segmentArrayLength] = currentPixel.getPosition(); //save it to segment array
            segmentMarkerArray[segmentArrayLength] = START_MARKER; //it's a starting point
            prevPixel.set(segmentArray[segmentArrayLength]); //save as previous pixel
            lastStartPixel.set(segmentArray[segmentArrayLength]); //also as start pixel
            segmentArrayLength++;
            segmentMarkerCount++;
            segmentStartMarkerCount++;
            if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
              printVerbose();
            }
          }
        }
      }

      //currentPixel is a temp pixel object for pixel manipulation
      //at start, current pixel will be start pixel
      if((!scanningError) && (!scanningFinished)) { //we check for errors all the time because it could happen any time!
        if(getFirstAdjacentPixel() == INVALID) {
          if(getFirstBlackPixel() == INVALID) {
            isTracingCompleted = true;
            scanningFinished = true;
            segmentMarkerArray[segmentArrayLength] = END_MARKER; //it's a starting point
            prevPixel.set(segmentArray[segmentArrayLength]); //save as previous pixel
            lastEndPixel.set(segmentArray[segmentArrayLength]); //also as start pixel
            segmentArrayLength++;
            segmentMarkerCount++;
            segmentEndMarkerCount++;
            if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
              printVerbose();
            }
          }

          else {
            currentPixel.set(getFirstBlackPixel()); //find the first black pixel which need not to be a nib pixel
            if(DEBUG_LEVEL <= SEVERITY_MESSAGE) {
              println();
              println("Pixel update 10 : P = " + currentPixel.position + ", X = " + currentPixel.X + ", Y = " + currentPixel.Y);
            }
            segmentArray[segmentArrayLength] = currentPixel.getPosition(); //save it to segment array
            segmentMarkerArray[segmentArrayLength] = START_MARKER; //it's a starting point
            prevPixel.set(segmentArray[segmentArrayLength]); //save as previous pixel
            lastStartPixel.set(segmentArray[segmentArrayLength]); //also as start pixel
            segmentArrayLength++;
            segmentMarkerCount++;
            segmentStartMarkerCount++;
            if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
              printVerbose();
            }
          }
        }
        else {
          currentPixel.set(getFirstAdjacentPixel()); //now we have a marker set, let's find the next pixel
          if(DEBUG_LEVEL <= SEVERITY_MESSAGE) {
            println();
            println("Pixel update 03 : P = " + currentPixel.position + ", X = " + currentPixel.X + ", Y = " + currentPixel.Y);
          }
          if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
            printVerbose();
          }
        }
      }

      //if we find a nib pixel
      if((isNibPixel(currentPixel)) && (isEdgePixel(currentPixel)) && (!scanningError) && (!scanningFinished)) { //send as object
        segmentArray[segmentArrayLength] = currentPixel.getPosition(); //save tehe pixel to the segment array
        segmentMarkerArray[segmentArrayLength] = END_MARKER; //mark it as END
        prevPixel.set(currentPixel.getPosition()); //save as prev pixel
        lastEndPixel.set(currentPixel.getPosition()); //we found an end pixel
        isTracingCompleted = true; //tracing is fully scanning a single segment
        segmentArrayLength++;
        segmentMarkerCount++;
        segmentEndMarkerCount++;
        segmentCount++;
        if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
          printVerbose();
        }
      }

      //if the getFirstAdjacentPixel() return an already marked pixel
      else if((isMarked(currentPixel)) && (isEdgePixel(currentPixel)) && (!scanningError) && (!scanningFinished)) { //check if currentPixel (object) is already marked
        if(lastStartPixel.position == prevPixel.position) { //the last start pixel has nowhere to connect
          segmentArray[segmentArrayLength] = currentPixel.getPosition(); //save the already mared pixel to the segment array
          segmentMarkerArray[segmentArrayLength] = END_MARKER; //mark it as END
          prevPixel.set(currentPixel.getPosition()); //save as prev pixel
          lastEndPixel.set(currentPixel.getPosition()); //we found an end pixel
          isTracingCompleted = true; //tracing is fully scanning a single segment
          segmentArrayLength++;
          segmentMarkerCount++;
          segmentEndMarkerCount++;
          redundantMarkerCount++; //becasue we used an already marked pixel as an end pixel
          segmentCount++;
          //at the end we'll have a segment wil only two pixels; one start and one end
          if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
            printVerbose();
          }
        }

        //otherwise it could be an end of loop
        else if (isEdgePixel(currentPixel)){
          segmentMarkerArray[segmentArrayLength-1] = END_MARKER; //it's not an end pixel but an end of loop
          lastEndPixel.set(segmentArray[segmentArrayLength-1]);
          currentPixel.set(prevPixel.position); //set current pixel to previous pixel : from postion value
          if(DEBUG_LEVEL <= SEVERITY_MESSAGE) {
            println();
            println("Pixel update 05 : P = " + currentPixel.position + ", X = " + currentPixel.X + ", Y = " + currentPixel.Y);
          }
          isTracingCompleted = true; //completed a segment
          segmentPointMarkerCount -= 1; //becasue we've just used a previously marked point pixel as end pixel (no change in segmentArraylength)
          segmentEndMarkerCount++;
          segmentCount++;
          if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
            printVerbose();
          }
        }
      }

      //finally we check if the pixel is a point in line (not start or end)
      else if((isEdgePixel(currentPixel)) && (!scanningError) && (!scanningFinished)) { //just to make sure that it's apoint in a line
        segmentArray[segmentArrayLength] = currentPixel.getPosition();
        segmentMarkerArray[segmentArrayLength] = POINT_MARKER;
        prevPixel.set(currentPixel.getPosition());
        isTracingCompleted = false;
        segmentArrayLength++;
        segmentMarkerCount++;
        segmentPointMarkerCount++;
      }
    } //while ends

    if(!scanningError) {
       if(segmentMarkerArray[segmentMarkerCount-1] != END_MARKER) {
         segmentMarkerArray[segmentMarkerCount-1] = END_MARKER;
         lastEndPixel.set(segmentArray[segmentArrayLength-1]);
         segmentEndMarkerCount++;
         segmentPointMarkerCount--;
         segmentCount++;
       }
       if(DEBUG_LEVEL <= SEVERITY_INFO) {
         println();
         println("--- Scanning Finished ----");
      }
       if(DEBUG_LEVEL <= SEVERITY_VERBOSE) {
         printVerbose();
       }
       return segmentCount;
     }
     else return INVALID;
   }
  //=========================================================================//
  //prints all the variable values and flag status

  public void printVerbose () {
    println();
    println("Current Pixel : P = " + currentPixel.position + ", X = " + currentPixel.X + ", Y = " + currentPixel.Y);
    println("Prev Pixel : P = " + prevPixel.position + ", X = " + prevPixel.X + ", Y = " + prevPixel.Y);
    println("Last Start Pixel : P = " + lastStartPixel.position);
    println("Last End Pixel : P = " + lastEndPixel.position);
    println("isPixelBlack = " + isPixelBlack(currentPixel.position));
    println("isNibPixel = " + isNibPixel(currentPixel.position));
    println("isEdgePixel = " + isEdgePixel(currentPixel.position));
    println("isMarked = " + isMarked(currentPixel.position));
    println("Black Pixel Count = " + blackPixelCount);
    println("Nib Pixel Count = " + nibPixelCount);
    println("Nib Used Pixel Count = " + nibPixelUsedCount);
    println("Edge Pixel Count = " + edgePixelCount);
    println("Segment Array Length = " + segmentArrayLength);
    println("Segment Count = " + segmentCount);
    println("Segment Marker Count = " + segmentMarkerCount);
    println("Segment Start Marker Count = " + segmentStartMarkerCount);
    println("Segment End Marker Count = " + segmentEndMarkerCount);
    println("Segment Point Marker Count = " + segmentPointMarkerCount);
    println("Segment Redundant Marker Count = " + redundantMarkerCount);
  }
  //=========================================================================//
  //returns first unmarked black pixel in the image

  int getFirstBlackPixel () {
    for(int y=0; y<imageHeight; y++) {
      for(int x=0; x<imageWidth; x++) {
        if((isEdgePixel(x, y)) && (!isMarked(x, y))) {
          return (x + (y * imageWidth));
        }
      }
    }
    if(DEBUG_LEVEL <= SEVERITY_WARNING) {
      println();
      println("Error at getFirstBlackPixel() : Couldn't find any pixels!");
    }
    return INVALID;
  }
  //=========================================================================//
  //checks if a pixel was already marked

  boolean isMarked (int x, int y) {
    int pixelPosition = (x + (y * imageWidth));
    if(segmentArrayLength == 0)
      return false;
    else {
      for(int i=0; i<segmentArrayLength; i++) {
        if(segmentArray[i] == pixelPosition)
          return true;
      }
      return false;
    }
  }

  //-------------------------------------------------------------------------//

  boolean isMarked (int pixelPosition) {
    int x = (pixelPosition % imageWidth); //calculate X from position
    int y = (pixelPosition - (pixelPosition % imageWidth)) / imageWidth; //calculate Y from position
    return isMarked(x, y);
  }

  //-------------------------------------------------------------------------//

  boolean isMarked (pixelObject sourceObject) {
    return isMarked(sourceObject.X, sourceObject.Y);
  }
  //=========================================================================//
  //determines if a pixel is a point in line

  boolean isPointPixel(int x, int y) {
    if(((getNeighborsCount(x, y) + getFriendsCount(x, y)) == 2) && isEdgePixel(x,y))
      return true;
    else return false;
  }

  //-------------------------------------------------------------------------//

  boolean isPointPixel(int pixelPosition) {
    int x = (pixelPosition % imageWidth); //calculate X from position
    int y = (pixelPosition - (pixelPosition % imageWidth)) / imageWidth; //calculate Y from position
    return isPointPixel(x, y);
  }

  //-------------------------------------------------------------------------//

  boolean isPointPixel(pixelObject sourceObject) {
    return isPointPixel(sourceObject.X, sourceObject.Y);
  }
  //=========================================================================//
  //finds the first adjacent friend of a pixel

  int getFirstAdjacentFriend (int position) {
    return INVALID;
  }
  //=========================================================================//
  //finds first adjacent neighbor of a pixel

  int getFirstAdjacentNeighbor (int position) {
    return INVALID;
  }
  //=========================================================================//
  //checks if one of the surrounding pixel is black and then returns the
  //relative position which can be 0 to 8. If found, returns the first one
  //intercepted in a clockwise rotation. Whenever we refer to "pixel" or
  //"PIXEL", the pixel is assumed to be black.

  public int getFirstAdjacentPixel () {
    //println("At getFirstAdjacentPixel() : currentPixel X = " + currentPixel.X + " Y = " + currentPixel.Y);
    return getFirstAdjacentPixel(currentPixel.X, currentPixel.Y);
  }

  //-------------------------------------------------------------------------//

  public int getFirstAdjacentPixel (int position) {
    //convert to x, y and send it
    return getFirstAdjacentPixel((position % imageWidth), ((position - (position % imageWidth)) / imageWidth));
  }

  //-------------------------------------------------------------------------//

  public int getFirstAdjacentPixel (pixelObject a) {
    a.calculateXY();
    return getFirstAdjacentPixel(a.X, a.Y);
    //return getFirstAdjacentPixel((a.position % imageWidth), ((a.position - (a.position % imageWidth)) / imageWidth));
  }

  //-------------------------------------------------------------------------//

  public int getFirstAdjacentPixel (int x, int y) {
    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Invalid pixel coordinates at getFirstAdjacentPixel(int, int) " + "X = " + x + " Y = " + y);
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return INVALID;
    }

    else if(isPixelBlack(x, y))  { //check if it's a black pixel anyway
      for(int i=0; i<8; i++) { //to find unmarked pixels
        int X = x + scanningPatternX[i]; //calculate the coordinates of adjacent pixels using the predefined scanning pattern
        int Y = y + scanningPatternY[i];
        if(isPixelValid(X, Y) && isPixelBlack(X, Y) && isEdgePixel(X, Y)) { //check also if edge pixel
          if(!isMarked(X, Y)) { //if not marked
            return convertToPosition(X, Y);
          }
        }
      }

      for(int i=0; i<8; i++) { //if there's no unmarked pixels, then retrun a marked one
        int X = x + scanningPatternX[i];//calculate the coordinates of adjacent pixels using the predefined scanning pattern
        int Y = y + scanningPatternY[i];
        if(isPixelValid(X, Y) && isPixelBlack(X, Y) && isEdgePixel(X, Y)) {
          return convertToPosition(X, Y); //no need to check for unmarked
        }
      }
    }
    return INVALID;
  }
  //=========================================================================//
  //converts X,Y coordinates to position in the image array

  public int convertToPosition (int x, int y) {
    return (x + (y * imageWidth));
  }
  //=========================================================================//
  //determines if a pixel is black and is at the edge of the image or at the
  //edge of any solif shape

  public boolean isEdgePixel (pixelObject sourceObject) {
    return isEdgePixel(sourceObject.X, sourceObject.Y);
  }

  //-------------------------------------------------------------------------//

  public boolean isEdgePixel(int position) {
    return isEdgePixel((position % imageWidth), ((position - (position % imageWidth)) / imageWidth));
  }

  //-------------------------------------------------------------------------//

  public boolean isEdgePixel (int x, int y) {
    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at isEdgePixel(int, int) " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return false;
    }

    if(edgeDetected) {
      int position = convertToPosition(x, y);
      for(int i=0; i<edgePixelCount; i++) {
        if(edgePixelArray[i] == position)
          return true;
      }
      return false;
    }

    else if(isPixelBlack(x, y)) { //if a pixel is black
      if(isBorderPixel(x, y)) //if the pixel is already at image border
        return true;

      else {
        if((getFriendsCount(x, y) < 4) || isPointPixel(x, y)) return true;
        else return false;
      }
    }
    else return false;
  }
  //=========================================================================//
  //determines if a pixel is end of a line segment

  public boolean isNibPixel (pixelObject sourceObject) {
    return isNibPixel(sourceObject.X, sourceObject.Y);
  }

  //-------------------------------------------------------------------------//

  public boolean isNibPixel(int position) {
    return isNibPixel((position % imageWidth), ((position - (position % imageWidth)) / imageWidth));
  }

  //-------------------------------------------------------------------------//

  public boolean isNibPixel (int x, int y) {
    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at isNibPixel(int, int) " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return false;
    }

    if(nibDetected) {
      int position = convertToPosition(x, y);
      for(int i=0; i<nibPixelCount; i++) {
        if(nibPixelArray[i] == position)
          return true;
      }
      return false;
    }

    else if(isPixelBlack(x, y) && isEdgePixel(x, y)) {
      if((getNeighborsCount(x, y) + getFriendsCount(x,y)) == 1) //only one neighbor or friend
        return true;
      else return false;
    }
    else return false;
  }
  //=========================================================================//
  //gets the number of friends of a pixel

  public int getFriendsCount(pixelObject sourceObject) {
    return getFriendsCount(sourceObject.X, sourceObject.Y);
  }

  //-------------------------------------------------------------------------//

  public int getFriendsCount (int x, int y) {
    int friendPixelCount = 0;

    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at getFriendsCount() " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return INVALID;
    }

    for(int i=0; i<4; i++) { //assuming first four entries of scanning pattern are friends
      int X = x + scanningPatternX[i];
      int Y = y + scanningPatternY[i];
      if(isPixelValid(X, Y) && isPixelBlack(X, Y)) {
        friendPixelCount++;
      }
    }
    return friendPixelCount;
  }
  //=========================================================================//
  //gets the number of neighbors (black) of a pixel

  public int getNeighborsCount(pixelObject sourceObject) {
    return getNeighborsCount(sourceObject.X, sourceObject.Y);
  }

  //-------------------------------------------------------------------------//

  public int getNeighborsCount (int x, int y) {
    int neighborPixelCount = 0;

    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at getNeighborsCount(int, int) " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return INVALID;
    }

    for(int i=4; i<8; i++) { //assuming last four in the scanning pattern are neighbors
      int X = x + scanningPatternX[i];
      int Y = y + scanningPatternY[i];
      if(isPixelValid(X, Y) && isPixelBlack(X, Y)) {
        neighborPixelCount++;
      }
    }
    return neighborPixelCount;
  }
  //=========================================================================//
  //determines if a pixel is either at  corner or border of an image

  public boolean isBorderPixel (int x, int y) {
    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at isBorderPixel(int, int) " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return false;
    }

    if((y==0) || (x==0) || (y==imageYIndexLimit) || (x==imageXIndexLimit)) //check if pixel is at edge of image
      return true;

    else return false;
  }

  //-------------------------------------------------------------------------//

  public boolean isBorderPixel (int position) {
    return isBorderPixel((position % imageWidth), ((position - (position % imageWidth)) / imageWidth));
  }
  //=========================================================================//
  //determines if a pixel is at border of an image and is not a corner pixel

  public boolean isSideBorderPixel (int x, int y) {
    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at isSideBorderPixel(int, int) " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return false;
    }

    if (!isCornerPixel(x, y)) { //if not a corner pixel
      if ((x==0) && (y<imageYIndexLimit)) //left border
        return true;
      else if ((y==0) && (x<imageXIndexLimit)) //top border
       return true;
      else if ((x==imageXIndexLimit) && (y<imageYIndexLimit)) //right border
        return true;
      else if ((y==imageYIndexLimit) && (x<imageXIndexLimit)) //bottom border
        return true;
      else return false;
    }
    else return false; //if a corner pixel
  }
  //=========================================================================//
  //determines if a pixel is at either of the 4 corners of the image

  public boolean isCornerPixel (int x, int y) {
    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at isCornerPixel() " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return false;
    }

    if ((x==0) && (y==0))
      return true;
    else if ((x==0) && (y==imageYIndexLimit))
      return true;
    else if ((x==imageXIndexLimit) && (y==0))
      return true;
    else if ((y==imageYIndexLimit) && (x==imageXIndexLimit))
      return true;
    else return false;
  }
  //=========================================================================//
  //checks if pixel coordinates are valid
  public boolean isPixelValid (int position) {
    return isPixelValid((position % imageWidth), ((position - (position % imageWidth)) / imageWidth));
  }

  //-------------------------------------------------------------------------//

  public boolean isPixelValid (pixelObject sourceObject) {
    return isPixelValid(sourceObject.X, sourceObject.Y);
  }

  //-------------------------------------------------------------------------//

  public boolean isPixelValid (int x, int y) {
    if((x<0) || (y<0) || (x>imageXIndexLimit) || (y>imageYIndexLimit)) {
      return false;
    }
    else return true;
  }
  //=========================================================================//
  //checks if a pixel in the image is black

  public boolean isPixelBlack (int position) {
    return isPixelBlack((position % imageWidth), ((position - (position % imageWidth)) / imageWidth));
  }

  //-------------------------------------------------------------------------//

  public boolean isPixelBlack (pixelObject sourceObject) {
    return isNibPixel(sourceObject.X, sourceObject.Y);
  }

  //-------------------------------------------------------------------------//

  public boolean isPixelBlack (int x, int y) {
    if(!isPixelValid(x, y)) {
      if(DEBUG_LEVEL <= SEVERITY_CRITICAL) {
        println();
        println("Error : Invalid pixel coordinates at isPixelBlack(int, int) " + "X = " + x + " Y = " + y);
        println("Program will now terminate.");
      }
      if(EXIT_AT_ERROR == 1) System.exit(-1);
      return false;
    }

    int pixelLocation = (x+(y*imageWidth)); //calculate the pixel location in the PImage array from cords
    int pixelRed = (int) red(imageArray.pixels[pixelLocation]); //get red value of pixel
    int pixelGreen = (int) green(imageArray.pixels[pixelLocation]); //get green value of pixel
    int pixelBlue = (int) blue(imageArray.pixels[pixelLocation]); //get blue value of pixel

    if ((pixelRed > 0) && (pixelGreen > 0) && (pixelBlue > 0)) { //check if white
      return false;
    }
    else if ((pixelRed < 10) && (pixelGreen < 10) && (pixelBlue < 10)) { //check if black
      return true;
    }
    else return false; //default return
  }

  //=========================================================================//
  //creates an outline image containing only edge pixels generated by edge
  //detection algorithm

  boolean createOutlineImage () {
    outlineImage = new imgObject(this);
    outlineImage.imageArray = createImage(outlineImage.imageWidth, outlineImage.imageHeight, RGB); //create image
    this.findEdgePixels(); //first find the edge pixels from source image
    //println("Edge pixel count = " + sourceImage.edgePixelCount);
    outlineImage.imageArray.loadPixels(); //load pixels for altering

    for(int y=0; y<outlineImage.imageHeight; y++) {
      for(int x=0; x<outlineImage.imageWidth; x++) {
        int pixelLocation = (x+(y*(this.imageWidth))); //find the pixel location in PImage from coords
        outlineImage.imageArray.pixels[pixelLocation] = color(255, 255, 255);
      }
    }

    for(int i=0; i <this.edgePixelCount; i++) {
      outlineImage.imageArray.pixels[this.edgePixelArray[i]] = color(0, 0, 0);
    }
    outlineImage.imageArray.updatePixels(); //update the image
    return true;
  }
  //=========================================================================//
  //simulates CNC drawing using the segment array

  void simulateFreehand(int originX, int originY) {
    int X, Y;

    X = (selectedImage.segmentArray[loopCounter[0]] % imageWidth); //calculate X from position
    Y = (selectedImage.segmentArray[loopCounter[0]] - (selectedImage.segmentArray[loopCounter[0]] % imageWidth)) / imageWidth; //calculate Y from position
    point(originX+X, originY+Y);
    if(loopCounter[0] <(selectedImage.segmentArrayLength-1)) loopCounter[0]++;
  }

  //=========================================================================//
  //draws the image using the edge pixel array

  void simulateImageEdge(int originX, int originY) {
    int X, Y;

    X = (selectedImage.edgePixelArray[loopCounter[1]] % imageWidth); //calculate X from position
    Y = (selectedImage.edgePixelArray[loopCounter[1]] - (selectedImage.edgePixelArray[loopCounter[1]] % imageWidth)) / imageWidth; //calculate Y from position
    point(originX+X, originY+Y);
    if(loopCounter[1] <(selectedImage.edgePixelCount-1)) loopCounter[1]++;
  }
  //=========================================================================//
} //imgObject class ends

//=========================================================================//
//uiButton defines interactive buttons with hover, press and click effects.
//a button can be associated with a label defined by uiButtonLabel

public class uiButton {
  int buttonWidth, buttonHeight, buttonX, buttonY;
  color buttonColor, defaultColor, backupColor, hoverColor, activeColor, pressedColor;
  boolean ifPressed, ifClicked, ifHover, ifActive, mouseStatus;
  uiButtonLabel linkedLabel;

  //---------------------------------//
  //constructor
  uiButton (int a, int b, int c, int d, color e, color f, color g, color h) {
    buttonX = a;
    buttonY = b;
    buttonWidth = c;
    buttonHeight = d;
    buttonColor = e;
    defaultColor = buttonColor;
    backupColor = buttonColor;
    hoverColor = f;
    pressedColor = g;
    activeColor = h;
    ifHover = false;
    ifPressed = false;
    ifClicked = false;
    ifActive = false;
    mouseStatus = false;
  }

  //---------------------------------//

  void display () { //display the button and label
    fill(buttonColor);
    rect(buttonX, buttonY, buttonWidth, buttonHeight);
    linkedLabel.display(); //display the label
  }

  //---------------------------------//

  boolean isHover () { //hover effects
    if ((mouseX >= buttonX) && (mouseX <= (buttonX + buttonWidth))
      && (mouseY >= buttonY) && (mouseY <= (buttonY + buttonHeight))) {
      buttonColor = hoverColor;
      linkedLabel.labelColor = linkedLabel.hoverColor;
      ifHover = true;
      return true;
    }
    else {
      buttonColor = defaultColor;
      linkedLabel.labelColor = linkedLabel.defaultColor;
      ifHover = false;
      return false;
    }
  }

  //---------------------------------//

  boolean isPressed () { //when button is pressed
    if (isHover()) {
      if (mousePressed && (mouseButton == LEFT)) {
        ifPressed = true;
        buttonColor = pressedColor;
        return true;
      }
    }
    else {
      ifPressed = false;
    }
    return false;
  }

  //---------------------------------//

  boolean isClicked () {
    if (isHover()) {
      if (mousePressed && (mouseButton == LEFT) && (!mouseStatus)) {
        mouseStatus = true;
      }
      if ((!mousePressed) && (mouseStatus)) {
        ifClicked = true;
        mouseStatus = false;
        return true;
      }
    }

    if ((!isHover()) && (mouseStatus)) {
      mouseStatus = false;
    }
    return false;
  }

  //---------------------------------//

  void reset() { //resets color to the default color
   defaultColor = backupColor;
  }

  //---------------------------------//

  void setColor (color a) {
    defaultColor = a;
  }

  //---------------------------------//

  void setLabelColor (color a) { //set the color of the linked label
    linkedLabel.setColor(a);
  }

  //---------------------------------//

  void linkLabel (uiButtonLabel a) { //the label to link
    linkedLabel = a;
  }

  //---------------------------------//

  void setLabel (String a) { //sets label name or text
    linkedLabel.labelName = a;
  }
} //uiButton class ends

//=========================================================================//

//uiButtonLabel defines text labels with hover, press and click effects
//they must be linked with a uiButton to work

public class uiButtonLabel {

  String labelName;
  int labelX, labelY, fontSize;
  PFont labelFont;
  color labelColor, defaultColor, backupColor, hoverColor, pressedColor, activeColor;
  uiButton linkedButton;

  //---------------------------------//

  uiButtonLabel(String a, int b, int c, PFont d, int e, color f, color g, color h, color i) {
    labelName = a;
    labelX = b;
    labelY = c;
    labelFont = d;
    fontSize = e;
    labelColor = f;
    defaultColor = labelColor;
    backupColor = labelColor;
    hoverColor = g;
    pressedColor = h;
    activeColor = i;
  }

  //---------------------------------//

  void display() {

    if (linkedButton.isHover()) {
      labelColor = hoverColor;
      displayLabel();
    }

    else {
      labelColor = defaultColor;
      displayLabel();
    }
  }

  //---------------------------------//
  //displays w/t the button
  void displayLabel () {
    textFont(labelFont, fontSize);
    fill(labelColor);
    text(labelName, labelX, labelY);
  }

  //---------------------------------//

  void setColor (color a) {
    defaultColor = a;
  }

  //---------------------------------//

  void reset() {
    //labelColor = backupColor;
    defaultColor = backupColor;
  }

  //---------------------------------//

  void linkButton (uiButton a) {
    linkedButton = a;
    labelX += linkedButton.buttonX;
    labelY += linkedButton.buttonY;
  }
} //uiButtonLabel class ends

//=========================================================================//

//textLabel are standalone texts that can be placed anywhere
//they can be associated with a text labelbox defined by labelbox

public class textLabel {
  String labelName;
  int labelX;
  int labelY;
  PFont labelFont;
  int fontSize;
  color primaryColor;
  color defaultColor;

  //---------------------------------//

  textLabel (String a, int b, int c, PFont d, int e, color f) {
    labelName = a;
    labelX = b;
    labelY = c;
    labelFont = d;
    fontSize = e;
    primaryColor = f;
    defaultColor = primaryColor;
  }

  //---------------------------------//

  public void display () {
    fill(primaryColor);
    textFont(labelFont, fontSize);
    text(labelName, labelX, labelY);
  }

  //---------------------------------//

  public void setColor (color a) {
    primaryColor = a;
  }

  //---------------------------------//

  public void setLabel (String a) {
    labelName = a;
  }

  //---------------------------------//

  public void reset () {
    primaryColor = defaultColor;
  }
} //textLabel class ends

//=========================================================================//

//labelBox defines static text fields or boxes for text labels
//can be linked to a textLabel

public class labelBox {
  int width, height, x, y;
  color primaryColor, backupColor;
  boolean labelAvailable;
  textLabel linkedLabel;

  //---------------------------------//

  labelBox (int a, int b, int c, int d, color e, textLabel f) { //with associated label text
    x = a;
    y = b;
    width = c;
    height = d;
    primaryColor = e;
    backupColor = e;
    linkedLabel = f;
    labelAvailable = true;
  }

  //---------------------------------//

  labelBox (int a, int b, int c, int d, color e) { //without label text
    x = a;
    y = b;
    width = c;
    height = d;
    primaryColor = e;
    backupColor = e;
    labelAvailable = false;
  }

  //---------------------------------//

  public void display() {
    fill(primaryColor);
    rect(x, y, width, height);

    if(labelAvailable) { //only if label is available
      fill(linkedLabel.primaryColor);
      textFont(linkedLabel.labelFont, linkedLabel.fontSize);
      //the following will place the text at the center of the button regardless of the text's length
      //the logic is to set half of the (box length - text length) as margins are both sides of the text
      text(linkedLabel.labelName, (((width - textWidth(linkedLabel.labelName))/2) + x), (((height - linkedLabel.fontSize)/2) + (y+11)));
    }
  }

  //---------------------------------//

  public void setBoxColor (color a) {
    primaryColor = a;
  }

  //---------------------------------//

  public void setPosition (int a, int b) {
    x = a;
    y = b;
  }

  //---------------------------------//

  public void setLabel (String a) {
    if(labelAvailable) {
      linkedLabel.labelName = a;
    }
  }

  //---------------------------------//

  public void reset() {
    primaryColor = backupColor;
  }
} //labelBox class ends

//=========================================================================//

public class childBox {
  int boxWidth, boxHeight, boxX, boxY, headerHeight, titleX, titleY, titleFontSize;
  color boxColor, headerColor, titleColor;
  PFont titleFont;
  String titleName;

  //x, y, width, height, headerHeight, titleName, titleX, titleY, titleFont, titleFontSize, boxColor, headerColor, titleColor
  childBox (int a, int b, int c, int d, int e, String f, int g, int h, PFont i, int j, color k, color l, color m) {
    boxX = a;
    boxY = b;
    boxWidth = c;
    boxHeight = d;
    headerHeight = e;
    titleName = f;
    titleX = g;
    titleY = h;
    titleFont = i;
    titleFontSize = j;
    boxColor = k;
    headerColor = l;
    titleColor = m;
  }

  void display () {
    fill(headerColor);
    rect(boxX, boxY, boxWidth, headerHeight);
    fill(titleColor);
    textFont(titleFont, titleFontSize);
    text(titleName, boxX + titleX, boxY + titleY);
    fill(boxColor);
    rect(boxX, boxY + headerHeight, boxWidth, boxHeight - headerHeight);
  }

  void setTitle (String a) {
    titleName = a;
  }

  void setBoxColor (color a) {
    boxColor = a;
  }

  void setHeaderColor (color a) {
    headerColor = a;
  }
}

//class definitons end
//=========================================================================//

int COORD_TYPE_NONE = 0; //coordinate type identifiers for serial communication
int COORD_TYPE_START = 1;
int COORD_TYPE_END = 2;
int COORD_TYPE_DOWN = 3;

int SERIAL_WAIT_DELAY = 200;
char DELIMITER = ';'; //delimiter

String VERSION_NUMBER = "1.1.6";
String RELEASE_DATE = "IST 12:00:56 PM, 29-06-2017, Thursday";
String AUTHOR = "Vishnu M Aiea";
String SOURCE_WEBSITE = "https://github.com/vishnumaiea/Mini-CNC-Plotter";
String AUTHOR_WEBSITE = "www.vishnumaiea.in";

String ALIGN_CENTER = "CENTER";
String ALIGN_RIGHT = "RIGHT";
String ALIGN_LEFT = "LEFT";
String ALIGN_TOP = "TOP";
String ALIGN_BOTTOM = "BOTTOM";

//list of human readable error status
String [] serialStatusList = {"Error : Could not find the port specified !",
                             "Error : Device disconnected !",
                             "Serial ended !",
                             "No ports available !"};

int serialStatus = -1; //used as index to select from serialStatusList

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

int lineCount = 0; //number of lines in the image. Used for Lines drawing
int pointCount = 0; //number of pixels or points in an image. Used for Points drawing
int segmentCount = 0; //number of discrete lines in the image. Used for Freehand drawing
int currentSegment = 0; //current line, point or lines segment being plotted
int commandRetryCount = 0; //retry count for failing initialization requests
int coordinateType = 1; //identifies the type of coordinates

int pixelLocation = 0; //pixel location or index in the image file array
int pixelRed; //red value of a pixel
int pixelGreen; //green value of a pixel
int pixelBlue; //blue value of a pixel

boolean pixelIsBlack = false; //stores color of a pixel as bool. true = black, false = white or transparent
boolean prevPixelColor = true; //same as pixelColor
PImage imageSelected; //selected image object
String imageFilePath;

int lineCountLimit = 2000; //limit for lines coordinates for Lines method
int [][][] lineCords = new int [2] [2] [lineCountLimit];

boolean isMainWindowStarted = false;
boolean isInitialWindowStarted = false;
boolean startMonitorSerial = false;
boolean startMainWindow = false;
boolean portSelectError;
boolean waitingForResponse = false;

boolean isImageLoaded = false;
boolean isImageSelected = false;
boolean isFilePromptOpen = false;
boolean isPlottingStarted = false;
boolean isPlotterActive = false;
boolean ifPlotterReady = false;
boolean isPlottingFinished = false;
boolean isPlotterWaiting = false;

boolean ifCalibratePlotter = false;
boolean ifStartPlotter = false;
boolean ifPausePlotter = false;
boolean ifResumePlotter = false;
boolean ifStopPlotter = false;

boolean isUpPressed = false;
boolean isDownPressed = false;
boolean isleftPressed = false;
boolean isRightPressed = false;
boolean isPenDown = false;
boolean ifLines = false;
boolean ifPoints = false;
boolean ifFreehand = false;
boolean ifToMirror = false;

int selectPortValue = -1; //virtual com port value
int portCount = 0; //number of COM ports available
int prevPortCount = 0;
int portIndexLimit = -1; //index limit for port list
int activePortValue = -1;
int tempInt; //int variable for testing
int comStatusCounter; //to check is the OBU is on and transmitting

boolean startPressed = false; //for start button
boolean quitPressed = false; //for quit button
boolean aboutPressed = false;
boolean serialSuccess = false; //check if com port opening was successful
boolean isPortError = false; //port error status
boolean serialDisconnected = false;

String selectPortName = "NONE"; //name of port selected
String activePortName = "NONE";

color colorWhite = #FFFFFF;
color colorBlue = #006699;
color colorRed = #c55757;
color colorGreen = #47B938;
color colorOrange = #F07A3F;
color colorLightGrey = 220;
color colorMediumGrey = 200;
color colorDarkGrey = 170;
color colorBlack = #000000;
color colorMediumBlack = 80;
color colorTextField = 240;
color colorDefaultButton = 235;

//font vars
PFont robotoFont, poppinsFont, segoeFont, h4Font, h5Font, h6Font, fontAwesome;

//UI buttons
uiButton startMainButton, quitAppButton, startAboutButton, portDecButton, portIncButton, quitMainButton;
uiButton plotterUpButton, plotterDownButton, plotterLeftButton, plotterRightButton, plotterPenButton;
uiButton plotterHomeButton;
uiButton loadImageButton, linesButton, pointsButton, freehandButton;
uiButton plotterStartButton, plotterPauseButton, plotterStopButton, plotterCalibrateButton;
uiButton backButton;

//labels for UI buttons
uiButtonLabel plotterStartButtonLabel, plotterPauseButtonLabel, plotterResumeButtonLabel, plotterStopButtonLabel, plotterCalibrateButtonLabel;
uiButtonLabel plotterUpArrow, plotterDownArrow, plotterLeftArrow, plotterRightArrow, plotterPenArrow, plotterPenCircle;
uiButtonLabel plotterStartIcon, plotterPauseIcon, plotterResumeIcon, plotterStopIcon;
uiButtonLabel startMainButtonLabel, quitAppButtonLabel, aboutButtonLabel;
uiButtonLabel loadImageButtonLabel, linesButtonLabel, pointsButtonLabel, freehandButtonLabel;
uiButtonLabel portDecButtonLabel, portIncButtonLabel, quitMainButtonLabel;
uiButtonLabel backButtonLabel;

//text labels and boxes
textLabel fileName, portNameLabel, currentTask, currentSerialComStatus, currentPlotterStatus, currentPlotterPosition;
labelBox fileNameBox, portNameBox, serialComStatusBox, plotterStatusBox, plotterPositionBox, currentTaskBox;

//=========================================================================//

void setup() {
  size(800, 655);
  background(colorDarkGrey);

  surface.setTitle("Mini CNC Plotter - Vishnu M Aiea");

  poppinsFont = createFont("poppins-medium.ttf", 20); //load ttf fonts from "data" folder
  segoeFont = createFont("seguisb.ttf", 20);
  fontAwesome = createFont("fontawesome-webfont.ttf", 20);

  imageHeight = 327;
  imageWidth = 250;

  //instantiating labels
  //name, X, Y, font, fontSize, labelColor, hoverColor, pressedColor, activeColor, button

  backButtonLabel = new uiButtonLabel ("BACK", 23, 23, segoeFont, 14, colorBlue, colorWhite, colorOrange, colorBlue);

  plotterUpArrow = new uiButtonLabel ("",8, 40, fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange, colorOrange);
  plotterDownArrow = new uiButtonLabel ("", 8, 40, fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange, colorOrange);
  plotterLeftArrow = new uiButtonLabel ("", 8, 40, fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange, colorOrange);
  plotterRightArrow = new uiButtonLabel ("",8, 40, fontAwesome, 40, colorMediumGrey, colorBlue, colorOrange, colorOrange);
  plotterPenArrow = new uiButtonLabel ("", 18, 35, fontAwesome, 27, colorWhite, colorBlue, colorOrange, colorOrange);
  plotterPenCircle = new uiButtonLabel ("", 8, 40, fontAwesome, 42, colorMediumGrey, colorBlue, colorOrange, colorOrange);

  plotterStartIcon = new uiButtonLabel ("", 15, 22, fontAwesome, 16, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  plotterPauseIcon = new uiButtonLabel ("", 15, 22, fontAwesome, 16, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  plotterResumeIcon = new uiButtonLabel ("", 15, 22, fontAwesome, 16, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  plotterStopIcon = new uiButtonLabel ("", 15, 22, fontAwesome, 16, colorMediumBlack, colorWhite, colorOrange, colorWhite);

  startMainButtonLabel = new uiButtonLabel ("START", 20, 23, segoeFont, 14, colorBlue, colorWhite, colorOrange, colorBlue);
  quitAppButtonLabel = new uiButtonLabel ("QUIT", 22, 23, segoeFont, 14, colorBlue, colorWhite, colorOrange, colorBlue);
  aboutButtonLabel = new uiButtonLabel ("ABOUT", 18, 23, segoeFont, 14, colorBlue, colorWhite, colorOrange, colorBlue);

  loadImageButtonLabel = new uiButtonLabel ("Load Image", 16, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  linesButtonLabel = new uiButtonLabel ("Lines", 36, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  pointsButtonLabel = new uiButtonLabel ("Points", 32, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  freehandButtonLabel = new uiButtonLabel ("Freehand", 24, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);

  quitMainButtonLabel = new uiButtonLabel ("", 3, 21, fontAwesome, 24, 200, colorBlue, colorOrange, colorWhite);

  plotterStartButtonLabel = new uiButtonLabel ("START", 52, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  plotterPauseButtonLabel = new uiButtonLabel ("PAUSE", 52, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  plotterResumeButtonLabel = new uiButtonLabel ("RESUME", 52, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  plotterStopButtonLabel = new uiButtonLabel ("STOP", 52, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);
  plotterCalibrateButtonLabel = new uiButtonLabel ("CALIBRATE", 25, 20, segoeFont, boxTitleFontSize, colorMediumBlack, colorWhite, colorOrange, colorWhite);

  portDecButtonLabel = new uiButtonLabel ("", 8, 30, fontAwesome, 27, colorWhite, colorWhite, colorOrange, colorWhite);
  portIncButtonLabel = new uiButtonLabel ("", 12, 30, fontAwesome, 27, colorWhite, colorWhite, colorOrange, colorWhite);


  //instantiating buttons
  //(X, Y, W, H, Label, buttonColor, buttonHoverColor, buttonLabelColor, buttonLabelHoverColor
  backButton = new uiButton (360, 530, 80, 35, colorWhite, colorBlue, colorBlue, colorWhite);

  startMainButton = new uiButton (220, 480, 80, 35, colorWhite, colorBlue, colorBlue, colorWhite);
  quitAppButton = new uiButton (360, 480, 80, 35, colorWhite, colorBlue, colorBlue, colorWhite);
  startAboutButton = new uiButton (500, 480, 80, 35, colorWhite, colorBlue, colorBlue, colorWhite);
  portDecButton = new uiButton (330, 270, 30, 40, colorWhite, colorBlue, colorBlue, colorWhite);
  portIncButton = new uiButton (430, 270, 30, 40, colorWhite, colorBlue, colorBlue, colorWhite);
  quitMainButton = new uiButton (748, 25, 25, 25, #018ec6, 240, 200, colorBlue);

  plotterUpButton = new uiButton (105, 455, 50, 50, colorDefaultButton, colorBlue, 50, 250);
  plotterDownButton = new uiButton (105, 555, 50, 50, colorDefaultButton, colorBlue, 50, 250);
  plotterLeftButton = new uiButton (55, 505, 50, 50, colorDefaultButton, colorBlue, 50, 250);
  plotterRightButton = new uiButton (155, 505, 50, 50, colorDefaultButton, colorBlue, 50, 250);
  plotterPenButton = new uiButton (105, 505, 50, 50, colorDefaultButton, colorBlue, 50, 250);

  loadImageButton = new uiButton (48, 182, 100, 30, colorDefaultButton, colorBlue, colorOrange, colorOrange);
  linesButton = new uiButton (48, 232, 100, 30, colorDefaultButton, colorBlue, colorOrange, colorBlue);
  pointsButton = new uiButton (48, 282, 100, 30, colorDefaultButton, colorBlue, colorOrange, colorBlue);
  freehandButton = new uiButton (48, 332, 100, 30, colorDefaultButton, colorBlue, colorOrange, colorBlue);

  plotterStartButton = new uiButton (265, 445, 115, 30, colorDefaultButton, colorBlue, colorOrange, colorWhite);
  plotterPauseButton = new uiButton (265, 490, 115, 30, colorDefaultButton, colorBlue, colorOrange, colorWhite);
  plotterStopButton = new uiButton (265, 535, 115, 30, colorDefaultButton, colorBlue, colorOrange, colorWhite);
  plotterCalibrateButton = new uiButton (265, 580, 115, 30, colorDefaultButton, colorBlue, colorOrange, colorWhite);

  portDecButton = new uiButton (330, 270, 30, 40, colorBlue, colorBlue, colorOrange, colorBlue);
  portIncButton = new uiButton (430, 270, 30, 40, colorBlue, colorBlue, colorOrange, colorBlue);


  //link the button labels to the buttons

  backButton.linkLabel(backButtonLabel);

  startMainButton.linkLabel(startMainButtonLabel);
  quitAppButton.linkLabel(quitAppButtonLabel);
  startAboutButton.linkLabel(aboutButtonLabel);
  portDecButton.linkLabel(portDecButtonLabel);
  portIncButton.linkLabel(portIncButtonLabel);
  quitMainButton.linkLabel(quitMainButtonLabel);

  plotterUpButton.linkLabel(plotterUpArrow);
  plotterDownButton.linkLabel(plotterDownArrow);
  plotterLeftButton.linkLabel(plotterLeftArrow);
  plotterRightButton.linkLabel(plotterRightArrow);
  plotterPenButton.linkLabel(plotterPenCircle);

  loadImageButton.linkLabel(loadImageButtonLabel);
  linesButton.linkLabel(linesButtonLabel);
  pointsButton.linkLabel(pointsButtonLabel);
  freehandButton.linkLabel(freehandButtonLabel);

  plotterStartButton.linkLabel(plotterStartButtonLabel);
  plotterPauseButton.linkLabel(plotterPauseButtonLabel);
  plotterStopButton.linkLabel(plotterStopButtonLabel);
  plotterCalibrateButton.linkLabel(plotterCalibrateButtonLabel);

  //---------------------------------------------------------------//

  //link the buttons to the labels

  backButtonLabel.linkButton(backButton);

  plotterStartButtonLabel.linkButton(plotterStartButton);
  plotterPauseButtonLabel.linkButton(plotterPauseButton);
  plotterStopButtonLabel.linkButton(plotterStopButton);
  plotterCalibrateButtonLabel.linkButton(plotterCalibrateButton);

  plotterUpArrow.linkButton(plotterUpButton);
  plotterDownArrow.linkButton(plotterDownButton);
  plotterLeftArrow.linkButton(plotterLeftButton);
  plotterRightArrow.linkButton(plotterRightButton);
  plotterPenArrow.linkButton(plotterPenButton);
  plotterPenCircle.linkButton(plotterPenButton);

  plotterStartIcon.linkButton(plotterStartButton);
  plotterPauseIcon.linkButton(plotterPauseButton);
  plotterResumeIcon.linkButton(plotterPauseButton);
  plotterStopIcon.linkButton(plotterStopButton);

  startMainButtonLabel.linkButton(startMainButton);
  quitAppButtonLabel.linkButton(quitAppButton);
  aboutButtonLabel.linkButton(startAboutButton);

  loadImageButtonLabel.linkButton(loadImageButton);
  linesButtonLabel.linkButton(linesButton);
  pointsButtonLabel.linkButton(pointsButton);
  freehandButtonLabel.linkButton(freehandButton);

  portDecButtonLabel.linkButton(portDecButton);
  portIncButtonLabel.linkButton(portIncButton);
  quitMainButtonLabel.linkButton(quitMainButton);

  //normal standalone text labels
  //name, x, y, font, fontSize, color
  fileName = new textLabel ("None", 125, 152, segoeFont, boxTitleFontSize, colorMediumBlack);
  portNameLabel = new textLabel ("NONE",infoBoxX+290, infoBoxY+75, segoeFont, boxTitleFontSize, colorMediumBlack);
  currentTask = new textLabel ("0/0", 320, 355, segoeFont, boxTitleFontSize, colorMediumBlack);
  currentSerialComStatus = new textLabel ("Connected", 300, 234, segoeFont, boxTitleFontSize, colorMediumBlack);
  currentPlotterStatus = new textLabel ("Idle", 310, 275, segoeFont, boxTitleFontSize, colorMediumBlack);
  currentPlotterPosition = new textLabel ("0, 0, 0", 310, 314, segoeFont, boxTitleFontSize, colorMediumBlack);

  //x, y, width, height, color, textLabel
  fileNameBox = new labelBox (infoBoxX+85, infoBoxY+14, 280, boxTitleHeight, colorTextField, fileName);
  portNameBox = new labelBox (infoBoxX+254, infoBoxY+57, 110, boxTitleHeight, colorTextField, portNameLabel);
  serialComStatusBox = new labelBox (infoBoxX+254, infoBoxY+97, 110, boxTitleHeight, colorTextField, currentSerialComStatus);
  plotterStatusBox = new labelBox (infoBoxX+254, infoBoxY+137, 110, boxTitleHeight, colorTextField, currentPlotterStatus);
  plotterPositionBox = new labelBox (infoBoxX+254, infoBoxY+177, 110, boxTitleHeight, colorTextField, currentPlotterPosition);
  currentTaskBox = new labelBox (infoBoxX+254, infoBoxY+217, 110, boxTitleHeight, colorTextField, currentTask);
}

//=========================================================================//

void draw() {
  if ((!startPressed) && (!aboutPressed)) {
    displayInitialWindow();
  }

  if (startPressed) {
    displayMainWindow();
  }

  if (aboutPressed) {
    displayAboutWindow();
  }
}

//=========================================================================//

void displayInitialWindow() {
  displayInitialStaticInfo();

  if (isPortError) { //check wether a port error occurred in main window
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

  else if (serialStatus == 2){ //serial ended by user
    textFont(segoeFont, 15);
    fill(colorRed);
    text(serialStatusList[serialStatus], 350, 410);
  }

  else if (serialStatus == 3) { //no ports available
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

    if (portDecButton.isClicked()) {
      if (selectPortValue > 0) {
        selectPortValue--;
        selectPortName = Serial.list()[selectPortValue];
        printVerbose("Port Decrement");
      }
    } else {
      selectPortName = Serial.list()[selectPortValue];
    }

    if (portIncButton.isClicked()) {
      if ((selectPortValue < (Serial.list().length -1 )) && (selectPortValue > -1)) {
        selectPortValue++;
        selectPortName = Serial.list()[selectPortValue];
        printVerbose("Port Increment");
      }
    } else {
      selectPortName = Serial.list()[selectPortValue];
    }

    //---------------------------------------------------//

    // Apply the click effect only if conditions are met

    if (selectPortValue >= portIndexLimit) {
      portDecButton.isPressed();
    }

    else if (selectPortValue < portIndexLimit) {
      portIncButton.isPressed();
    }

    //---------------------------------------------------//

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

  else if (portCount >0) {

    if (serialStatus == 3) {
      serialStatus = -1;
    }
  }
}

//=========================================================================//
//displays static titles and stuff

void displayInitialStaticInfo () {
  smooth();
  noStroke();
  background(colorDarkGrey);
  fill(colorLightGrey);
  rect(125, 450, 550, 95); //third box in starting window

  startMainButton.display();
  startAboutButton.display();
  quitAppButton.display();

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
  text(VERSION_NUMBER, 405, 170);

  textFont(poppinsFont, 12);
  fill(colorMediumGrey);
  text("© 2017  Vishnu M Aiea", 332, 195);

  fill(colorBlue);
  textFont(segoeFont, 15);
  text("Connect the Plotter and select the COM port", 246, 375);

  rect(330, 270, 130, 40); //COM port selection
  fill(colorWhite);
  rect(360, 272, 70, 36); //small rect for port value

  portDecButton.display();
  portIncButton.display();
}

//=========================================================================//
//gets the number of currenlty available serial COM ports

void getSerialPortInfo() {
  portCount = Serial.list().length;
  portIndexLimit = portCount - 1;
}

//=========================================================================//
//prints all the variables to the console

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

//=========================================================================//
//shows the about, credits, getting started tutorial etc

void displayAboutWindow() {
  if(aboutPressed) {
    smooth();
    noStroke();
    background(colorDarkGrey);

    displayRect(125, 50, 550, 120, colorBlue); //first box in initial window
    displayRect(125, 170, 550, 340, colorWhite); //second box in initial window
    displayRect(125, 510, 550, 75, colorLightGrey); //second box in initial window

    setTextProperties(poppinsFont, 26);
    displayText("MINI CNC PLOTTER", colorWhite, 283, 95);
    setTextProperties(poppinsFont, 12);
    displayText("Version", colorMediumGrey, 355, 125);
    displayText(VERSION_NUMBER, colorMediumGrey, 405, 125);
    displayText("© 2017  Vishnu M Aiea", colorMediumGrey, 332, 150);

    setTextProperties(poppinsFont, 13);
    displayText("This is a control software designed for drawing graphics with", colorMediumBlack, ALIGN_CENTER, 120, 125, 100, 550);
    displayText("CNC plotters made from CD stepper drives.", colorMediumBlack, ALIGN_CENTER, 145, 125, 100, 550);
    displayText("The software is developed with ", "Processing.", colorMediumBlack, colorBlue, ALIGN_CENTER, 170, 125, 100, 550);
    displayText("Full tutorial is available at author's website.", colorMediumBlack, ALIGN_CENTER, 195, 125, 100, 550);
    setTextProperties(poppinsFont, 13);
    displayText("Version : ", VERSION_NUMBER, colorMediumBlack, colorBlue, ALIGN_CENTER, 247, 125, 100, 550);
    displayText("Developed by  ", "Vishnu M Aiea", colorMediumBlack, colorBlue, ALIGN_CENTER, 272, 125, 100, 550);
    displayText("License : ", "MIT License, Copyright © 2017  Vishnu M Aiea", colorMediumBlack, colorBlue, ALIGN_CENTER, 297, 125, 100, 550);
    displayText("Release date : ", RELEASE_DATE, colorMediumBlack, colorBlue, ALIGN_CENTER, 322, 125, 100, 550);
    displayText("GitHub : ", SOURCE_WEBSITE, colorMediumBlack, colorBlue, ALIGN_CENTER, 347, 125, 100, 550);
    displayText("Author's Website : ", AUTHOR_WEBSITE, colorMediumBlack, colorBlue, ALIGN_CENTER, 372, 125, 100, 550);

    backButton.display();
    if (backButton.isClicked())
    aboutPressed = false;
  }
}

//=========================================================================//

void displayRect (int x, int y, int w, int h, color c) {
  fill(c);
  rect(x, y, w, h);
}

//=========================================================================//

void displayRect (int x, int y,int w, int h, color c, String align, int parentWidth, int parentHeight) {
  fill(c);
  if(align.equals(ALIGN_CENTER))
  rect((((parentWidth-w)/2)+x), (((parentHeight-h)/2)+y), w, h);
}

//=========================================================================//

void displayRect (int x, int y,int w, int h, color c, String align, int parentWidth) {
  fill(c);
  if(align.equals(ALIGN_CENTER))
  rect((((parentWidth-w)/2)+x), y, w, h);
}

//=========================================================================//

void setTextProperties (PFont font, int fontSize) {
  textFont(font, fontSize);
}

//=========================================================================//

void displayText (String a, color b, int x, int y) {
  fill(b);
  text(a, x, y);
}

//=========================================================================//

void displayText (String a, color b, int x, int y, int parentX, int parentY) {
  fill(b);
  text(a, parentX+x, parentY+y);
}

//=========================================================================//

void displayText (String a, color b, String align,int y, int parentX, int parentY, int parentWidth) {
  fill(b);
  if(align.equals(ALIGN_CENTER))
  text(a, (((parentWidth - textWidth(a))/2) + parentX), (y+parentY));
}

//=========================================================================//

void displayText (String a, String b, color c, color d, String align, int y, int parentX, int parentY, int parentWidth) {
  String combinedString = a + b;
  int firstStringWidth = (int) textWidth(a);
  int secondStringWidth = (int) textWidth(b);
  int combinedStringWidth = (int) textWidth(combinedString);

  fill(c);
  if(align.equals(ALIGN_CENTER))
  text(a, (((parentWidth - combinedStringWidth)/2) + parentX), (y+parentY));
  fill(d);
  text(b, (((parentWidth - combinedStringWidth)/2) + firstStringWidth + parentX), (y+parentY));
}

//=========================================================================//

void displayMainWindow() {

  //------------------------------------------//

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

  //------------------------------------------//

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

  //------------------------------------------//

  if ((serialSuccess) && (!isPortActive(activePortName))) {
    resetAll("PORT ERROR");
    printVerbose("Active Port Error");
  }

  //-------------------------------------------//

  if ((startMainWindow) && (!isPortError) && (isPortActive(activePortName))) {

    //-------------- Main Window Contents Start Here -------------//

    smooth();
    noStroke();
    background(colorMediumGrey);

    //----------- Static Title -------------------------//

    displayRect(0, 0, 800, 600, colorBlue);
    setTextProperties(poppinsFont, 25);
    displayText("MINI CNC PLOTTER", colorWhite, 280, 37);
    setTextProperties(poppinsFont, 12);
    displayText("Version", colorMediumGrey, 345, 62);
    displayText(VERSION_NUMBER, colorMediumGrey, 395, 62);

    //----------- Static Title Ends --------------------//


    //----------------- Boxes -------------------------//

    fill(colorWhite);
    rect(imageBoxX, imageBoxY, imageBoxWidth, imageBoxHeight);

    if (isImageLoaded) {
      image(imageSelected, (imageBoxX+5), (imageBoxY+5));
    }
    else {
      fill(colorMediumBlack);
      textFont(segoeFont, 13);
      text("No Image Selected", 550, 250);
    }

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

    //----------------- Boxes Ends -------------------------//


    //----------------- Box Contents -----------------------//

    textFont (segoeFont, boxTitleFontSize);
    fill (colorMediumBlack);
    text ("Filename", infoBoxX+20, infoBoxY+32);

    loadImageButton.display();
    linesButton.display();
    pointsButton.display();
    freehandButton.display();

    loadImageButton.isHover();
    linesButton.isHover();
    pointsButton.isHover();
    freehandButton.isHover();


    //--------- Image Selection -----------------------------//

    if ((loadImageButton.isClicked()) && (!isFilePromptOpen)) { //if button clicked and prompt is not already open
      if (!isImageLoaded) {
        isFilePromptOpen = true; //file prompt is now open
        selectInput("Select a PNG file :", "selectImageFile"); //the 2nd parameter is actually a function
      }
    }

    if ((isImageSelected) && (!isImageLoaded)) {
      imageSelected = loadImage(imageFilePath, "png");

      if (imageSelected == null) {
        imageSelected = null;
        isImageLoaded = false;
        isImageSelected = false;
        imageFilePath = null;
        isFilePromptOpen = false;
        fileName.reset();
        fileName.labelName = "None";
      }

      if ((imageSelected.width == -1) || (imageSelected.height == -1)) { //chedck if image is valid
        println("Incompatible file was selected.");
        fileName.setColor(colorRed);
        fileName.labelName = "Invalid File";

        isImageLoaded = false; //reset everything if not valid
        isImageSelected = false;
        imageHeight = -1;
        imageWidth = -1;
        imageFilePath = null;
        isFilePromptOpen = false;
        imageSelected = null;
      }

      else { //proceed if valid
        isImageLoaded = true;
        imageHeight = imageSelected.height;
        imageWidth = imageSelected.width;

        isFilePromptOpen = false;
        ifLines = true;
        ifPoints = false;
        ifFreehand = false;
        fileName.reset();
        fileName.labelName = getFileName(imageFilePath);
        println("Image loaded");
        countLines();
        currentTask.setLabel("0/" + lineCount);
      }
    }

    fileNameBox.display();
    loadImageButton.isPressed();

    //--------------Image Selection Ends ----------------------//


    //-------------- Plotting Type Selection ------------------//

    linesButton.display();
    pointsButton.display();
    freehandButton.display();

    if ((linesButton.isClicked()) || (ifLines)) {
      linesButton.setColor(colorBlue);
      linesButtonLabel.setColor(colorWhite);

      pointsButton.reset();
      pointsButtonLabel.reset();
      freehandButton.reset();
      freehandButtonLabel.reset();

      if ((!isPlottingStarted) && (!ifLines)) {
        ifLines = true;
        ifPoints = false;
        ifFreehand = false;
        println("Lines Selected");
      }
    }

    if ((pointsButton.isClicked()) || (ifPoints)) {
      pointsButton.setColor(colorBlue);
      pointsButtonLabel.setColor(colorWhite);

      linesButton.reset();
      linesButtonLabel.reset();
      freehandButton.reset();
      freehandButtonLabel.reset();

      if ((!isPlottingStarted) && (!ifPoints)) {
        ifLines = false;
        ifPoints = true;
        ifFreehand = false;
        println("Points Selected");
      }
    }

    if ((freehandButton.isClicked()) || (ifFreehand)) {
      freehandButton.setColor(colorBlue);
      freehandButtonLabel.setColor(colorWhite);

      linesButton.reset();
      linesButtonLabel.reset();
      pointsButton.reset();
      pointsButtonLabel.reset();

      if ((!isPlottingStarted) && (!ifFreehand)) {
        ifLines = false;
        ifPoints = false;
        ifFreehand = true;
        println("Freehand Selected");
      }
    }

    linesButton.isPressed();
    pointsButton.isPressed();
    freehandButton.isPressed();

    //-------------- Plotting Type Selection Ends ------------------//


    //-------------- Info Fields ------------------//

    fill (colorMediumBlack);
    text ("Port", infoBoxX+160, infoBoxY+75);
    text ("Serial Status", infoBoxX+160, infoBoxY+115);
    text ("Plotter Status", infoBoxX+160, infoBoxY+155);
    text ("Position", infoBoxX+160, infoBoxY+195);
    text ("Current Task", infoBoxX+160, infoBoxY+235);

    portNameBox.display();
    serialComStatusBox.display();
    plotterStatusBox.display();
    plotterPositionBox.display();
    currentTaskBox.display();

    //-------------- Info Fields Ends ------------------//


    //----------- Movement Control Buttons -----------------------//

    //--------------------------------//
    plotterUpArrow.displayLabel();

    if (plotterUpButton.isPressed()){
      plotterUpArrow.labelColor = colorOrange;
    }
    //-------------------------------//

    plotterLeftArrow.displayLabel();
    if (plotterLeftButton.isPressed()){
      plotterLeftArrow.labelColor = colorOrange;
    }
    //-------------------------------//

    plotterPenCircle.displayLabel();
    plotterPenArrow.displayLabel();

    if (plotterPenButton.isPressed()){
      plotterPenCircle.labelColor = colorOrange;
    }
    //------------------------------//

    plotterRightArrow.displayLabel();

    if (plotterRightButton.isPressed()){
      plotterRightArrow.labelColor = colorOrange;
    }
    //------------------------------//

    plotterDownArrow.displayLabel();

    if (plotterDownButton.isPressed()){
      plotterDownArrow.labelColor = colorOrange;
    }
    //------------------------------//

    //----------- Movement Control Buttons Ends-----------------------//


    //----------- Control Buttons ---------------------//

    plotterStartButton.display();
    plotterPauseButton.display();
    plotterStopButton.display();
    plotterCalibrateButton.display();

    plotterStartButton.isHover();
    plotterPauseButton.isHover();
    plotterStopButton.isHover();
    plotterCalibrateButton.isHover();

    if (((plotterStartButton.isClicked()) && (isImageLoaded)) || ifCalibratePlotter) {

      ifStartPlotter = true;
      ifStopPlotter = false;

      plotterStartButton.setColor(colorGreen);
      plotterStartButton.setLabelColor(colorWhite);

      plotterStopButton.setColor(colorRed);
      plotterStopButton.setLabelColor(colorWhite);

      plotterStopIcon.setColor(colorWhite);
      plotterStartIcon.setColor(colorWhite);
    }

    if ((plotterStopButton.isClicked()) && (ifStartPlotter)) {
      ifPlotterReady = false;
      isPlottingFinished = true;
      isPlottingStarted = false;
      isPlotterActive = false;
      commandRetryCount = 0;
      currentSegment = 0;
      waitingForResponse = false;
      coordinateType = 0;
      isPenDown = false;

      ifStartPlotter = false;
      ifStopPlotter = true;
      ifPausePlotter = false;
      ifCalibratePlotter = false;

      plotterStopButton.reset();
      plotterStopButtonLabel.reset();
      plotterStartButton.reset();
      plotterStartButtonLabel.reset();
      plotterCalibrateButton.reset();

      plotterStartIcon.reset();
      plotterStopIcon.reset();
    }

    if ((plotterPauseButton.isClicked()) && (ifStartPlotter)) {
      ifPausePlotter = (ifPausePlotter ? false: true);
      //isPlotterWaiting = (isPlotterWaiting ? false: true);
    }

    if ((plotterCalibrateButton.isClicked()) && (!ifStartPlotter)) {
      ifCalibratePlotter = true;
    }

    if (!ifPausePlotter) {
      plotterPauseButton.isHover();
      plotterPauseButton.isPressed();

      plotterPauseButton.reset();
      plotterPauseButtonLabel.reset();
      plotterPauseButton.setLabel("PAUSE");
      plotterPauseIcon.display();
    }

    if (ifPausePlotter) {
      plotterPauseButton.setLabel("RESUME");
      plotterPauseButton.setColor(colorBlue);
      plotterPauseButton.setLabelColor(colorWhite);

      plotterResumeIcon.setColor(colorWhite);
      plotterResumeIcon.display();
    }

    plotterStartIcon.display();
    plotterStopIcon.display();

    plotterStartButton.isPressed();
    plotterStopButton.isPressed();
    plotterCalibrateButton.isPressed();
    plotterPauseButton.isPressed();

    //------------ Control Buttons Ends ---------------//

    //----------------- Box Contents Ends -----------------------//


    //------------- Quit Button -----------------------//

    quitMainButton.display();

    if (quitMainButton.isClicked()) {
      resetAll("QUIT"); //reset everything for quitting main window
      printVerbose("Connection ended by user.");

      if (serialPort.active()) {
        serialPort.stop();
      }
    }

    //----------------Quit Button Ends -----------------//

    if ((serialPort.active()) && (activePortName != "NONE")) {
      portNameBox.setLabel(activePortName);
    }

    else {
      portNameBox.setLabel("NONE");
    }

    //------------ Serial Comm Starts --------------//

    if ((isImageLoaded) && (ifLines)) {
      if ((ifStartPlotter) && (!ifPausePlotter)) {
        if ((lineCount != 0) && (currentSegment <= 0) && (!isPlotterActive)){
          countLines();
          thread("plotImage");
        }
      }
    }

    //------------ Serial Comm Ends --------------//

    //--------------- Main Window Contents End Here ---------------//
  }
}

//=========================================================================//
//reset everything

boolean resetAll() {
  startPressed = false;
  isPortError = false;
  serialSuccess = false;
  startMainWindow = false;

  activePortName = "NONE";
  activePortValue = -1;
  selectPortName = "NONE";
  selectPortValue = -1;
  serialStatus = -1;
  currentSerialComStatus.setLabel("Disconnected");
  currentTask.setLabel("0/0");
  currentPlotterStatus.setLabel("Idle");
  currentPlotterPosition.setLabel("0, 0, 0");

  isImageLoaded = false;
  isImageSelected = false;
  imageFilePath = null;
  isFilePromptOpen = false;
  fileName.labelName = "None";
  fileName.reset();

  lineCount = 0;
  ifPlotterReady = false;
  isPlottingFinished = true;
  isPlottingStarted = false;
  isPlotterActive = false;
  isPlotterWaiting = false;
  commandRetryCount = 0;
  currentSegment = 0;
  waitingForResponse = false;
  coordinateType = 0;
  isPenDown = false;

  ifStartPlotter = false;
  ifPausePlotter = false;
  ifStopPlotter = true;

  plotterStopButton.reset();
  plotterStopButtonLabel.reset();
  plotterStartButton.reset();
  plotterStartButtonLabel.reset();
  plotterCalibrateButton.reset();

  plotterPauseButton.reset();
  plotterPauseButtonLabel.reset();
  plotterPauseButton.setLabel("PAUSE");
  plotterPauseIcon.display();

  plotterStartIcon.reset();
  plotterStopIcon.reset();

  return true;
}

//=========================================================================//

boolean resetPlotter () {
  ifPlotterReady = false;
  isPlottingFinished = true;
  isPlottingStarted = false;
  isPlotterActive = false;
  isPlotterWaiting = false;
  commandRetryCount = 0;
  currentSegment = 0;
  waitingForResponse = false;
  coordinateType = 0;
  isPenDown = false;

  ifStartPlotter = false;
  ifPausePlotter = false;
  ifStopPlotter = true;

  currentPlotterStatus.setLabel("Idle");
  currentPlotterPosition.setLabel("0, 0, 0");

  plotterStopButton.reset();
  plotterStopButtonLabel.reset();
  plotterStartButton.reset();
  plotterStartButtonLabel.reset();
  plotterCalibrateButton.reset();

  plotterPauseButton.reset();
  plotterPauseButtonLabel.reset();
  plotterPauseButton.setLabel("PAUSE");
  plotterPauseIcon.display();

  plotterStartIcon.reset();
  plotterStopIcon.reset();
  return true;
}

//=========================================================================//

boolean resetAll (String method) {
  resetAll(); //reset all flags

  if(method.equals("QUIT"))
  serialStatus = 2;

  if(method.equals("PORT ERROR")) {
    serialStatus = 1;
    isPortError = true;
  }
  return true;
}

//=========================================================================//

//establishes serial comuuncation through the selected COM port

void establishSerial() {
  if (!serialSuccess) {
    getSerialPortInfo();

    if ((portCount> 0) && (selectPortValue > -1) && (selectPortValue < portCount)) {
      printVerbose("establishSerial");
      activePortName = Serial.list()[selectPortValue];
      printVerbose("establishSerial-2");
      serialPort = new Serial(this, activePortName, 9600);
      activePortValue = selectPortValue;
      currentSerialComStatus.setLabel("Connected");
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

//=========================================================================//

//checks if a selected COM port is currently present/active

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

//=========================================================================//

boolean isCurrentPortActive () {
  if(isPortActive(activePortName))
  return true;

  else return false;
}

//=========================================================================//

//opens file selection prompt and let you select a file

void selectImageFile(File selectedPath) {
  if (selectedPath == null) {
    println("Window was closed or the user hit cancel.");
    imageFilePath = null; //reset image parameters
    imageSelected = null;
    isImageLoaded = false;
    isImageSelected = false;
    isFilePromptOpen = false;
  }
  else {
    println("User selected " + selectedPath.getAbsolutePath());
    imageFilePath = selectedPath.getAbsolutePath();
    isImageSelected = true;
  }
}

//=========================================================================//

//gets the filename from the absolute path

String getFileName(String filePath) {
  String [] splittedString = splitTokens(filePath, "\\");
  return splittedString[splittedString.length - 1];
}

//=========================================================================//

//checks if a pixel in the image is black

boolean isPixelBlack(int x, int y) {
  pixelLocation = (x+(y*imageWidth)); //calculate the pixel location in the PImage array from cords
  pixelRed = (int) red(imageSelected.pixels[pixelLocation]); //get red value of pixel
  pixelGreen = (int) green(imageSelected.pixels[pixelLocation]); //get green value of pixel
  pixelBlue = (int) blue(imageSelected.pixels[pixelLocation]); //get blue value of pixel

  if ((pixelRed > 10) && (pixelGreen > 10) && (pixelBlue > 10)) { //check if white
    return false;
  } else if ((pixelRed < 10) && (pixelGreen < 10) && (pixelBlue < 10)) { //check if black
    return true;
  }
  return false; //default return
}

//=========================================================================//

//counts the no. of lines in image and store the start and end coordinates
//of each line to a 3D array with total count of lines ie lineCount.

boolean countLines() {
  if (isImageLoaded) {
    lineCount = 0;
    for (int y=0; y<imageHeight; y++) { //loop until image height or rows
      for (int x=0; x<imageWidth; x++) { //loop until image width or columns
        pixelIsBlack = isPixelBlack(x, y); //get the color of the pixel

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
        }

        if ((pixelIsBlack) && ((x==0) || (!prevPixelColor))) { //if pixel color is black AND (there's no prev pixel OR prev pixel is white)
          if(ifToMirror) {
            lineCords[0][0][lineCount] = x; //x cord of starting of a line
            lineCords[0][1][lineCount] = y; //y cord of starting of a line
          }
          else if(!ifToMirror) {
            lineCords[0][0][lineCount] = (imageWidth - 1) - x; //x cord of starting of a line
            lineCords[0][1][lineCount] = y; //y cord of starting of a line
          }
        }

        if ((!pixelIsBlack) && (prevPixelColor)) { //if pixel color is white AND prev pixel color is black
          if(ifToMirror) {
            lineCords[1][0][lineCount] = x-1; //x cord of ending of a line
            lineCords[1][1][lineCount] = y; //y cord of ending of a line
            lineCount++; // increase z to store the next line's cords
          }
          else if (!ifToMirror) {
            lineCords[1][0][lineCount] = (imageWidth - 1) - (x-1); //x cord of ending of a line
            lineCords[1][1][lineCount] = y; //y cord of ending of a line
            lineCount++; // increase z to store the next line's cords
          }
        }

        if ((pixelIsBlack) && (x==(imageWidth-1))) { //if pixel is black but at the end of any row
          if(ifToMirror) {
            lineCords[1][0][lineCount] = x; //x cord of ending of a line
            lineCords[1][1][lineCount] = y; //y cord of ending of a line
            lineCount++; // increase z to store the next line's cords
          }
          else if(!ifToMirror) {
            lineCords[1][0][lineCount] = (imageWidth - 1) - x; //x cord of ending of a line
            lineCords[1][1][lineCount] = y; //y cord of ending of a line
            lineCount++; // increase z to store the next line's cords
          }
        }
      }
    }
    println();
    print("Total Lines Found : ");
    println(lineCount);
    println();
    return true;
  }

  else {
    lineCount = -1; //default or error response
    return false;
  }
}

//=========================================================================//

void plotImage () {
  if ((ifStartPlotter) && (!ifStopPlotter) && (isCurrentPortActive())) {
    while ((isCurrentPortActive()) && (!ifStopPlotter) && (!isPlottingFinished)) { //plotting loop
      while((!ifPausePlotter) && (!ifStopPlotter) && (!isPlottingFinished) && (isCurrentPortActive())) {
        if(isPlotterWaiting) { //print the resuming message if plotter was waiting.
          println("Plotting thread is resuming.");
          println();
        }
        isPlotterWaiting = false;
        isPlotterActive = true;

        //------- Get the plotter ready to plot -----------//
        if ((!ifPlotterReady) && (isCurrentPortActive()) && (!ifStopPlotter)) { //if plotter is not ready yet

          if((!waitingForResponse) && (!ifPlotterReady) && (!ifStopPlotter)) {
            serialSendCommand("READY?"); //asl if ready
            delay(1000);
            commandRetryCount++;
          }

          if (serialCheckRespone("READY!")) { //read response
            println("Plotter is ready");
            println();
            ifPlotterReady = true; //plotter is ready
            commandRetryCount = 0;
          }
          else {
            ifPlotterReady = false; //plotter is not ready yet
          }

          if (commandRetryCount == 10) { //if retries are exhausted
            commandRetryCount = 0;
          }
        }
        //--------- Plotter initiation ends -------------//

        //------------------------ Plotting starts --------------------//
        if ((ifPlotterReady) && (isCurrentPortActive()) && (!ifStopPlotter)) {

          //------------------- Header Info Starts ---------------------------//
          if (currentSegment == 0) { //do only once
            currentPlotterStatus.setLabel("Initializing");
            serialSendCommand("G251,W" + imageWidth + "," + "H" + imageHeight); //send image width and height
            delay(100);
            waitingForResponse = false; //does not confirm

            if (ifLines) {
              serialSendCommand("G252,LINE,N" + lineCount); //plot mode is lines
              delay(100);
              waitingForResponse = false;
            }

            else if (ifPoints) {
              serialSendCommand("G252,POINT,N" + pointCount); //plot mode is points
              delay(100);
              waitingForResponse = false;
            }

            else if (ifFreehand) {
              serialSendCommand("G252,FREE,N" + segmentCount); //plot mode is freehand
              delay(100);
              waitingForResponse = false;
            }

            serialSendCommand("G28"); //return to home
            delay(100);
            waitingForResponse = false;

            isPlottingStarted = true;
            isPlottingFinished = false;
            currentSegment = 1;
            coordinateType = 0;
            isPenDown = false;
            serialPort.clear();
          }
          //--------------------- Header Info Ends ---------------------------//

          //---------- Lines start -------------//
          if ((ifLines) && (!isPlottingFinished) && (isCurrentPortActive()) && (!ifStopPlotter)) {
            if (currentSegment > lineCount) { //check if finished plotting all lines
              println();
              serialSendCommand("M30");
              delay(50);
              println();
              println("Plotting has finished.");
              isPlottingFinished = true; //plotting has finished
              resetPlotter();
            }
            else if ((!isPlottingFinished) && (!ifStopPlotter)) { //if plotting has not finished yet
              currentPlotterStatus.setLabel("Working");
              if ((!waitingForResponse) && (!ifStopPlotter)) {
                if (((coordinateType == COORD_TYPE_END) || (coordinateType == COORD_TYPE_NONE)) && (!isPenDown) && (!ifStopPlotter)) { //check what type of coordiante was sent last. 2 = end, 1 = start
                  println();
                  println("Current Segment = " + currentSegment + " / " + lineCount);
                  currentTask.setLabel(currentSegment + "/" + lineCount);
                  serialSendCommand("G00," + getStartOfLine(currentSegment) + ",Z2"); //get the start cord of the current line
                  currentPlotterPosition.setLabel(lineCords[0][0][currentSegment-1] + ", " + lineCords[0][1][currentSegment-1] + ", 2");
                  coordinateType = COORD_TYPE_START; //set the type to start coordiante
                  waitingForResponse = true; //set the flag and wait for response
                }

                else if((coordinateType == COORD_TYPE_START) && (!isPenDown) && (!ifStopPlotter)) { //if start coordinates have been sent
                  serialSendCommand("G01,X0,Y0,Z1"); //pen down
                  currentPlotterPosition.setLabel(lineCords[0][0][currentSegment-1] + ", " + lineCords[0][1][currentSegment-1] + ", 1");
                  isPenDown = true;
                  coordinateType = COORD_TYPE_DOWN; //coordinate for Z axis
                  waitingForResponse = true; //set the flag and wait for response
                }

                else if ((coordinateType == COORD_TYPE_DOWN) && (isPenDown) && (!ifStopPlotter)) { //check what type of coordiante was sent last. 2 = end, 1 = start
                  serialSendCommand("G00," + getEndOfLine(currentSegment) + ",Z2");
                  currentPlotterPosition.setLabel(lineCords[1][0][currentSegment-1] + ", " + lineCords[1][1][currentSegment-1] + ", 2");
                  currentSegment++; //increment and move to next line
                  coordinateType = COORD_TYPE_END; //set the type to end coordinate
                  waitingForResponse = true; //set the flag and wait for response
                }

                else if ((coordinateType == COORD_TYPE_END) && (isPenDown) && (!ifStopPlotter)) {
                  serialSendCommand("G01,X0,Y0,Z0"); //pen up
                  currentPlotterPosition.setLabel(lineCords[1][0][currentSegment-1] + ", " + lineCords[1][1][currentSegment-1] + ", 0");
                  isPenDown = false;
                  coordinateType = COORD_TYPE_NONE; //reset the coordinate type. 0 means nothing
                  waitingForResponse = true; //set the flag and wait for response
                }
              }

              if((waitingForResponse) && (!ifStopPlotter)) {
                if (serialCheckRespone("DONE!")) { //check response
                  waitingForResponse = false; //reset the flag
                }
                else currentSerialComStatus.setLabel("Waiting");
              }
            }
          }
          //------------ Lines end -------------//

          //---------- Points start -------------//
          if ((ifPoints) && (!isPlottingFinished) && (isCurrentPortActive()) && (!ifStopPlotter)) {
            println("Points : Feature not supported yet.");
          }
          //------------ Points end -------------//

          //---------- Freehand starts -------------//
          if ((ifFreehand) && (!isPlottingFinished) && (isCurrentPortActive()) && (!ifStopPlotter)) {
            println("Freehand : Feature not supported yet.");
          }
          //------------ Freehand ends -------------//
        }
        //------------------------ Plotting ends --------------------//
      } //second while loop ends

      if((ifPausePlotter) && (!isPlotterWaiting)) {
        currentPlotterStatus.setLabel("Paused");
        println();
        println("Plotting thread is waiting.");
        println();
        isPlotterWaiting = true;
      }
    } //main while loop ends
  }

  if (ifStopPlotter) {
    println();
    println("Plotting has been cancelled !");
    serialSendCommand("M30");
    delay(50);
    isPlotterActive = false;
  }

  if ((ifStopPlotter) || (isPlottingFinished)) { //if plotting is finished or if to stop plotting
    ifStopPlotter = true;
    isPlottingFinished = true;
    isPlottingStarted = false;
    ifStartPlotter = false;
    ifPlotterReady = false;
    isPlotterActive = false;
    isPlotterWaiting = false;
    commandRetryCount = 0;
    currentSegment = 0;
    waitingForResponse = false;
    coordinateType = COORD_TYPE_NONE;
    currentSerialComStatus.setLabel("Connected");
    currentPlotterStatus.setLabel("Idle");
    currentPlotterPosition.setLabel("0, 0, 0");
    currentTask.setLabel(currentSegment + "/" + lineCount);
  }

  if(!isCurrentPortActive()) { //if there's a port error - reset everything
    isPlottingFinished = true;
    isPlottingStarted = false;
    ifPlotterReady = false;
    ifStartPlotter = false;
    isPlotterActive = false;
    isPlotterWaiting = false;
    ifStopPlotter = true;
    commandRetryCount = 0;
    currentSegment = 0;
    lineCount = 0;
    waitingForResponse = false;
    coordinateType = 0;
    currentSerialComStatus.setLabel("Connected");
    currentPlotterStatus.setLabel("Idle");
    currentPlotterPosition.setLabel("0, 0, 0");
    currentTask.setLabel("0/0");
    println("Thread has terminated abruptly !");
  }
}

//=========================================================================//
//receive any response, format it and return

String serialReceiveRespone() {
  if(isCurrentPortActive()) { //check if port is available
    if (serialPort.available() > 0) {
      currentSerialComStatus.setLabel("Receiving");
      String receivedResponse = serialPort.readStringUntil(DELIMITER); //read until
      if(receivedResponse != null) { //only if response is not null
        receivedResponse = removeDelimiter(receivedResponse); //remove delimiter
        int responseLength = receivedResponse.length(); //get the original length of response
        String receivedResponseCopy = receivedResponse; //take a copy
        receivedResponse = receivedResponse.replace("\n", "<CR>"); //replace new lines
        println("Received Response = " + receivedResponse + " (" + responseLength + ")"); //print debug
        return receivedResponseCopy; //return response
      }
      else return "NULL"; //if response string is null
    }
    else return "NULL"; //if no serial data is available
  }
  else return "NULL"; //if port is not active
}

//=========================================================================//
//check the equivalency of the response string with an expected string

boolean serialCheckRespone (String expectedResponse) {
  if(isCurrentPortActive()) { //check if port is available
    if (serialPort.available() > 0) {
      currentSerialComStatus.setLabel("Receiving");
      String receivedResponse = serialPort.readStringUntil(DELIMITER); //read the response from the buffer
      if((receivedResponse != null)) { //only if it's not null and valid with ; at the end
        receivedResponse = removeDelimiter(receivedResponse); //remove the delimiter
        int responseLength = receivedResponse.length(); //get the original length of response
        receivedResponse = receivedResponse.replace("\n", "<CR>"); //replace new lines
        println("Received Response = " + receivedResponse + " (" + responseLength + ")"); //print debug
        //println("Expected Response = " + expectedResponse + " (" + expectedResponse.length() + ")");

        if (receivedResponse.contains(expectedResponse)) { //check if response is what we expected
          //println("Checked Response = " + receivedResponse); //print debug
          //println();
          waitingForResponse = false; //reset serial waiting flag so as to send next command
          serialPort.clear(); //clear port after success
          return true; //if expected response is received
        }
        else return false; //if expected response is not received
      }
      else return false; //if response string is null
    }
    else return false; //if no serial data is available
  }
  else return false; //if port is not active
}

//=========================================================================//
//checks if the response string is valid

boolean isValidResponse (String a) {
  if(a.contains(";")) //ckeck for delimiter
  return true;

  else return false;
}

//=========================================================================//
//removes delimiter from response string

String removeDelimiter (String a) {
  if(isValidResponse(a)) { //check if valid
    String b = a.replace(";", ""); //replace delimiter
    return b;
  }
  else return "NULL";
}

//=========================================================================//
//sends the serial command and wait for a specific delay

boolean serialSendCommand(String commandString) {
  if(isCurrentPortActive()) { //check if port is alive
    currentSerialComStatus.setLabel("Sending");
    serialPort.clear(); //not sure about this
    serialPort.write(commandString); //write to serial port
    serialPort.write(DELIMITER); //write the delimiter
    println("Send command : " + commandString); //print debug
    waitingForResponse = true; //set the waiting flag and wait for response
    delay(100); //relaxation time
    return true;
  }
  else return false;
}

//=========================================================================//
//gets the end coordinates of a line

String getEndOfLine (int a) {
  if((a > -1) && (a <= lineCount)) { //index should be between 0 to lineCount
    String tempString = "X";
    tempString += nf(lineCords[1][0][a-1]); //x coordinate of end of line - as string
    tempString += ",Y";
    tempString += nf(lineCords[1][1][a-1]); //y coordinate of end of line - as string
    return tempString; //return the formatted string
  }
  else return "NULL";
}

//=========================================================================//
//gets the start coordinates of a line

String getStartOfLine (int a) {
  if((a > -1) && (a <= lineCount)) { //index should be between 0 to lineCount
    String tempString = "X";
    tempString += nf(lineCords[0][0][a-1]); //x coordinate of start of line - as string
    tempString += ",Y";
    tempString += nf(lineCords[0][1][a-1]); //x coordinate of start of line - as string
    return tempString; //return the formatted string
  }
  else return "NULL";
}

//=========================================================================//