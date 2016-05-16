private String newsTitle;
private int alpha;
private float x;
private float y;

public class NewsText {
  public NewsText(String newsTitle_, int alpha_) {
    newsTitle = newsTitle_;
    alpha = alpha_;
    x = width / 2;
    y = height;
  }

  public void move() {
    // Setting the alpha value of the text by mapping it's current y value
    // from a range of 0 to the height of the sketch, to be a value between
    // 0 and 255. This way text will fade out an eventually become invisible
    // as it moves up the screen. The reason behind this is so that no matter
    // what the height of the sketch is, the text will always be just about to
    // fade out by the time it reaches the top of the screen.
    alpha = round(map(y, 0, height, 0, 255));

    // Setting a random value to the x of the text, so that it will appear to 
    // jitter back and forth across the screen
    x = random(0, width);

    // Decreasing the y value of the text so that it moves up the screen
    y -= 0.5;

    // Setting the text colour to white, and the alpha channel to equal the
    // alpha value we set above i.e. so that the text will continue to fade
    // out as it moves up the screen
    fill(255, 255, 255, alpha);

    // Setting the size of the font to be a random value between 12 and 60, so
    // that the text will randomly grow and shrink every time it moves
    textSize(random(12, 60));

    // Adding the text to the sketch using the string value it was assigned when
    // it was created, as well as the x and y values we set above
    text(newsTitle, x, y);

    // Resetting defaults
    textSize(14);
  }

  // Creating a method to return the alpha of the text to the main sketch, so that
  // we can tell if the text is still visible or not. Once the alpha value reaches 0,
  // a new newsText object will be created, containing a new random news title  
  public int getAlpha() {
    return alpha;
  }
}

