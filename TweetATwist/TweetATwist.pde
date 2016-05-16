import ddf.minim.*;
import processing.video.*;
import twitter4j.conf.*;
import twitter4j.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import java.util.*;

XML settings;

// Creating a boolean to adjust the sketches capabilities based on
// whether there is internet available or not. Currently, I have no
// way of checking if there is internet available, but I have been
// experimenting with various ways of testing the connection (see
// the experiments folder of my GitHub account). For the meantime,
// if this boolean is set to false, the sketch will reduce it's
// functionality appropriately, and all interactions with Twitter
// and other external resources e.g. news feeds, will be disabled.
// The instruction screen will also be updated, to reflect the 
// interactions that are currently available
Boolean internetAvailable = true;

// The ability to send images to twitter is off by default, and
// can be turned on by changing this variable
Boolean twitterOn = true;  
String tweetText = "Tweet A Twist.";
String tweetHashtags = "#processing #java";
String twitterQuery = "#tweetatwist";

// Audio Variables
Minim minim;
AudioPlayer cameraClick;
AudioPlayer cameraZoomIn;
AudioPlayer cameraZoomOut;

// Slit Video variables
PImage newFrame;
Capture liveStream;

// These variables are fully explained in the setup() function
int sketchWidth;
int sketchHeight;
int originalReuseFrames;
int reuseFrames;
int totalSavedFrames;
int secondsDelay;
PImage[] allSavedFrames;
int sketchFrameRate;
int liveStreamFrameRate;

// Booleans to ensure that the external threads and the main
// sketch communicate effectively together i.e. that images
// wont start being created from the saved frames until the 
// buffer is built, and that the draw function will only 
// add an image to the sketch when a new image is available
Boolean buffered = false;
Boolean imageAvailable = false;

// The variable is only used when the buffer is being created
// when the sketch loads, to ensure that new images are incrementally
// saved to the next available space in the saved frames array
int saveToFrame = 0;

// Globally accessible image which will contain the latest
// slit video image, which is created in the createSlitImage
// thread. The reason for this variable is that threads
// cannot draw directly onto the sketch, so I am using this
// as a way to pass the data back from the thread to be used
// in the draw function
PImage slitImage;

String newestImagePath;

// Lets Twist Again Movie Setup
Movie letsTwistAgain;

// The user can show / hide the lets twist again video by pressing
// the ENTER key on their keyboard. By default, this video is hidden
Boolean letsTwistAgainShowing = false;

// Bubble Generator variables
XML[] keyboardButtons;
int bubbleSize;
int bubbleXPos;
int currentBubble = 0;
Boolean bubbleArrayFull = false;
Bubble[] bubbles;

// Latest News variables
XML[] newsSources;
String newsXmlSourceUrl;
int getNewsAt = 0;
String newsType;
XML rteNewsXmlData;
XML[] rteNewsItems;
Boolean newsAvailable = false;
NewsText newNews;

// Picture Frame Images variables
int totalSavedPfImages = 0;
PictureFrame[] savedPfImages = new PictureFrame[6];
int savePfImageTo = 0;
Boolean pfImagesAvailable = false;
PImage showPfImageFullscreen;
Boolean fullscreen = false;

// Tweet A Twist variables
TwitterFactory twitterFactory;
Twitter twitter;
String currentDirectory;
String[] tweetIds = new String[20];
int saveTweetIdTo = 0;
XML savedTweetIdsXmlData;
XML[] savedTweetIds;
Boolean twitterSearching = false;
int secondsDelayBetweenTwitterSearches;

// Created a new app on https://apps.twitter.com/, which generated the OAuth Keys
// and Access Tokens required for accessing Twitter's api. These keys/tokens are 
// unique to my TweetATwist2015/tweetatwist application.
String OAuthConsumerKey = "OUNstTKQhstYlaJdHz2EQxPqn";
String OAuthConsumerSecret = "ReMMk8Es8oCmEzZb8HDXIKwRKr4SK57IOd2HZfW82rx6TKlJWj";
String AccessToken = "4214109479-ThR0PMQC7xJnsTFnYKUQd9AizRl83RDT6R5wJyY";
String AccessTokenSecret = "GwMw5VD0rKdHX7DyPcr6gorxE7agzv0CM39VRLAwDuOZE";

// Instruction Screen
InstructionScreen instructionScreen;
Boolean showInstructions = false;
PImage questionMark; 

void setup() {
  // Initiating the sketch and the Live Stream Capture so that 
  // they will have the same width and height. Having to set the
  // size() values seperatly as the MAC's do not allow for variables
  // to be used in this function. The settings below can be swapped out
  // for a Standard Definition (SD) PC computer, or a High Definition (HD)
  // MAC Computer

  /*
  SD PC
   size(640, 360);
   sketchFrameRate = 60;
   liveStreamFrameRate = 30;
   */

  /*
  HD MAC */
  fullScreen();
  sketchFrameRate = 90;
  liveStreamFrameRate = 90;

  settings = loadXML("settings.xml");

  // These variables are used below to calculate the required buffer,
  // as well as setting up the camera to match the sketch size
  sketchWidth = width;
  sketchHeight = height;

  background(0);
  frameRate(sketchFrameRate);

  // Setting up and starting the live stream
  liveStream = new Capture(this, sketchWidth, sketchHeight, liveStreamFrameRate);
  liveStream.start();

  // The quality, speed and buffer size of this sketch
  // are entirely based on how many lines we want to use
  // a frame for, which is set using "reuseFrames". The
  // totalSavedFrames and secondsDelay will be calculated
  // based on this variable, in conjunction with the
  // sketchFrameRate. Using the originalReuseFrames variable
  // to set this, so that if the user changes it later with
  // the arrow keys, it can always be reset to the original
  originalReuseFrames = 1;
  reuseFrames = originalReuseFrames;

  // Setting the total saved frames required i.e. the buffer size
  // to be equal to the height of the sketch. This is so that I can 
  // allow the user to increase the quality of the sketch using 
  // the arrow keys, without suddenly having to pause to create a larger
  // buffer
  totalSavedFrames = sketchHeight / originalReuseFrames;

  // Calculating the amount of seconds that will be reuqired in
  // order to get the most optimal result based on the total
  // number of frames that are being saved divided by the 
  // sketch frame rate i.e. how long it is going to take the
  // sketch to build up that many frames
  secondsDelay = totalSavedFrames / sketchFrameRate;

  // Globally accessible array of images, which acts as a buffer
  // for the slit video. Images are added to this array using the 
  // saveFrame thread. Lines are taken from each of these images
  // to create each frame of the slit video in the createSlitImage
  // thread
  allSavedFrames = new PImage[totalSavedFrames];

  // Setting up the instruction screen
  instructionScreen = new InstructionScreen();
  questionMark = loadImage("questionMark.png");

  // Audio Setup
  minim = new Minim(this);
  cameraClick = minim.loadFile("cameraClick.mp3");
  cameraZoomIn = minim.loadFile("cameraZoomIn.mp3");
  cameraZoomOut = minim.loadFile("cameraZoomOut.mp3");

  // Lets Twist Again Video
  letsTwistAgain = new Movie(this, "letsTwistAgain.mp4");
  letsTwistAgain.loop();  

  // Creating bubbles based on user pressing keyboard keys, and creating
  // the bubbles array to hold all the bubbles we generate (there will only
  // ever be 100 bubbles at any time, as we will just loop around and
  // overwrite the oldest bubbles in the array if we run out of space
  keyboardButtons = settings.getChild("keyboardButtons").getChildren("button");
  bubbles = new Bubble[100];

  // Printing out the settings of this sketch
  println("--------------------------------------------------------------------------");
  println("SKETCH SETTINGS");
  println("Each frame will be reused for " + reuseFrames + " lines");
  println("The frame rate of this sketch is " + sketchFrameRate + " fps");
  println("The required time delay for this sketch is " + secondsDelay + " seconds");
  println("The required buffer size of this sketch is " + totalSavedFrames + " frames");
  println("--------------------------------------------------------------------------");

  if (internetAvailable)
  {
    // Configuring the twitter4j library using the keys/tokens I have generated above.
    // This is required for access the twitter API (to identify which app and/or developer
    // is requesting access to the TwistATweet2015/tweetatwist application
    ConfigurationBuilder config = new ConfigurationBuilder();
    config.setOAuthConsumerKey(OAuthConsumerKey);
    config.setOAuthConsumerSecret(OAuthConsumerSecret);
    config.setOAuthAccessToken(AccessToken);
    config.setOAuthAccessTokenSecret(AccessTokenSecret);

    // Creating an instance of the twitter factory class, and passing in the configuration
    // settings, including keys and tokens as created above, to allow the application
    // access to the relevant twitter API
    twitterFactory = new TwitterFactory(config.build());
    twitter = twitterFactory.getInstance();

    // Setting the amount of seconds to delay between each twitter search, as calling the 
    // Twitter API too often will result in the application exceeding the rate limit allocated
    secondsDelayBetweenTwitterSearches = 6;

    // Getting the absolute path to the sketches current location, as I will need it later
    // to read in the twitterImage file as a File object - file objects appear to require
    // absolute paths as opposed to relative ones for some reason
    currentDirectory = sketchPath("");

    // Getting the latest news from RTE Entertainment and creating an empty newNews object,
    // as a placeholder until the news sources have been fully loaded and setup
    newsSources = settings.getChild("newsSources").getChildren("news");
    //getNewsXmlSource();
    newNews = new NewsText("", 255);

    // Getting any previously saved tweetId data - so we can tell if tweets
    // are old or new
    savedTweetIdsXmlData = loadXML("savedTweetIds.xml");
    if (savedTweetIdsXmlData.getChildren("tweetId").length > 0)
    {
      savedTweetIds = savedTweetIdsXmlData.getChildren("tweetId");
      for (int i = 0; i < savedTweetIds.length; i++)
      {
        // Working out how many child elements there are in the savedTweetIdsXmlData
        // XML sheet, so that we can make sure to stay within this range in the below
        // if statement
        int getIndexValue = savedTweetIdsXmlData.getChildren("tweetId").length - 1 - i;

        if (getIndexValue >= 0 && i < tweetIds.length)
        {
          // Getting the content of the XML element i.e. the tweet id of the previously saved tweets
          // and storing it in the tweetIds array to be accessed later to test against tweets as they
          // are read in
          tweetIds[i] = savedTweetIds[getIndexValue].getContent();
        }
        //println("Loaded Saved Tweet XML index " + getIndexValue + " into index " + i + " of the tweetIds array. The value = " + tweetIds[i]);
        saveTweetIdTo = i + 1;
      }
    }

    //thread("getLatestNews");
  }
}

void draw() {
  background(0);
  // Using the buffered boolean to stop the draw function trying to access
  // the PImage array of images for the slit video, until that frame has 
  // been filled with a buffer of images to run the video. The only 
  // occurs once, when the sketch is first run
  if (buffered)
  {
    // Shifting the frames and creating a new slit image, whether or not a new
    // image has become available from the camera. There will still be movement in the 
    // saved frames, so I decided that I could speed up the responsiveness of the application
    // by running these two threads independantly of the captureEvent
    thread("shiftFrames");

    // Calling the createSlitImage thread to go create an image out of
    // the current allSavedFrames PImage array, which it will saved back
    // to the global slitImage PImage variable
    thread("createSlitImage");

    if (internetAvailable)
    {
      // Calling the searchTweets thread to check if the specified hashtag has
      // been used in any new tweets. Using the twitterSearching boolean to check
      // if this thread is already running, so that only one twitterSearching thread
      // will run at a time
      if (frameCount % (sketchFrameRate * secondsDelayBetweenTwitterSearches) == 0 && twitterSearching == false)
      {
        thread("searchTweets");
        twitterSearching = true;
      }
    }
  } else {
    textSize(width/10);
    textAlign(CENTER);
    fill(255);

    // Working out how much of the frame buffer has been loaded. I had to explicitly
    // cast each of the relevent values to floats in order for them to divide into
    // one another
    int percent = round((float(saveToFrame) / float(totalSavedFrames)) * 100);
    text("Loading... " + percent + "%", sketchWidth/2, sketchHeight/2);
  }
  if (imageAvailable)
  {
    // Accessing the global slitImage object and adding it to the stage as an image
    // using the flipAndShowImage function, to ensure the image is not a mirrored
    // version (as with most built in webcams).
    flipAndShowImage(slitImage, liveStream.width, liveStream.height);

    if (letsTwistAgainShowing)
    {
      // Lowering the alpha so that I can place the letsTwistAgain video frames as
      // and a semi-transparent overlay on the slitImages to try and encourage users 
      // to dance and interact with the video. Centering the imageMode, so that the video will
      // always be centered, regardless of the sketche's aspect ratio
      tint(255, 100);
      imageMode(CENTER);

      // Adding a frame of letsTwistAgain to the sketch. As the resolution of the screen
      // may change depending on the device, I wanted the video to always be the full height
      // of the screen, so I set the x and y to be half the height and width (as imageMode is
      // set to 0). As the original resolution of the video is 360 x 640, I have set the height
      // to be the height of the sketch, and the width to be 1.77 times the value of the height
      // so that the video's aspect ratio will be maintained (16:9)
      image(letsTwistAgain, width/2, height/2, height * 1.77, height);

      // Resetting the imageMode to the default of CORNER, and resetting the alpha of the sketch
      // back to full, so that no other images in the sketch will be affected.
      imageMode(CORNER);
      tint(255, 255);
    }
  }

  // Checking if the XML data has been loaded in from the RTE Entertainment RSS feed
  if (internetAvailable && newsAvailable)
  {
    // As each NewsText element will incrementally fade out (based on it's alpha channel)
    // as it moves up the screen, I will use the getAlpha() method to continually test if
    // the news is still visible. If it is, the .move() method will be called to continue
    // moving it up the screen, otherwise a new news object will be created
    if (newNews.getAlpha() > 0)
    {
      newNews.move();
    } else {
      // Picking a random news item based on a random index between 0 and the 
      // highest possible index in the array of "news items" in the rte news XML
      int randomNewsItemAt = round(random(0, rteNewsItems.length - 1));

      // Getting the title of the news article and storing it in a string, so it
      // can be passed in to create a text object based on it
      String randomNewsItem = rteNewsItems[randomNewsItemAt].getChild("title").getContent();

      // Creating a new NewsText object using the title of the latest random news item's title
      newNews = new NewsText(randomNewsItem, 255);

      /*
      println(newsType + " UPDATE - " + randomNewsItem);
       println("--------------------------------------------------------------------------");
       */
    }

    if (frameCount % 3000 == 0)
    {
      // Reload the latest news for the RTE Entertainment RSS feed, to get the latest updates
      thread("getLatestNews");
    }
  }

  // Move all the bubbles, based on their individual speed properties
  moveBubbles();

  // Checking if picture frame images are available. Once the user has hit the spacebar once, then
  // this will always be true, it only needs one image to be available before it shows them
  if (pfImagesAvailable)
  {
    // Deciding which increment constraint to use, depending on how many picture frame images I
    // have currently saved in. If there isn't enough to loop through the full array, then
    // we will just use the total count of how many images have been saved up to now to 
    // constrain the loop within the relevant part of the array
    int incrementWithin = totalSavedPfImages < savedPfImages.length ? totalSavedPfImages : savedPfImages.length;

    for (int i = 0; i < incrementWithin; i++)
    {
      // Calling the show() method on each of the picture frame images, so that they will
      // be continually redrawn over the rest of the elements in the scene
      savedPfImages[i].show(i);
    }
  }

  if (fullscreen)
  {
    flipAndShowImage(showPfImageFullscreen, liveStream.width, liveStream.height);
  }

  if (showInstructions)
  {
    instructionScreen.show();
  } 
  // Show Question mark to open/close instruction screen
  image(questionMark, width - questionMark.width, 0);
}
void mouseClicked() {
  if ((mouseX > width - questionMark.width) && (mouseY < questionMark.height))
  {
    showInstructions = !showInstructions;
  } else {
    showInstructions = false;
  }

  // Checking if there are picture frame images available, and if there are,
  // that none of them are currently showing fullscreen i.e. so that clicking on 
  // the lower area of the screen when there are no picture frames there won't cause an error
  if (pfImagesAvailable && fullscreen == false)
  {
    // As each of the picture frames has the same width, and are spaced equally,
    // then I just need to get what the mouse X position is on the screen, divide it
    // by the width of one of the images (as they all have the same width anyway) and
    // then set this as the index number of the picture frame image I want to get by
    // rounding it down (so that the possible numbers will be between 0 and the total
    // number of picture frame images available across the screen
    int getImage = floor(mouseX / savedPfImages[0].pfWidth);

    // If the mouse Y is greater than the height of the saved picture frames, and the
    // getImage number is less than totalSavedPfImages (just incase the above equation
    // should throw up any errors) the set the full screen PImage variable to contain the
    // original slitVideoImage which that frame contained, and set the fullscreen
    // boolean to true, so that the draw function knows that it can now show this image
    if (mouseY > savedPfImages[0].framedImageHeight && getImage < totalSavedPfImages)
    {
      showPfImageFullscreen = savedPfImages[getImage].slitVideoImage;
      fullscreen = true;

      // Rewind the audio first, so that it will always play from
      // the beginning
      cameraZoomIn.rewind();
      cameraZoomIn.play();
    }
  } else if (fullscreen)
  {
    // If an image is already being shown in fullscreen, then clicking again will just
    // reset the fullscreen variable so that the draw function will no longer show this
    // image
    fullscreen = false;

    // Rewind the audio first, so that it will always play from
    // the beginning i.e. if it is currently playing and you
    // click again it will go back to the beginning.
    cameraZoomOut.rewind();
    cameraZoomOut.play();
  }
}

void keyPressed() {
  // Resetting fullscreen to false, so that the draw function knows to return the
  // picture frame images to their original size if one of them was being displayed
  // fullscreen
  fullscreen = false;

  println(keyCode);
  // SPACEBAR
  if (keyCode == 32 || keyCode == 33 || keyCode == 34)
  {
    println("Capture Image");
    // Saving an image
    thread("captureAnImage");
  } else if (keyCode == ENTER)
  {
    // Toggle the letsTwistAgainShowing boolean between true and false, so 
    // that users have the option to hide the video if they want
    letsTwistAgainShowing = !letsTwistAgainShowing;
  } else if (keyCode == DOWN)
  {
    // Increase the number of times a frame will be reused in a slit image i.e.
    // decrease the quality of the slitImage
    if (reuseFrames < 9)
    {
      reuseFrames++;
      println("Each frame will now be reused for " + reuseFrames + " lines in each slit image, so the quality will be reduced");
      println("--------------------------------------------------------------------------");
    }
  } else if (keyCode == UP)
  {
    // Decrease the number of times a frame will be reused in a slit image i.e.
    // increase the quality of the slitImage
    if (reuseFrames > originalReuseFrames)
    {
      reuseFrames--;
      println("Each frame will now be reused for " + reuseFrames + " lines in each slit image, so the quality will be increased");
      println("--------------------------------------------------------------------------");
    }
  } else if (keyCode == LEFT || keyCode == RIGHT)
  {
    // Reset the value of the reuseFrames variable to the default, as set in the
    // setup function i.e. return the quality of the slitImage to it's default
    reuseFrames = originalReuseFrames;
  } else if (keyCode >= 97 && keyCode <= 105 && internetAvailable)
  {
    // Testing if a key on the number pad has been pressed, and if it has,
    // then map the value from it's keyCode range of 97 to 105, to its index
    // value e.g. 0-8 and then get the news source using the getNewsXmlSourch thread
    int keyCodeNum = keyCode;
    getNewsAt = floor(map(keyCodeNum, 97, 105, 0, 8));
    //thread("getNewsXmlSource");
  } else {
    /* COMMENTED OUT FOR PEN AND PIXEL
     
     // Mapping the keyCodes which could represent a letter in the alphabet
     // (a-z lowercase) i.e. 65-90, to map to a range of 10 - 255, which I will use
     // as the width of the bubble that will be created
     int currentKey = round(map(keyCode, 65, 90, 10, 255));
     //println("The size value assigned to the character " + key + " is "  + currentKey);
     
     for (int i = 0; i < keyboardButtons.length; i++)
     {
     // Getting the character and the x position value of the
     // current element in the XML array
     String keyChar = keyboardButtons[i].getString("char");
     int keyValue = keyboardButtons[i].getInt("value");
     
     // Checking if the current element in the array is in the list of characters
     // that I have assigned values to in the external XML page to get the x position 
     // we want to assign to the button
     if (String.valueOf(key).indexOf(keyChar) >= 0)
     {
     //println("The x position value assigned to the character " + keyChar + " is " + keyValue);
     bubbleSize = currentKey;
     bubbleXPos = keyValue;
     thread("generateBubble");
     }
     }
     
     */
  }
}

void captureEvent(Capture c) {
  // Reading in the newest frame from the live stream
  liveStream.read();

  // Save the current frame using the saveFrame thread
  thread("saveFrame");
}

void movieEvent(Movie m)
{
  // Reading in the newest frame from the letsTwistAgain video
  letsTwistAgain.read();
}

void saveFrame() { 
  // Testing to see if enough frames have been loaded in to create the
  // buffer required for the slit scan image
  if (saveToFrame < totalSavedFrames - 1)
  {
    // While we set up the buffer for the video, we wont overwrite any previously
    // saved images in the allSavedFrames array, instead we will just use the 
    // saveToFrame variable to track where we last saved to, and then increase it
    // by one each time so that we always save to the next available space in the
    // array
    allSavedFrames[saveToFrame] = liveStream.get(0, 0, sketchWidth, sketchHeight);
    saveToFrame++;
  } else {    
    // Storing in the newest frame in the newFrame variable, so that the shiftFrames
    // thread can access it, to store it in position 0 of the PImage array. This is
    // so that the most recent images will always arrive at the top of the screen and
    // eventually work their way towards the bottom
    newFrame = liveStream.get(0, 0, sketchWidth, sketchHeight);

    thread("shiftFrames");

    // Now that enough images have been loaded in to fill the required buffer size
    // the buffered boolean will let the draw function know that it can now start calling
    // the shiftFrame and createSlitImage threads
    buffered = true;
  }
}

void createSlitImage() {
  // Creating a slitImage object to store the image that will be displayed
  // on screen. The purpose of this object is that it is not possible
  // to draw directly onto the main sketch from a thread, so by using
  // a global variable I can just pass the image back instead
  slitImage = createImage(liveStream.width, liveStream.height, ARGB);

  for (int y = 0; y < liveStream.height; y+=reuseFrames)
  {
    // Mapping the value of y to a range of 0 to the total number of images 
    // stored in the allSavedFrames array, so that we can reuse the frames
    // for multiple rows. This is so that even if we only have 60 frames 
    // saved, and the window height is 120, then we can just use each frame
    // twice to make up for the difference. It also means that the line
    // at the top of the screen will always come from the first (and most 
    // recently saved) frame in the array, and the bottom will always come
    // from the last image in the array, and so will achieve the desired effect
    // of top to bottom animation
    int getFrameAt = round(map(y, 0, liveStream.height, 0, totalSavedFrames / reuseFrames));

    // Getting the frame specified by getFrameAt from the PImage allSavedFrames
    // array, and storing it in a temporary PImage variable
    PImage getFrame = allSavedFrames[getFrameAt];

    // Getting the colour values of a specific line of the image
    // and setting them as the values of the corrosponding line
    // on the main sketch
    PImage getLine = getFrame.get(0, y, liveStream.width, reuseFrames);
    // slitImage.blend(getLine, 0, y, liveStream.width, 1, 0, y, liveStream.width, 1, LIGHTEST);
    // pimg.blend(src, sx, sy, sw, sh, dx, dy, dw, dh, mode)

    slitImage.set(0, y, getLine);
  }

  // Letting the draw function know that there is now a new image available
  imageAvailable = true;
}

void shiftFrames() {
  // Shifting each frame down by one in the array of saved frames and essentially
  // loosing the last image in the array, so that we will only ever have the most
  // recent images saved (to a maximum specified by totalSavedFrames)
  for (int i = allSavedFrames.length - 1; i > 0; i--)
  {
    allSavedFrames[i] = allSavedFrames[i - 1];
  }

  // Saving the newest frame into the first position in the array
  allSavedFrames[0] = newFrame;
}

void getNewsXmlSource() {
  // Getting the href of the relevant news outlet e.g. business, sport etc,
  // usng the getNewsAt (set by the number keys on the keyboard) variable to access the 
  // relevant xml element in the newsSources XML document
  newsXmlSourceUrl = newsSources[getNewsAt].getString("href");
  try {
    // Loading in the XML from the news source url specified above
    rteNewsXmlData = loadXML(newsXmlSourceUrl);

    // Getting the type of news e.g. business, sport etc, so that I can print out
    // below what the news source is titles
    newsType = newsSources[getNewsAt].getString("from");

    // Calling to getLatestNews thread to load in the newest XML from this source
    thread("getLatestNews");

    println("You will now receieve news updates from " + newsType);
    println("--------------------------------------------------------------------------");
  } 
  catch (Exception e) {
    println("Could not load XML");
  }
}

void getLatestNews() {
  // Loading in the "item" children from the relevant news xml
  rteNewsItems = settings.getChild("newsSources").getChildren("item");
  newsAvailable = true;
}

void generateBubble() {
  // Create a new bubble and add it to the relevant position in the array
  // i.e. if the array is not yet full, add it to the next available 
  // position, or else just override the most historic bubble in the array
  Bubble myBubble = new Bubble(bubbleXPos, height, bubbleSize);
  bubbles[currentBubble] = myBubble;

  // Check if Bubbles array is full yet so that when we create a new bubble
  // we can add it to the relevant position in the array i.e. if the array is
  // not yet full, add it to the next available position in the array, or else 
  // just override the most historic bubble in the array
  if (currentBubble < bubbles.length - 1)
  {
    // Increasing the currentBubble so that we know where to store the next 
    // bubble that is created in the bubbles array
    currentBubble++;
  } else
  {
    // Setting current bubble back to 0, so that the loop can start all over again,
    // i.e. the next time a key is pressed, the new bubble will be put at position
    // 0 in the array, and therefore overwrite the most historic bubble
    currentBubble = 0;
    bubbleArrayFull = true;
  }
}

void moveBubbles() {
  // Check if Bubbles array is full yet, so that we know whether to loop
  // through the entire array, or just through the section of it that
  // actually has bubbles stored in it
  int itterateBy = bubbleArrayFull ? bubbles.length - 1 : currentBubble;

  // Loop through every bubble in the array and call the drawBubble()
  // method on it, so that it will animate itself to move up the screen
  for (int i = 0; i < itterateBy; i++)
  {
    bubbles[i].drawBubble();
  }
}

void searchTweets() {
  if (buffered)
  {
    println("SEARCHING FOR TWEETS CONTAINING " + twitterQuery);
    println("--------------------------------------------------------------------------");
    try {
      Query query = new Query(twitterQuery);
      QueryResult result = twitter.search(query);

      if (result.getTweets() != null)
      {
        List<Status> tweets = result.getTweets();
        for (Status tweet : tweets) {
          // Creating a new date object, so that I can test the current time against the
          // time the tweet was sent. This is so that only new tweets will trigger an image
          // to be generated (as before this any tweets containing the relevant hashtags were
          // triggering the captureAnImage thread, even though they may have been previously
          // read in)

          Date d = new Date();
          long currentTime = d.getTime();
          long tweetSentTime = tweet.getCreatedAt().getTime();
          //println(currentTime - tweetSentTime);
          //println(tweet.getId());

          // Checking if the tweet is less than an hour old - Twitter picks up on tweets that were sent historically,
          // so by cutting out everything more than an hour old, I am saving the sketch having to loop through the 
          // tweetIds array to see if this is a new tweet
          if (currentTime - tweetSentTime < 3600000)
          {
            // Using a ternary operator to choose what to itterate the loop within. If there aren't enough
            // tweet ids saved in the tweetIds array then we will loop within the saveTweetIdTo variable,
            // otherwise we will itterate the loop within the length of the tweetIds array -1. The purpose
            // of this is that when the array is not full, we won't be looping through indexes that do
            // not yet hold a value
            int incrementTweetWithin = saveTweetIdTo < tweetIds.length ? saveTweetIdTo : tweetIds.length - 1;

            // Creating a new boolean for oldTweet. This boolean will start out as false, and will only every
            // become true if the tweet's id is equal to one of the tweetIds we have stored in the array. This
            // way we can tell if this is an old tweet or a new tweet to the sketch
            Boolean oldTweet = false;
            String currentTweetId = String.valueOf(tweet.getId());

            // Looping through the tweetIds we have previously saved, using the increment within variable we set above
            // to ensure we only test the indexes that contain a value
            for (int i = 0; i < incrementTweetWithin; i++)
            {
              if (currentTweetId.equals(tweetIds[i]))
              {
                // If the id of the current tweet is equal to one of the tweetIds we have previously saved, then this
                // is an old tweet, as we have read it in before, so we set oldTweet equal to true
                oldTweet = true;
                println("Old Tweet from " + tweet.getUser().getScreenName() + " : IncomingTweetId = " + tweet.getId());
                println("--------------------------------------------------------------------------");
              }
            } 

            // If this is not an old tweet - as set using the for loop above
            if (oldTweet == false)
            {
              saveTweetIdTo = saveTweetIdTo < tweetIds.length - 1 ? saveTweetIdTo : 0;          
              // Save the id of this tweet into our tweetIds array, so that we know we have read this tweet in next
              // time the sketch searches for new tweets
              tweetIds[saveTweetIdTo] = currentTweetId;

              // Using a ternary operator to increment saveTweetIdTo. If it is currently less than the length of the array
              // minus 1, we will increase it by one, otherwise if it is higher that the length of the array, we will
              // reset it to 0. This is so that we are always saving the tweetId over an empty space, or if the array is
              // full, the oldest space in the array
              saveTweetIdTo = saveTweetIdTo < tweetIds.length - 1 ? saveTweetIdTo + 1 : 0;

              // Save the tweetId to the external XML file - so this data will persist to the next session
              XML newTweetIdXml = savedTweetIdsXmlData.addChild("tweetId");
              newTweetIdXml.setContent(currentTweetId);
              saveXML(savedTweetIdsXmlData, "data/savedTweetIds.xml");


              // Setting the text that will be sent in the reply to the user
              tweetText = "Hi @" + tweet.getUser().getScreenName() + " :)";
              println("NEW TWEET from: @" + tweet.getUser().getScreenName() + " - " + tweet.getText());

              // Calling the captureAnImage thread, which will save out and image, and ultimatley a picture frame image. If
              // twitter is turned on (based on the twitterOn boolean) then this image will be tweeted back to the user
              // along with the above image
              thread("captureAnImage");
            }
          }
        }
      }
      //println("Search Completed");
      twitterSearching = false;
    } 
    catch (TwitterException twitterException) {
      twitterException.printStackTrace();
      println("Unable to search tweets due to: " + twitterException.getMessage());
      println("--------------------------------------------------------------------------");
    }
  }
}

void tweetWithImage()
{
  try
  {
    // Creating a new status object and passing in the tweetText, which was set when the 
    // spacebar was pressed
    StatusUpdate status = new StatusUpdate(tweetText);

    // Loading the twitterImage file in as a File. This image was saved to the images
    // folder when the spacebar was pressed (in the key pressed function). Ideally,
    // I would rather just send out a PImage in a tweet, as this would save me having to
    // save the image out of the sketch, only to load it back in a few milli seconds later,
    // but as the setMedia() method calls for a File object, this is the closest I can get
    // at the moment.
    File tweetImage = new File(currentDirectory + "/" + newestImagePath);

    // Setting the media item of the tweet to be the image we just loaded back in above
    // i.e. the most recent slitVideoImage
    status.setMedia(tweetImage);

    // Using the updateStatus() method to send out the tweet containing the text and image
    // as set above
    twitter.updateStatus(status);

    println("SENDING TWEET A TWIST");
    println("--------------------------------------------------------------------------");
  }
  catch (TwitterException twitterException)
  {
    // Providing a TwitterException that will be thrown if there is an issue sending
    // the tweet
    println("Error Message: "+ twitterException.getMessage());
    println("--------------------------------------------------------------------------");
  }
  println("TWEET A TWIST SUCCESSFULLY SENT");
  println("--------------------------------------------------------------------------");
}

void captureAnImage() {
  // If a full buffer of images has been saved in to the sketch, as set by the totalSavedFrames variable
  if (buffered)
  {
    // Creating a new picture frame and passing the current slit image in, so that it can
    // be displayed within the frame
    PictureFrame newPfImage = new PictureFrame(slitImage);

    // Storing the new picture frame image in the savedPfImages array. This array will only
    // ever hold the 6 most recently saved images, and it's purpose is that it allows me
    // to access all of these images within the draw function so that I can loop through and
    // call their show() method, so that they can be continually redrawn within the sketch
    savedPfImages[savePfImageTo] = newPfImage;

    // Creating a loop so that the images in the savedPfImages array will continually be
    // overwritten. This is so I will only ever save a maximum of 6 images (as discussed above).
    // Once the savePfImageTo int gets to the length of the array (-1) it will be reset to 0
    // and the process will start again
    if (savePfImageTo < savedPfImages.length - 1)
    {
      savePfImageTo++;
    } else {
      savePfImageTo = 0;
    }

    // Counting the total saved picture frame images. This really only matters until there have
    // been 6 images saved, as I am only using it to ensure that the loop in the draw function
    // doesn't try and access images that don't exist yet i.e. if there are only 2 saved images,
    // the loop can still run as it will just loop through how many have actually been saved
    // so far
    totalSavedPfImages++;

    // Using the pfImagesAvailable boolean to let the draw function know that there is now at
    // least one image available in the picture frame images array
    pfImagesAvailable = true;

    // Rewind the audio first, so that it will always play from
    // the beginning i.e. if it is currently playing and you
    // click again it will go back to the beginning.
    cameraClick.rewind();
    cameraClick.play();
  }

  if (twitterOn && internetAvailable)
  {
    // Creating a new PImage object so that I can save the current slit image in the 
    // saveForTwitter variable, so that I can save it out using the .save() method. 
    // The save() method requires an image that was created programmatically to be saved
    // out by using createImage() and get(), so that the sketch can work out the file location
    // which it would have otherwise known with an image that was read in i.e. from a camera
    // (According to the processing.org reference on .save(). The reason I am using .save() 
    // instead of .saveFrame() is that I don't want to save everything on screen, I just 
    // want to save the slit video image. I need to save the image out as a jpeg, so that the
    // tweetWithImage thread can read it back in as a File, as the twitter4j .setMedia()
    // method only accepts File objects as an argument.
    PImage saveImage = createImage(100, 100, RGB);
    saveImage = slitImage.get();

    // Using ternary operators to define the current date and time, for
    // use in the file name of the image (wanted each part of the date/time
    // to be represented by a two digit value i.e. 01 instead of 1)
    String currentDay = day() < 10 ? "0" + day() : "" + day();
    String currentMonth = month() < 10 ? "0" + month() : "" + month();
    String currentHour = hour() < 10 ? "0" + hour() : "" + hour();
    String currentMinute = minute() < 10 ? "0" + minute() : "" + minute();
    String currentSecond = second() < 10 ? "0" + second() : "" + second();

    // Generating a new filename for this image, based on the current time. Using the
    // newestImagePath variable to 
    newestImagePath = "Pictures/TweetATwist-" + currentDay + currentMonth + year() + "-" + currentHour + currentMinute + currentSecond + ".jpg";
    
    saveImage.save(newestImagePath);

    // Setting the text I would like to appear alongside my image in the tweet. I am including
    // the date and time in the tweet, as processing doesn't seem to like the same text going
    // out in two different tweets
    tweetText += " " + tweetHashtags;

    // Calling the tweetWithImage thread, which will load in the twitterImage.jpg from the images
    // folder of the sketch, and post this along with the tweetText to the TweetATwist2015
    // twitter page
    thread("tweetWithImage");
  }
}

void flipAndShowImage(PImage flipMe, float flipMeWidth, float flipMeHeight)
{
  // Storing the current position of the matrix
  pushMatrix();

  // Scalling the matrix by -1 on the x value, so that it will flip horizontally
  // while the y remains unaffected (by setting it to 1)
  scale(-1, 1);

  // Adding the image that was passed in to the function to the stage, using
  // width and height that were also passed in, setting the width to be minus
  // so that it will flip horizontally across the flipped matrix
  image(flipMe, 0, 0, -flipMeWidth, flipMeHeight);

  // Resetting the matrix to it's previous state
  popMatrix();
}

void exit() {
  // Stopping the letsTwistAgain video from playing
  letsTwistAgain.stop();

  // Stopping the liveStream from capturing new frames
  liveStream.stop();

  // Setting twitterSearching to true, so that the searchTweets
  // thread will no longer be called
  twitterSearching = true;

  println("Sketch Closed");
  println("--------------------------------------------------------------------------");
} 