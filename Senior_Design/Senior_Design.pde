import controlP5.*; //import ControlP5 library
import processing.serial.*;

Serial port;

ControlP5 cp5_main; //create ControlP5 object
PFont font; // Create font object that's the font for most of the objects in the UI
PFont title_font; // Create font for the title
Textarea schedule_area; // Schedule area where we display the routine rotations and pauses
StringList schedule_list; // StringList where we store our routines
String schedule_str; // String that we display in the schedule_area
IntList schedule_norm; // IntList that has the normalized values of StringList
String dir = "r"; // Variablet to control direction for the turntable


void setup(){ // Setup function, similar to one in Arduino

  size(800, 800);    // Window size, (width, height)
  
  //printArray(Serial.list());   //prints all available serial ports
  
  // Instantiating the StringList and IntList
  schedule_list = new StringList(); 
  schedule_norm = new IntList();
  
  // Creating some arrays that we use in filling in our dropdown selection areas
  String[] rotation_type = new String[2];
  rotation_type[0] = "Degrees";
  rotation_type[1] = "Radians";
  String[] pause_type = new String[2];
  pause_type[0] = "Minutes";
  pause_type[1] = "Seconds";
  
  /* Serial port where the device is connected too, uncomment line above
   * printArray(Serial.list()); to see where the device is connected. When
   * testing, comment out this line. 
  */
  //port = new Serial(this, "/dev/cu.usbserial-A9083WZZ", 115200);
  
  // Instantiating fonts and the controlP5 object
  cp5_main = new ControlP5(this);
  font = createFont("Arial", 12);
  title_font = createFont("Arial", 30);
  
  //1600 steps = 360 degree
 
  // Save button
  cp5_main.addButton("save")
    .setPosition(290,100) // (x,y)
    .setSize(60, 40)      
    .setFont(font)
    .setColorBackground(color(0,145,0));  

  // Load button
  cp5_main.addButton("load")
    .setPosition(290, 150) // (x,y)
    .setSize(60, 40)
    .setFont(font);

  // Rotate button
  cp5_main.addButton("rotate") 
    .setPosition(650, 200)  // (x,y)
    .setSize(60, 40)      
    .setFont(font);

  // Add button
  cp5_main.addButton("add")
    .setPosition(650, 245) // (x,y)
    .setSize(60, 40)      
    .setFont(font);

  // Clear button
  cp5_main.addButton("clear")
    .setPosition(50, 610) // (x,y)
    .setSize(60, 40)      
    .setFont(font)
    .setColorBackground(color(255,0,0));

  // Running a schedule button
  cp5_main.addButton("run_schedule")
    .setPosition(400, 400) // (x,y)
    .setSize(200, 100)      
    .setFont(font)
    .setColorBackground(color(0,0,255))
    .setCaptionLabel("Run Schedule");
  
  // Toggle button
  cp5_main.addButton("toggle")
     .setPosition(600,25) // (x,y)
     .setSize(100,50)
     .setFont(font)
     .setColorBackground(color(0,0,255))
     .setCaptionLabel("CCW");
  
  // Select menu for the rotation units
  cp5_main.addScrollableList("rotation_type")
   .setPosition(400, 100) // (x,y)
   .setSize(100, 100)
   .setBarHeight(20)
   .setItemHeight(20)
   .addItems(rotation_type)
   .setType(ScrollableList.DROPDOWN);
  
  // Select menu for the pause units
  cp5_main.addScrollableList("pause_type")
   .setPosition(510, 100) // (x,y)
   .setSize(100, 100)
   .setBarHeight(20)
   .setItemHeight(20)
   .addItems(pause_type)
   .setDefaultValue(1.0)
   .setType(ScrollableList.DROPDOWN);
  
  schedule_area = cp5_main.addTextarea("Scheduled rotation")
    .setPosition(50,200) // (x,y)
    .setSize(300,400)
    .setFont(createFont("arial",12))
    .setLineHeight(14)
    .setColor(color(255,255,255))
    .setColorBackground(color(255,100))
    .setColorForeground(color(255,100));
  
  // Rotational input field
  cp5_main.addTextfield("input")
    .setPosition(400,200) // (x,y)
    .setSize(200,40)
    .setFont(font)
     .setFocus(true)
     .setColor(color(255,0,0));
   
  // Schedule name field 
  cp5_main.addTextfield("schedule_name")
    .setPosition(50,100) // (x,y)
    .setSize(200,40)
    .setFont(font)
    .setColor(color(255,0,0))
    .setCaptionLabel("Schedule Name");
   
  // Label to remind users to set their units!
  cp5_main.addTextlabel("label")
    .setText("You forgot to set your UNITS")
    .setPosition(400,510) // (x,y)
    .setColor(color(169,169,169))
    .setFont(createFont("Arial",15));
                        
  schedule_area.setText("Currently empty, when you add rotations to schedule"
                  + " it will show up here"
  );
}

void draw(){

  background(169, 169, 169);
  fill(0, 0, 0);              
  textFont(title_font);
  text("Human Turntable", 275, 50); 
  
  // Testing code to see what value we sent through Serial
  /*
  String val = port.readStringUntil('\n');
  if(val != null){
    println(val + "\n");
  }*/
}

/*
 * Description: Function that gets called when the add button is pressed. It'll add a value to the schedule display area
 * as well as the StringList and IntList we created earlier. 
 * Return: void
 * Params: N/A
 */
void add(){
  String value_to_add;
  int norm_value_add;
  if(cp5_main.get(ScrollableList.class, "rotation_type").getLabel() == "rotation_type" || cp5_main.get(ScrollableList.class, "pause_type").getLabel() == "pause_type"){
    cp5_main.get(Textlabel.class, "label").setColor(color(255,0,0));
    return;
  }
  
  // Check if the size is a even number or not, since on even numbers, we store the rotation and on odd number we store pauses. Since we shouldn't ever need more that one rotation
  // consecutively, we do it this way. 
  if(schedule_list.size() % 2 == 0){
    value_to_add = cp5_main.get(Textfield.class,"input").getText() + " " + cp5_main.get(ScrollableList.class, "rotation_type").getLabel();
    
    // Converts the value into steps aka "normalizing" it
    norm_value_add = int(convert_to_steps(int(get_input("input")), cp5_main.get(ScrollableList.class, "rotation_type").getLabel()));
  }else{
    value_to_add = cp5_main.get(Textfield.class,"input").getText() + " " + cp5_main.get(ScrollableList.class, "pause_type").getLabel();
    
    // Converts the value into ms aka "normalizing" it
    norm_value_add = int(convert_to_ms(int(get_input("input")), cp5_main.get(ScrollableList.class, "pause_type").getLabel()));
  }
  schedule_norm.append(norm_value_add);
  print(schedule_norm);
  schedule_list.append(value_to_add);
  String schedule = create_schedule_str(schedule_list);
  schedule_area.setText(schedule);
  clearTextField("input");
  cp5_main.get(Textlabel.class, "label").setColor(color(169,169,169));
}

/*
 * Description: Function that gets called when the save button is pressed. This button will save the schedule locally, with whatever name you have put in the input box.
 * File is saved at wherever you ran this application from
 * Return: void
 * Params: N/A
 */
void save(){
  String[] schedule_arr = schedule_list.array();
  String file_name = get_input("schedule_name");
  if(file_name == null){
    saveStrings("default.txt", schedule_arr);
  }else{
    saveStrings(file_name, schedule_arr); 
  }
  clearTextField("schedule_name");
}

/*
 * Description: Function that gets called when the load button is pressed. It will read in the data from
 * the file you named and load all its values into the schedule area.
 * Return: void
 * Params: N/A
 */
void load(){
  // Loading the text from the save file
  String[] loaded_schedule = loadStrings(cp5_main.get(Textfield.class, "schedule_name").getText());
  // Connecting everything with a newline char
  String schedule_string = join(loaded_schedule, "\n");
  int norm_to_add;
  
  // Clear all of our global lists to make room for the newly loaded schedule
  schedule_list.clear();
  schedule_norm.clear();
  
  // Creating data structure for the schedule
  for(int i = 0; i < loaded_schedule.length; i++){
    schedule_list.append(loaded_schedule[i]);
  }
  
  // 2-D array to allow us to get both the unit and the actual value
  String[][] temp = new String[loaded_schedule.length][2];
  
  for(int j = 0; j < loaded_schedule.length;j++){
    temp[j] = split(loaded_schedule[j]," ");
  }
  
  // Setting the units in the dropdown menu to same one as loaded schedule
  cp5_main.get(ScrollableList.class, "rotation_type").setLabel(temp[0][1]);
  cp5_main.get(ScrollableList.class, "pause_type").setLabel(temp[1][1]);
  
  // Load the units and actual values into our global data structures
  // and convert everything to either ms or steps
  for(int k = 0; k < loaded_schedule.length; k++){
    int convert = int(temp[k][0]);
    String type = temp[k][1];
    type = type.trim();
    print(type + "\n");
    if(k % 2 == 0){
      norm_to_add = convert_to_steps(convert,type);
    }else{
      norm_to_add = convert_to_ms(convert, type);
    }
    schedule_norm.append(norm_to_add);
  }
  
  schedule_area.setText(schedule_string);
  clearTextField("schedule_name");
}

/*
 * Description: Converts the schedule from a list of values to something that we can
 * display in the schedule area.
 * Return: String
 * Params: StringList schedule
 */
String create_schedule_str(StringList schedule){
  int list_size = schedule.size();
  schedule_str = "";
  for(int i = 0; i < list_size; i++){
    schedule_str += schedule.get(i);
    schedule_str += "\n";
  }
  return schedule_str;
}

/*
 * Description: Function that gets called when the rotate button is pressed. Converts the values to steps
 * and then writes that value through the serial port
 * Return: void
 * Params: N/A
 */
void rotate(){
  int temp = convert_to_steps(int(get_input("input")),cp5_main.get(ScrollableList.class, "rotation_type").getLabel());
  cp5_main.get(Textfield.class, "input").clear();
  
  // Arduino is expecting 4 bytes so if the rotation value isn't 4 bytes, we have to 0 extend it. 
  String test = nf(temp, 4);
  port.write(test);
  // Testing code to see what value we sent through Serial
  /*
  String val = port.readStringUntil('\n');
  if(val != null){
    println(val + "\n");
  }*/
  
}

/*
 * Description: Used to convert the degrees or radians into steps since thats what our motor uses.
 There is some accuracy issues here as we have to truncate the decimal part of the function.
 However, this shouldn't be as big of an issue if you increase the steps per rotation for the motor
 * Return: int(steps) - integer version of the steps
 * Params: input - the rotation value in the input field
           type - radians/degrees
 */
int convert_to_steps(int input, String type){
 float steps = 0.0;
 if(type.equals("Radians")){
   steps = 254.65 * float(input);
 }else if(type.equals("Degrees")){
   steps = 4.4445 * float(input);
 }
 return int(steps);
}

/*
 * Description: Convert the pause into ms since that's what our delay function takes.  
 * Return: delay - delay in ms instead of seconds or minutes
 * Params: input - the rotation value in the input field
           type - seconds/minutes
 */
int convert_to_ms(int pause, String type){
  int delay = 0;
  //print(type + "\n");
  if(type.equals("Seconds")){
    delay = pause * 1000;
  }else if(type.equals("Minutes")){
    delay = pause * 60 * 1000;
  }
  //print(delay);
  return delay;
}

/*
 * Description: Funcition that gets called when the run schedule button is pressed.  
 * Return: delay - delay in ms instead of seconds or minutes
 * Params: input - the rotation value in the input field
           type - seconds/minutes
 */
void run_schedule(){
  int[] schedule_arr = schedule_norm.array();
  String temp;
  // Iterates through and writes either a rotation through the serial port or delays 
  // for a little bit.
  for(int i = 0; i < schedule_arr.length; i++){
    temp = nf(schedule_arr[i],4);
    if(i % 2 == 0){
      port.write(temp);
    }else{
      delay(schedule_arr[i]);
    }
  }
}

void clearTextField(String fieldname){
  cp5_main.get(Textfield.class, fieldname).clear();
}

String get_input(String fieldname){
   return cp5_main.get(Textfield.class, fieldname).getText(); 
}

/*
 * Description: Function that gets called when we wish to switch the rotation direction.
 * Sets the dir variable to l or r and we write the direction to the serial port
 * Return: N/A
 * Params: N/A
 */
void toggle(){
  if(dir.equals("r")){
    cp5_main.get(Button.class, "toggle").setLabel("CW");
    dir = "l";
  }else if(dir.equals("l")){
    cp5_main.get(Button.class, "toggle").setLabel("CCW");
    dir = "r";
  }
  port.write(dir);
}

/*
 * Description: Clear everything from our structures
 * Return: N/A
 * Params: N/A
 */
void clear(){
  schedule_area.setText("Your scheduled rotations and pauses have been cleared!");
  schedule_list.clear();
  schedule_norm.clear();
}
