public class Bubble {
  private int bubbleDiametre;
  private float bubbleX;
  private float bubbleY;
  private float speedIncrement;
  private int bubbleAlpha;

  public Bubble(float bubbleX_, float bubbleY_, int bubbleDiametre_) {
    bubbleDiametre = bubbleDiametre_;
    bubbleX = (bubbleX_ / 100) * width;
    bubbleY = bubbleY_;
    bubbleAlpha = 110;

    // Setting the speedIncrement to be a random value between 5 and 20, so
    // that each bubble will have it's own random speed
    speedIncrement = random(5, 20);

    drawBubble();
  }

  public void drawBubble() {
    noStroke();

    // Setting the red and green channels of the bubble's colour to 
    // be half of the value of their diametre, while the blue channel will
    // always be fully blue (255). This is so each bubble will be fundamentally
    // blue, but with variations in tint. Also setting the bubbleAlpha, based
    // which will decrease each time the bubble is redrawn, so that the bubbles
    // will fade out as they reach the top of the screen.
    fill(bubbleDiametre * 0.5, bubbleDiametre * 0.5, 255, bubbleAlpha);

    // Adding the bubble to the sketch
    ellipse(bubbleX, bubbleY, bubbleDiametre, bubbleDiametre);

    // Reducing the alpha of the bubble based on how fast the bubble
    // is moving (multiplied by a random value between 0.0005 and 0.0001) to give
    // some minor variation, and then subtracting it from the height so it will be
    // relative to where the bubble is on the sketch
    bubbleAlpha -= height * (speedIncrement * random(0.0005, 0.0001));

    // Decreasing the y value of the bubble by the speed increment to move the bubble
    // up the sketch
    bubbleY -= speedIncrement;
  }
}