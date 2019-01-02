// note: stereo version with two different curves on each channel (two AudioStreams). 
// note: only one oscillator and without sound optimization. multiple oscillators could be copied from version 110615 (a)
// note: x-axis = volume due to l/r panning (the more distant to the center the louder)
// note: y-axis = difference between the wave's volumes (the louder the sine wave the more to the top and v.v.)
// note: z-axis = pitch (the higher the higher)

// PrintWriter is initialized
PrintWriter mousePositions;

// global arrays and variables are defined 
String[] lines;
float[][] coordinatesArray;            // array in which the read coordinates are written into
float[][] altitude;                    // two-dimensional array which contains height depending on [x]/[y]  
int meshSizeIncrementX;
int meshSizeIncrementY;

// global variables (specific for this version) are defined
int diameterCircle = 7;
int[] startProfile = new int[2];
int[] endProfile = new int[2];
float[] elevationProfile = new float[2000];
int noteDurationProfile = 130;
int noteGapProfile = int(noteDurationProfile * 0.5);
int noteDurationCorrectorToChannel = 1;
float[] zSoundPitchProfile = new float[2000];
float panCenterToEdges = 0;
int profileMaxLength;

// global volumes and sound parameters are defined (avoid redundancy)
float volumeStream = 0.99;
float volumeSineWave = 0.33;
float volumeSquareWave = 0.05;
int unhearablePitch = 0;
int basicFrequency = 440;

int xySoundPitchMin = basicFrequency;
int xySoundPitchMax = 2 * basicFrequency;

// global boundary variables are defined
int maximumX = 0;
int minimumX = 100000000;
int maximumY = 0;
int minimumY = 100000000;
float maximumZ = 0;
float minimumZ = 100000;

// library Ess and its components are defined
import krister.Ess.*;
AudioStream myStreamUp, myStreamDown;
AudioChannel myChannelProfile;
SineWave myWaveUp;
SquareWave myWaveDown;
SineWave myWaveProfile;
Envelope myEnvelopeProfile;

// ******** setup function ********
// all setup settings are defined in this function
void setup(){
  // determines panel size and frame rate
  size(1280, 500);
  smooth();
  frameRate(40);
  cursor(CROSS);
  dataImport();
  startEss();
  drawDEM();
  
  // creates a text file in which the mouse positions will be written  
  mousePositions = createWriter("mousePositions.txt");
}

  
// ******** drawing function ********
// this function starts the sonification function depending on the drawing frameRate
void draw(){
  sonify();
}


// ******** data import function ********
// this function imports the DEM 
void dataImport(){
  // data import from text file
  lines = loadStrings("res/DEM.txt");

  // creates two-dimensional array in which the coordinates are stored separately
  coordinatesArray = new float[lines.length][3];

    // for-loop to load DEM and to determine min/max values    
  for (int i = 0; i < lines.length; i++){
    // splits each line into their components using ' ' as the divisor character
    String[] pieces = split(lines[i], '\t');

    // the following condition prevents mistakes due to void cells
    if (pieces.length == 3){
      // convert string to integer or float
      int x = int(pieces[0]);
      int y = int(pieces[1]); 
      float z = float(pieces[2]);    
 
      // intermediate step: converts strings to numerical values and write them into different arrays
      coordinatesArray[i][0] = x;
      coordinatesArray[i][1] = y;
      coordinatesArray[i][2] = z;
      
      // determines minimum and maximum values
      if (i > 0 && x > maximumX){
        maximumX = x;
      }
      if (i > 0 && x < minimumX){
        minimumX = x;
      }
      if (i > 0 && y > maximumY){
        maximumY = y;
      }
      if (i > 0 && y < minimumY){
        minimumY = y;
      }
      if (i > 0 && z > maximumZ){
        maximumZ = z;
      }
      if (i > 0 && z < minimumZ){
        minimumZ = z;
      }
    }
  }      

  // defines the mesh size increment which is dependent on the dataset
  meshSizeIncrementX = (maximumX - minimumX) / (width - 1);
  meshSizeIncrementY = (maximumY - minimumY) / (height - 1);
}


// ******** start function for Ess ********
// this function initializes Ess
void startEss(){
  // starts Ess, creates AudioStream, sets parameters, initializes wave oscillators and starts audio
  Ess.start(this);
  myStreamUp = new AudioStream();
  myStreamDown = new AudioStream();
  myChannelProfile = new AudioChannel();
  
  // hint: myChannelProfile's length is variable and bases on a global variable which every run will be refreshed
  myChannelProfile.initChannel(myChannelProfile.frames(noteDurationCorrectorToChannel * profileMaxLength * noteDurationProfile));

  EPoint[] myEnv = new EPoint[3];  //three-step breakpoint function
  myEnv[0] = new EPoint(0,0);      //Start at 0
  myEnv[1] = new EPoint(0.25, 1);  //attack
  myEnv[2] = new EPoint(2,0);      //release
  myEnvelopeProfile = new Envelope(myEnv);  //bind envelope to the breakpoint function
    
  myStreamUp.sampleRate(41000);
  myStreamDown.sampleRate(41000);
  
  myStreamUp.softClip = true;
  myStreamDown.softClip = true;
  
  myStreamUp.volume(0.99);
  myStreamDown.volume(0.99);
  
  // initializes the waves (oscillators) and set the myWaveProfile's pitch to 0 Hz to avoid malfunction.
  // hint: for debugging reasons just set the pitch to a hearable value (e.g. 1000 Hz)
  myWaveUp = new SineWave(unhearablePitch, volumeSineWave);
  myWaveDown = new SquareWave(unhearablePitch, volumeSquareWave);
  myWaveProfile = new SineWave(500, volumeSineWave);
   
  myStreamUp.start();
  myStreamDown.start();
}


// ******** DEM drawing function ********
// function which draws the DEM and ends afterwards. no lines could be drawn because of overdrawing.
void drawDEM() {
 // translates the coordinate system's origin to the lower left corner
  translate(0, height);
  scale(1.0, -1.0);  

  // this two-dimensional array stores the height values depending on the picture coordinates
  altitude = new float[width][height];

  // continue by retrieving values from array containing the numerical values
  for (int i = 0; i < coordinatesArray.length; i++){

    // converts x and y from float to integer because no float values are used for coordinates
      // note: height values will not be converted to integer - they will be retrieved from 'coordinatesArray[i][2]'
      int x = int(coordinatesArray[i][0]);
      int y = int(coordinatesArray[i][1]);
    
      // transforms geographical coordinates into image coordinates
      int xCoord = (x - minimumX + meshSizeIncrementX) / (meshSizeIncrementX);
      int yCoord = (y - minimumY + meshSizeIncrementY) / (meshSizeIncrementY);
      
      // calculates the gradient of the height difference between the lowest and the highest point divided in 256 RGB-units
      float colorDividend = (maximumZ - minimumZ) / 256;
      int zColor = round((coordinatesArray[i][2] - minimumZ) / colorDividend);

      // saves the float height value into a two-dimensional array depending on the image coordinates
      // hint: substract 1 from the image coordinates because an array begins with 0
      altitude[xCoord-1][yCoord-1] = coordinatesArray[i][2];

      // draws the relief as a greyscale picture    
      stroke(zColor);
      point(xCoord,yCoord);
  }
  noLoop();
}


// ******** mouse button interaction function ********
// function which determines the interaction for each mouse movement
void mousePressed() {
}


// ******** key interaction function ********
// this function determines what happens if a key will be pressed
void keyPressed(){
}


// ******** mouse interaction function ********
// function which determines the interaction for each mouse movement
void mouseMoved() {
  // writes the mouse positions in each line (tab delimited)
  mousePositions.println(mouseX + "\t" + mouseY);  
  mousePositions.flush();
}


// ******** sonification function ********
// this function calculates a sound from the actual mouse position and the retrieved height value
void sonify(){  
  // creates arrays with current cursor position (only one single row). The frequency is depending on the frame rate defined in the setup
  int[] mousePositionX = new int[1];
  int[] mousePositionY = new int[1];
  
  // writes the mouse position in the array. The x-position must be corrected by adding + 1 while the y-position must be substracted from 
  // 'height' because of coordinate system transformation, but without value correction because 'height' already contains it.
  mousePositionX[0] = mouseX + 1;
  mousePositionY[0] = height - mouseY ;

  // retrieves the height value from the actual cursor position, while the y-value must be corrected because of the transformation
  float retrievedHeight = altitude[mouseX][height-mouseY-1];

  // calculates pitch values from x and y positions (depending on DEM dimensions)
  float xySoundPitch = basicFrequency + retrievedHeight / maximumZ * basicFrequency;

  // passes the float variables 'xSoundPitch' and 'ySoundPitch' to the audioStreamWrite function
  audioStreamWrite(xySoundPitch);  
  loop();
  
  //println("x: " + mouseX + "\t" + "y: " + mouseY + "\t" + "z: " + retrievedHeight + "\t" + "zmin: " + minimumZ + "\t" + "zmax: " + maximumZ);
  //println(mousePositionX[0] + "\t" + width + "\t" + mousePositionY[0] + "\t" + height);    
}


// ******** sound output function ********
// this function outputs a sound from the calculated sound values 
void audioStreamWrite(float xySoundPitch) {
  // initialization of all music variables  
  myWaveUp.generate(myStreamUp);
  myWaveDown.generate(myStreamDown);
  
  // adjust phase
  myWaveUp.phase += myStreamUp.size;
  myWaveUp.phase %= myStreamUp.sampleRate;
  
  myWaveDown.phase += myStreamDown.size;
  myWaveDown.phase %= myStreamDown.sampleRate;
  
  // stores the defined anchor points in an array and draws an ellipse
  if ((keyPressed == true) && (key == 'f')) {
    startProfile[0] = mouseX;
    startProfile[1] = height - mouseY;
    stroke(255, 255, 0);
    fill(255, 255, 0);
    ellipse(mouseX, mouseY, diameterCircle, diameterCircle);  
    println("new start point set: " + startProfile[0] + " / " + startProfile[1]);
  }  
  
  // saves the end coordinates depending on a mouse click event
  else if ((keyPressed == true) && (key == 'e')) {
    if ((startProfile[0] == 0) && (startProfile[1] == 0)) {
      stroke(255, 0, 0);
      fill(255, 0, 0);
      ellipse(mouseX, mouseY, diameterCircle, diameterCircle);
      println("error: set first anchor point first by pressing 'f'");
    }
    else {
      if (myStreamUp.mute == false) {
        myStreamUp.mute(!myStreamUp.mute);      
      }
      if (myStreamDown.mute == false) {
        myStreamDown.mute(!myStreamDown.mute);      
      }
 
      // stores end points in an array and draws end lines     
      endProfile[0] = mouseX;
      endProfile[1] = height - mouseY;      
      strokeWeight(1);
      stroke(255);
      line(startProfile[0], height - startProfile[1], endProfile[0], height - endProfile[1]);
      strokeWeight(2);
      stroke(0, 255, 0);
      line(endProfile[0], height - endProfile[1]+5, endProfile[0], height - endProfile[1]-5); 
      line(endProfile[0]-5, height - endProfile[1], endProfile[0]+5, height - endProfile[1]);       
      println("new end point set: " + endProfile[0] + " / " + endProfile[1]);  
      
      // calculates slope
      float deltaX = endProfile[0] - startProfile[0];
      float deltaXAbs = abs(deltaX);
      float deltaY = -(endProfile[1] - startProfile[1]);
      float deltaYAbs = abs(deltaY);
      float m = -(deltaY / deltaX);          // must be negative because of the grid transformation
      
      if ((m > 1) || (m < -1)) {       
        profileMaxLength = int(deltaXAbs);   
        noteDurationCorrectorToChannel = round(abs(m));
        
        // starts Ess which reloads the profileMaxLenght stored as global variable
        startEss();
        
        // defines variables needed for the following for-loop
        int actualY;
        int calculatedX;
        int time = 0;
            
        // calculates a profile line due to the slope, retrieves the height values and stores them in an array
        for (int i = 0; i <= deltaYAbs; i++){
          // condition which checks wheter the profile must be drawn to the right or to the left
          if (endProfile[1] >= startProfile[1]) {
            actualY = startProfile[1] + i; 
            calculatedX = round(startProfile[0] + i * 1 / m);
          }
          else {
            actualY = startProfile[1] - i; 
            calculatedX = round(startProfile[0] - i * 1 / m);
          }

          /*elevationProfile[i] = altitude[calculatedX][actualY-1];        
          zSoundPitchProfile[i] = basicFrequency + elevationProfile[i] / maximumZ * basicFrequency;
          myWaveProfile.frequency = zSoundPitchProfile[i];          // update waveform frequency
          */
          myWaveProfile.frequency = basicFrequency + altitude[calculatedX][actualY-1] / maximumZ * basicFrequency;
          
          int begin = myChannelProfile.frames(time);                // starting position within channel
          int end = myChannelProfile.frames(noteGapProfile);        // ending position with channel        
   
          myWaveProfile.generate(myChannelProfile, begin, end);     // render triangle wave
          myEnvelopeProfile.filter(myChannelProfile, begin, end);   // apply envelope
          time += noteDurationProfile;                              // increment the channel output point
          println("Methode m<1 m>-1: " + calculatedX + "\t" + actualY + "\t" + elevationProfile[i] + "\t" + zSoundPitchProfile[i] + "\t" + " m = " + m + "\t" + i + "\t" + begin + "\t" + end);          
        }    
      }
      else {
        profileMaxLength = int(deltaYAbs);
        noteDurationCorrectorToChannel = round(abs(1/m));
        
        // starts Ess which reloads the profileMaxLenght stored as global variable
        startEss();
        
        // defines variables needed for the following for-loop
        int actualX;
        int calculatedY;
        int time = 0;
            
        // calculates a profile line due to the slope, retrieves the height values and stores them in an array
        for (int i = 0; i <= deltaXAbs; i++){
          // condition which checks wheter the profile must be drawn to the right or to the left
          if (endProfile[0] >= startProfile[0]) {
            actualX = startProfile[0] + i; 
            calculatedY = round(startProfile[1] + i * m);
          }
          else {
            actualX = startProfile[0] - i; 
            calculatedY = round(startProfile[1] - i * m);
          }

          elevationProfile[i] = altitude[actualX][calculatedY - 1];        
          zSoundPitchProfile[i] = basicFrequency + elevationProfile[i] / maximumZ * basicFrequency;
          myWaveProfile.frequency = zSoundPitchProfile[i];          // update waveform frequency
          
          int begin = myChannelProfile.frames(time);                // starting position within channel
          int end = myChannelProfile.frames(noteGapProfile);        // ending position with channel        
   
          myWaveProfile.generate(myChannelProfile, begin, end);     // render triangle wave
          myEnvelopeProfile.filter(myChannelProfile, begin, end);   // apply envelope
          time += noteDurationProfile;           // increment the channel output point
          println("Methode m>1 m<-1: " + actualX + "\t" + calculatedY + "\t" + elevationProfile[i] + "\t" + zSoundPitchProfile[i] + "\t" + " m = " + m + "\t" + i + "\t" + begin + "\t" + end);
        } 
      }     

      // debugging utilities
      //println(zSoundPitchProfile[i] + "\t" + myWaveProfile.frequency + "\t" + elevationProfile[i] + "\t" + i);        
      //println(startProfile[0] + " " + startProfile[1] + " " + endProfile[0] + " " + endProfile[1]);
        
      // plays the AudioChannel with the stored profile height
      myChannelProfile.play(); 
    }
  }
  else {
    if (myStreamUp.mute == true) {
      myStreamUp.mute(!myStreamUp.mute);      
    }  
    if (myStreamDown.mute == true) {
      myStreamDown.mute(!myStreamDown.mute);      
    }
    
    // defines the y-axis sound parameters depending on the cursor's position
    float volumeBottomToTop = 1 - mouseY/float(height);
    float volumeTopToBottom = mouseY/float(height);  
    
    myStreamUp.pan(panCenterToEdges);
    myStreamDown.pan(panCenterToEdges);
    
    myStreamUp.volume(volumeBottomToTop);
    myStreamDown.volume(volumeTopToBottom); 
      
    // if-loop to render the sound legend while pressing specific keys
    if (keyPressed == true){
      if ((key == CODED) && (keyCode == UP)) {
        // sets sound as hearable (not off), defines pitch and volume
        myStreamUp.mute(false);
        myWaveUp.frequency = round(xySoundPitchMax);
        myWaveUp.volume = volumeSineWave;

        myStreamDown.mute(false);
        myWaveDown.frequency = round(xySoundPitchMax);
        myWaveDown.volume = volumeSquareWave;
        
        println("up cursor key pressed:" + "\t" + "only highest tone hearable");
      } 
      else if ((key == CODED) && (keyCode == DOWN)) {
        // sets sound as hearable (not off), defines pitch and volume
        myStreamUp.mute(false);
        myWaveUp.frequency = round(xySoundPitchMin);
        myWaveUp.volume = volumeSineWave;

        myStreamDown.mute(false);        
        myWaveDown.frequency = round(xySoundPitchMin);
        myWaveDown.volume = volumeSquareWave;
        
        println("down cursor key pressed:" + "\t" + "only lowest tone hearable");
      }
      else if ((key == CODED) && (keyCode == SHIFT)) {
        // sets sound as hearable (not off), defines pitch and volume
        myStreamUp.mute(false);
        myStreamDown.mute(false);
   
        // mutes myWaveDown; only myWaveUp is hearable
        myWaveUp.volume = volumeSineWave;
        myWaveDown.volume = 0;
  
        println("SHIFT key pressed:" + "\t" + "only sine wave hearable");
      }
      else if ((key == CODED) && (keyCode == CONTROL)) {
        // sets sound as hearable (not off), defines pitch and volume
        myStreamUp.mute(false);
        myStreamDown.mute(false);
  
        // mutes myWaveUp; only myWaveDown is hearable
        myWaveUp.volume = 0;
        myWaveDown.volume = volumeSquareWave;
  
        println("CTRL key pressed:" + "\t" + "only square wave hearable");
      }
      else if ((key == CODED) && (keyCode == LEFT)) {
        myWaveUp.volume = volumeSineWave;
        myWaveDown.volume = volumeSquareWave;
        
        // sets balance to left
        panCenterToEdges = -1;
        
        println("left cursor key pressed:" + "\t" + "slowest beep velocity hearable");
      }
      else if ((key == CODED) && (keyCode == RIGHT)) {
        myWaveUp.volume = volumeSineWave;
        myWaveDown.volume = volumeSquareWave;

        // sets balance to right
        panCenterToEdges = 1;  
        
        println("right cursor key pressed:" + "\t" + "fastest beep velocity hearable");      
      }    
    } 
    // else-condition to render the regularly retrieved values without pressing any key 
    else {
      // assigns the balance and the pitch due to the cursor position and the retrieved height
      panCenterToEdges = -(1 - (mouseX/float(width)) * 2);
      myWaveUp.frequency = round(xySoundPitch);
      myWaveDown.frequency = round(xySoundPitch);
      
      // mutes the AudioStreams while AudioChannel is playing
      if (myChannelProfile.state == 2) {
        myStreamUp.volume(0);
        myStreamDown.volume(0);
      }
    }    
  }
}
 
  
// ******** Ess stop function ********
// this function ends Ess   
public void stop() {
  Ess.stop();
  super.stop();
}
