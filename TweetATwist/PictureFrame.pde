public class PictureFrame {
  private int pfWidth;
  private int pfHeight;
  private float pfX;
  private float pfY;
  private float randomRotation;

  private PImage slitVideoImage;  
  private int slitVideoHeight;
  private int slitVideoWidth;

  private PGraphics frame;
  private int framedImageHeight;

  public PictureFrame(PImage savedSlitVideoImage) {
    // Setting the width and height of the pictureFrame to be equal to the 
    // full resolution of the sketch (we will shrink them down later, but I want
    // to store them at full resolution so that they can be scalled up again if
    // the user wants to zoom in on them in the main sketch)
    pfWidth = width;
    pfHeight = height;

    // Setting the rotation value of the picture frame to a random number between
    // -30 and 30, so that each picture frame will look like it has been randomly
    // thrown down over the rest of the sketch
    randomRotation = random(-30, 30);

    // Setting the framed image height to be 1.2 times the size of the picture frame,
    // as the white tab at the bottom (which gives the impression of the picture being
    // a polaroid picture) will be 20% the si
    framedImageHeight = round(pfHeight * 1.2);

    // Setting the x of the picture frame to default to 0, and the y to be the height of the
    // sketch minus the framed height of the image (including the polaroid border) so that 
    // all picture frames will appear along the bottom of the sketch
    pfX = 0;
    pfY = height - framedImageHeight;

    // Setting the slitVideo image to be equal to the savedSlitVideo image that was just passed in
    // to the constructor
    slitVideoImage = savedSlitVideoImage;
    slitVideoWidth = slitVideoImage.width;
    slitVideoHeight = slitVideoImage.height;

    // Creating the picture frame of the image to have a width and height that matches the image,
    // a white stroke, a stroke weight 1/20th the width of the image (so that it will be scalable)
    // and adding a white rectangle below the frame, to give the effect of a polaroid image
    frame = createGraphics(slitVideoWidth, framedImageHeight);
    frame.beginDraw();
    frame.stroke(255);
    frame.strokeWeight(slitVideoWidth / 20);
    frame.noFill();
    frame.rect(0, 0, slitVideoWidth, slitVideoHeight);
    frame.noStroke();
    frame.fill(255);
    frame.rect(0, slitVideoHeight, slitVideoWidth, framedImageHeight - pfHeight);
    frame.endDraw();
  }

  public void show(float imageNum) {
    // Setting the width of the picture frame to be 1/6th of the width of the sketch
    // so that all six current picture frames will fit across the sketch equally
    pfWidth = round(width / 6);

    // Setting the height of the picture frame to be relative to the aspect ratio of
    // the sketch, multiplied by a quarter of the height
    pfHeight = round((width / height) * (height / 4));

    // Setting the framed height of the picture frame to be 20% taller than the image, 
    // so that the polaroid frame will also fit on the sketch
    framedImageHeight = round(pfHeight * 1.2);

    // Positioning the picture frame at the bottom of the sketch (when using imageMode = CENTER)
    pfY = height - framedImageHeight + (pfHeight / 2);

    // Setting the x position of the image based on which number in the set of 6 it is equal
    // to i.e. the first image will be positioned at 0 + half of it's own width
    pfX = imageNum * (pfWidth) + (pfWidth / 2);

    // Saving the current state of the matrix
    pushMatrix();

    // Translating the matrix based on the picture frame x and y we set above, so that each
    // image can be drawn at 0, 0
    translate(pfX, pfY);

    // Rotating the matrix based on the random rotation of each picture frame
    rotate(radians(randomRotation));

    // Setting the imageMode to CENTER so that each picture frame will rotate around it's center point
    imageMode(CENTER);
    flipAndShowImage(slitVideoImage, pfWidth, pfHeight);

    // Adding the picture frame to the sketch
    image(frame, 0, pfHeight * 0.1, pfWidth, framedImageHeight);

    // Resetting the imageMode to it's default value of CORNER, and resetting the matrix to it's original
    // co-ordinates
    imageMode(CORNER);   
    popMatrix();
  }
  
  public PImage getSlitVideoImage(){
    return slitVideoImage;
  }
}

// Was considering using the polaroid picture frame in the fullscreen version (when the user clicks
// on a picture frame in the sketch. Decided against it, but wanted to save the code for future use possibly
/* 
 if(fullscreen)
 {
 pfWidth = width;
 pfHeight = height;
 framedImageHeight = round(pfHeight * 1.2);
 pfY = pfHeight / 2;
 pfX = pfWidth / 2;
 }
 else {
 pfWidth = round(width / 6);
 pfHeight = round((width / height) * (height / 4));
 framedImageHeight = round(pfHeight * 1.2);
 pfY = height - framedImageHeight + (pfHeight / 2);
 pfX = imageNum * (pfWidth) + (pfWidth / 2);
 }
 */
