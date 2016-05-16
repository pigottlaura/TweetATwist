public class InstructionScreen {
  private String[] showInstructions;
  private float x;
  private float spacing;

  public InstructionScreen () {
    // Loading in the Instruction Screen XML from the settings XML (declared in the main sketch)
    XML[] instructionXML = settings.getChild("instructionScreen").getChildren("section");
    
    // Creating the showInstructions array with a length of 0, so that I can expand it as necessary
    // every time a line is read in (as I will not know how many lines I will be reading in
    // until later
    showInstructions = new String[0];

    // Looping through every sections of the Instruction Screen Settings
    for (int s = 0; s < instructionXML.length; s++)
    {
      XML section = instructionXML[s];
      String sectionType = section.getString("type");

      // With each iteration, I want to test the section type against the relevant variable, so that
      // only the relevant instruction lines are read in
      if ((sectionType.equals("internet") && internetAvailable) || (sectionType.equals("general")) || (sectionType.equals("noInternet") && !internetAvailable) || (sectionType.equals("twitter") && twitterOn && internetAvailable))
      {
        // Temporarily storing this section's lines as an array, so that I can loop through and
        // save out their contents
        XML[] lines = section.getChildren("line");

        // Looping through each line of the section, and storing it's content in the global
        // showInstructions array
        for (int l = 0; l < lines.length; l++)
        {
          // Temporarily storing this line so I can access it's content below
          XML line = lines[l];
          
          // Expanding the size of the showInstructions array by 1, so that this line
          // can now be added to it. The reason I do this before I actually add the line
          // is that if I did it after, I could end up with an empty space at the end of the
          // array, if this were the last line to be added.
          showInstructions = expand(showInstructions, showInstructions.length + 1);
          
          // Storing the contents of this line in the showInstructions array, at the last
          // available index. This way, no matter how many lines are added, there will never
          // be an empty space left at the end of the array
          showInstructions[showInstructions.length - 1] = line.getContent();
        }
      }
    }

    // Setting the x position of all text elements to be centered horizontally,
    // as they are being drawn from CENTER
    x = width / 2;
    
    // Working out how much spacing needs to be between each of the lines,
    // based on how many there are, so that they fill the height of the screen
    spacing = height / (showInstructions.length + 1);
  }  

  public void show() {
    background(0);
    fill(255);
    
    textSize(width/45);
    textAlign(CENTER);

    // Looping thorugh all the instruction lines that need to be shown for this
    // sketch, and adding them to the screen, setting their y to increment each
    // time, by multiplying the spacing (as defined above) by their index number
    // plus 1 i.e. first line will be at spacing * 1, second line will be at
    // spacing * 2 and so on
    for (int i = 0; i < showInstructions.length; i++)
    {
      text(showInstructions[i], x, spacing * (i + 1));
    }
  }
}

