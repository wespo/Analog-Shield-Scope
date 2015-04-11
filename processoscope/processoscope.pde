/* The Processing code */
import processing.serial.*;
import controlP5.*;


int SPEED = 1843200;
ControlP5 cp5;
RadioButton r;
RadioButton t_chan_sel;
CheckBox channelCheckbox;
CheckBox sincInterp;
Button recorderMode;
Button recordButton;
Button trigDir;
Button periodCalc;
Slider holdoff;
Slider s;
Slider t;
Slider b;
Slider o;

PrintWriter OUTPUT;

Serial port;  // Create object from Serial class
int val;      // Data received from the serial port
int chan;

boolean trigger_direction = true;

int num_channels = 1;
int sample_period = 100;
float zoom;
int offset = 400;
int window_width = 1200;
int window_height = 700;

int scope_width = 800;
int scope_height = 600;
int offset_x = (window_width - scope_width) / 2;
int offset_y = (window_height - scope_height) / 2;
int vcenter = offset_y+scope_height/2;
int offset_trace_y[];
int offset_channel_y = 0;
int trig_offset = 100;
int trig_channel = 0;
int scale_fac = 100;
int brightness = 30*255/100;
float channel_time = 400;
int k = 0;
float period[];

boolean acquiring = false;


// an event from slider sliderA will change the value of textfield textA here
public void Trigger(int theValue) {
  trig_offset = -theValue;
}

public void Scale(int theValue) {
  scale_fac = theValue;
}

public void Offset(int theValue) {
  offset_trace_y[offset_channel_y] = -theValue + vcenter;
}

public void Brightness(int theValue) {
  brightness = 255/100*theValue;
}

int[][] values;

Textlabel myTextlabelA;
Textlabel myTextlabelB;
Textlabel LogoText;
Textlabel SerialItems;
Textlabel TriggeredLight;
DropdownList d2;
void customize(DropdownList ddl) {
  // a convenience function to customize a DropdownList
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(20);
  ddl.setBarHeight(15);
  ddl.captionLabel().set("Serial Channel");
  ddl.captionLabel().style().marginTop = 3;
  ddl.captionLabel().style().marginLeft = 3;
  ddl.valueLabel().style().marginTop = 3;
  String[] serialList = Serial.list();
  for (int i=0;i<serialList.length;i++) {
    ddl.addItem(serialList[i], i);
  }
  //ddl.scroll(0);
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255, 128));
}
float sinc_vector[];

void setup() 
{
  sinc_vector = sincVector(scope_width, 1);
  size(window_width, window_height);
  // Open the port that the board is connected to and use the same speed (9600 bps)
  //println(Serial.list());
  port = new Serial(this, Serial.list()[Serial.list().length-1], SPEED);
  values = new int[4][scope_width * 2];
  period = new float[5];
  offset_trace_y =new int[4];
  offset_trace_y[0] = vcenter;
  offset_trace_y[1] = vcenter;
  offset_trace_y[2] = vcenter;
  offset_trace_y[3] = vcenter;
  zoom = 1.0f;
  smooth();
  cp5 = new ControlP5(this);

  // create a slider
  // parameters:
  // name, minValue, maxValue, defaultValue, x, y, width, height


  
  //screenshot
  cp5.addButton("snapshot")
     .setLabel("Take A Snapshot")
     .setPosition(20,250)
     .setSize(75,20)
     ;
  
  recordButton = cp5.addButton("dataRecord")
     .setLabel("Capture Data")
     .setPosition(20,275)
     .setSize(75,20)
     .setSwitch(true)
     ;
     
  recorderMode = cp5.addButton("recorderMode")
     .setLabel("Raw Signal")
     .setPosition(100,275)
     .setSize(65,20)
     .setSwitch(true)
     .setOn()
     ;
     //recorderMode.isOn()
  
  //Trigger
  t = cp5.addSlider("Trigger", -scope_height/2, scope_height/2, -trig_offset, offset_x - 30, offset_y, 25, scope_height);
  controlP5.Label label = t.valueLabel();
  label.style().marginTop = -10;
  label.style().marginLeft = -25;

  trigDir = cp5.addButton("trigDir")
     .setLabel("Trigger\nPos")
     .setPosition(112,170)
     .setSize(50,25)
     .setSwitch(true)
     ;
     
   trigDir.captionLabel().style().moveMargin(-4, 0, 0, 0);

  TriggeredLight = cp5.addTextlabel("TrigLight")
    .setText("Triggered")
    .setPosition(25, offset_y + 90)
    .setSize(50, 20);

  t_chan_sel = cp5.addRadioButton("t_ch_sel")
    .setPosition(80,offset_y + 22)
      .setSize(30, 20)
        .setColorForeground(color(120))
          .setColorActive(color(255))
            .setColorLabel(color(255))
              .setItemsPerRow(1)
                .setSpacingColumn(50)
                  .addItem("Trigger 0", 0)
                    .addItem("Trigger 1", 1)
                      .addItem("Trigger 2", 2)
                        .addItem("Trigger 3", 3)
                          .activate(0)
                            ;

  for (Toggle togg2:t_chan_sel.getItems()) {
    togg2.captionLabel().setColorBackground(color(255, 80));
    togg2.captionLabel().style().moveMargin(-7, 0, 0, -3);
    togg2.captionLabel().style().movePadding(7, 0, 0, 3);
    togg2.captionLabel().style().backgroundWidth = 48;
    togg2.captionLabel().style().backgroundHeight = 13;
  }
  //Scale
  s = cp5.addSlider("Scale", 1000, 10, scale_fac, offset_x + scope_width + 35, offset_y, 25, scope_height);
  label = s.valueLabel();
  label.style().marginTop = -10;
  label.style().marginLeft = -25;

  //Brightness
  b = cp5.addSlider("Brightness", 0, 100, 30, 24, offset_y+62, 50, 10);
  label = b.captionLabel();
  label.style().marginTop = 10;//b.height;
  label.style().marginLeft = -53;//-b.width;

  holdoff = cp5.addSlider("Holdoff", 0, scope_width, 0, offset_x+3, offset_y+scope_height+5, scope_width-6, 20);
  label = holdoff.captionLabel();
  label.style().marginTop = 15;//b.height;
  label.style().marginLeft = -scope_width+3;//-b.width;


  //Logo
  LogoText = cp5.addTextlabel("label2")
    .setText("Process-o-scope")
      .setPosition(offset_x, offset_y-35)
        .setColorValue(0xffffffff)
          .setFont(createFont("Futura", 24))
            ;

  //frequency measurement
  myTextlabelA = cp5.addTextlabel("label")
    .setText("Period:")
      .setPosition(20, offset_y + 20)
        .setColorValue(0xffffffff)
          ;
  myTextlabelB = cp5.addTextlabel("label3")
    .setText("Frequency:")
      .setPosition(20, offset_y + 40)
        .setColorValue(0xffffffff)
          ;
  periodCalc = cp5.addButton("periodCalcDisp")
     .setLabel("Show Period")
     .setPosition(100,250)
     .setSize(65,20)
     .setSwitch(true)
     ;


  //channel toggles
  channelCheckbox = cp5.addCheckBox("checkBox")
                .setPosition(20, 170)
                .setColorForeground(color(120))
                .setColorActive(color(255))
                .setColorLabel(color(255))
                .setSize(10, 10)
                .setItemsPerRow(1)
                .setSpacingColumn(30)
                .setSpacingRow(5)
                .addItem("Show Channel 0", 0)
                .addItem("Show Channel 1", 1)
                .addItem("Show Channel 2", 2)
                .addItem("Show Channel 3", 3)
                .activate(0)
                ;
  
  //sinc reconstruction
  sincInterp = cp5.addCheckBox("checkBox2")
                .setPosition(20, 230)
                .setColorForeground(color(120))
                .setColorActive(color(255))
                .setColorLabel(color(255))
                .setSize(10, 10)
                .setItemsPerRow(1)
                .setSpacingColumn(30)
                .setSpacingRow(5)
                .addItem("Enable sinc reconstruction", 0)
                .activate(0)
                ;
  
  
  //Offset
  o = cp5.addSlider("Offset", -scope_height/2, scope_height/2, 0, offset_x+scope_width + 5, offset_y, 25, scope_height);
  label = o.valueLabel();
  label.style().marginTop = -10;
  label.style().marginLeft = -25;

  r = cp5.addRadioButton("radioButton")
    .setPosition(offset_x+scope_width + 65, offset_y)
      .setSize(40, 20)
        .setColorForeground(color(120))
          .setColorActive(color(255))
            .setColorLabel(color(255))
              .setItemsPerRow(1)
                .setSpacingColumn(50)
                  .addItem("Channel 0", 0)
                    .addItem("Channel 1", 1)
                      .addItem("Channel 2", 2)
                        .addItem("Channel 3", 3)
                          .activate(0)
                            ;

  for (Toggle togg:r.getItems()) {
    togg.captionLabel().setColorBackground(color(255, 80));
    togg.captionLabel().style().moveMargin(-7, 0, 0, -3);
    togg.captionLabel().style().movePadding(7, 0, 0, 3);
    togg.captionLabel().style().backgroundWidth = 45;
    togg.captionLabel().style().backgroundHeight = 13;
  }
  
  //Select Serial port
  d2 = cp5.addDropdownList("Serial Channel")
          .setPosition(22, offset_y+18)
          .setSize(140,200)
          ;
  
  customize(d2); // customize the second list
}

int twosFix(int value) //lazy man's fix for 32 bit integer conversion.
{
  if (value > 32768) 
  {
    value = value - 65536;
  }
  //println(value);
  return value;
}

int getY(int val) {
  return (int)(val);// * scope_height + vcenter);
}

void getValue() {
  int value = -1;
  int channel = 0;
  while (port.available () >= 3) {
    channel = port.read();
    if ((channel == 0)|| (channel == 1) || (channel == 2) || (channel == 3)){
      //channel = port.read();
      //println(channel);
      value = (port.read() << 8) | (port.read());
      value = twosFix(value);
      if (channel < 0 || channel > 3)
      {
        channel = -1;
      }
      else
      {
        pushValue(value, channel);
      }
    }
  }
}

void pushValue(int value, int channel) {
  //  for (int i=0; i<scope_width-1; i++)
  //  {  
  //    values[channel][i] = values[channel][i+1];
  //  }
  if(acquiring && recorderMode.isOn())
  {
    OUTPUT.println(channel + "," + value);
  }
  value = value / scale_fac;
  values[channel] = subset(values[channel], 1); 
  values[channel] = append(values[channel], value);
  //println(value);
}

void drawUI()
{
  stroke(255);
  background(155);
  fill(0);
  rect(offset_x, offset_y, scope_width, scope_height, 4);
}

int findFirst(int[] passedArray, int threshold, int index, boolean direction)
{
  if (direction)
  {
    
    while((passedArray[index] < threshold) && (index < passedArray.length - 1))
    {
          index++;
    }
    if (index == passedArray.length)
    {
      return -1;
    }
    for (int i = index; i < passedArray.length/2; i++)
    {
      if (passedArray[i] < threshold)
      {
        return i;
      }
    }
    return -1;
  }
  else
  {
    while((passedArray[index] > threshold) && (index < passedArray.length - 1))
    {
          index++;
    }
    if (index == passedArray.length)
    {
      return -1;
    }
    for (int i = index; i < passedArray.length/2; i++)
    {
      if (passedArray[i] > threshold)
      {
        return i;
      }
    }
    return -1;
  }
}
float average(float[] data)
{
  float sum = 0;
  for(int i = 0; i < data.length; i++)
  {
    sum = sum + data[i];
  }
  return sum / data.length;
}
void drawLines() {
  drawUI();
  for (int channel = 0; channel < 4; channel++)
  {
    if(int(average(float(values[channel]))*1000000) == 0)
    {
      k = 0;
      continue;
    }
  
    stroke(255);
    strokeWeight(3);
    line(offset_x+1, vcenter, offset_x + scope_width-1, vcenter);
    strokeWeight(1);
    line(offset_x+1, vcenter+trig_offset, offset_x + scope_width-1, vcenter+trig_offset);

    int scope_scale = (int) (scope_width / zoom);
    
    //(scope_width-1) / (scope_scale-1)
    int[] interp = values[channel];
    
    int limit = scope_width;
    int scale = 1;
    if(sincInterp.getArrayValue(0) == 1)
    {
      interp = int(paddedSignal(float(interp), int(2 * scope_width * zoom)));
      interp = int(convolve(float(interp), sinc_vector));
      interp = subset(interp, interp.length/4, interp.length/2);
    }
    else
    {
      scale = int(zoom);
      limit = int(scope_width / zoom);      
    }
    
    //if this is the trigger channel, set triggering offset!
    if(trig_channel == channel)
    {
      k = findFirst(interp, trig_offset-offset_trace_y[trig_channel]+vcenter, 0, trigger_direction);
      if(k >= 0)
      {
          isTriggered(true);
      }
      else
      {
        k = 0;
        isTriggered(false);
      }
    }
    
    
    channel_time = num_channels * sample_period / zoom;
    if(int(holdoff.getValue()) + k < (interp.length - limit))
    {
      k = int(holdoff.getValue()) + k;
    } 
    //println(k);
    if(channel == trig_channel)
    {
      ellipseMode(CENTER);
      stroke(255);
      int period_st = findFirst(interp, trig_offset-offset_trace_y[trig_channel]+vcenter, 0, trigger_direction);
      int period_end = findFirst(interp, trig_offset-offset_trace_y[trig_channel]+vcenter, period_st+1, trigger_direction);
      //print(period_end+", "+period_st+"\n");
      if(periodCalc.isOn() && period_st > 0 && period_end > 0)
      {
        ellipse(offset_x+period_st, interp[period_st]+vcenter, 4,4);
        ellipse(offset_x+period_end, interp[period_end]+vcenter, 4,4);
        line(offset_x+period_st, interp[period_st]+vcenter,offset_x+period_end, interp[period_end]+vcenter);
      }
      if(offset_x+period_st == -1 && period_end == -1)
      {
        myTextlabelA.setText("Period:\ninf ms");
        myTextlabelB.setText("Frequency:\n0 Hz");
      }
      else
      {
        period = subset(period, 1); 
        period = append(period, (period_end - (period_st - 1))*channel_time * pow(.1, 6));
        float periodAvg = average(period);
        float frequency = 1/ periodAvg;
        myTextlabelA.setText("Period:\n" + int(periodAvg*1000) + "ms");
        myTextlabelB.setText("Frequency:\n" + int(frequency) + "Hz");
      }
    }
    if(channelCheckbox.getArrayValue(channel) == 0)
    {
      continue;
    }
    
    setColor(channel);
    int x0 = offset_x;
    int y0 = getY(interp[k]) + offset_trace_y[channel];
    //println(k);
    
    
    
    for (int i=1; i<limit; i++) {
      if(acquiring && !recorderMode.isOn())
      {
        OUTPUT.println(channel + "," + y0);
      }
      k++;
      int x1 = i*scale + offset_x;
      int y1 = getY(interp[k]) + offset_trace_y[channel];
      y0 = constrain(y0, offset_y, offset_y+scope_height);
      y1 = constrain(y1, offset_y, offset_y+scope_height);
      line(x0, y0, x1, y1);
      x0 = x1;
      y0 = y1;
    }
    if(acquiring && !recorderMode.isOn())
    {
      OUTPUT.println(channel + "," + y0);
    }
  }
  drawGrid();
  //drawInterp(sinc_vector);
  //drawInterp(paddedSignal(float(values[0]), scope_width*2));  
}

void trigDir()
{
  trigger_direction = !trigger_direction;
  if(trigger_direction)
  {
    trigDir.setLabel("Trigger\nPos");
  }
  else
  {
    trigDir.setLabel("Trigger\nNeg");
  }
}
void setColor(int channel)
{
  switch(channel) {
    case 0:
      stroke(0, 255, 0);
      break;
    case 1:
      stroke(255, 0, 0);
      break;
    case 2:
      stroke(0, 0, 255);
      break;
    case 3:
      stroke(255, 0, 255);
      break;
    }
}
void drawGrid()
{
  stroke(255, brightness);
  int numlines_x = 10;
  int numlines_y = 10;
  //vertical lines
  for (int i = 1; i < numlines_x; i++)
  {
    line(offset_x+i*scope_width/numlines_x, offset_y, offset_x+i*scope_width/numlines_x, offset_y+scope_height);
  }
  //horizontal lines
  for (int i = 1; i < numlines_x; i++)
  {
    line(offset_x, offset_y+i*scope_height/numlines_y, offset_x+scope_width, offset_y+i*scope_height/numlines_y);
  }
}

void isTriggered(boolean trig_on)
{
  if(trig_on == true)
  {
    stroke(255);
    fill(255,255,0);
  }
  else
  {
    stroke(255);
    fill(120);
  }
  rect(24, offset_y+86, 50, 20, 4);
}

void snapshot()
{
  println("snap.");
  PImage cp = get (offset_x, offset_y, scope_width, scope_height);
  cp.save("processocope_"+year()+"_"+month()+"_"+day()+"_"+hour()+minute()+second()+".png"); 
}

void recorderMode()
{
  if(recordButton.isOn())
  {
    //stopRecording();  
    recordButton.setOff();
  }
}

void keyReleased() {
  switch (key) {
  case '=':
    zoom *= 2.0f;
    println(zoom);
    if ( (int) (scope_width / zoom) <= 1 )
      zoom /= 2.0f;
    break;
  case '-':
    zoom /= 2.0f;
    if (zoom < 1.0f)
      zoom *= 2.0f;
    break;
  }
  sinc_vector = sincVector(int(4 * scope_width), int(zoom));
}

void dataRecord()
{
  if(recordButton.isOn())
  {
    selectOutput("Select a file to write to:", "fileSelected");
  }
  else
  {
    stopRecording();
  }
}

void startRecording(String filePath)
{
  OUTPUT = createWriter(filePath + ".csv");
  OUTPUT.println("Channel,Value");
  println(filePath);
  acquiring = true;
}

void stopRecording()
{
  acquiring = false;
  OUTPUT.flush();
  OUTPUT.close();
  println("points have been exported");
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    startRecording(selection.getAbsolutePath());
  }
}

void draw()
{
  getValue();
  if ((val != -1) && (chan != -1)) {
    drawLines();
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(r)) {
    offset_channel_y = (int)theEvent.group().value();
    o.setValue(vcenter - offset_trace_y[offset_channel_y]);
  }
  if(theEvent.isFrom(d2)){
    port = new Serial(this, Serial.list()[(int)d2.value()], SPEED);
  }
  if (theEvent.isFrom(t_chan_sel)) {
    k = 0;
    trig_channel = (int)theEvent.group().value();
    k = 0;
  }
}

float[] paddedSignal(float[] signal, int sigLength)
{
  float[] resultSignal = new float[4*scope_width]; //sigLength
  //for(int i = signal.length - signal.length/int(zoom); i < signal.length; i++)
  int i = 0;
  while((i < signal.length) && (i * sigLength / signal.length < (4 * scope_width)))
  {
    resultSignal[i * sigLength / signal.length] = signal[i];
   i++;
  }
  //print(resultSignal);
  return resultSignal;
}


float[] sincVector(int sincLength, int zoom)
{
  float[] resultVector = new float[sincLength];
  for(int i = 0; i < sincLength; i++)
  {
    float scale = (1/float(zoom));
    //println(scale);
    float sample = -sinc((i-sincLength/2)*scale);//(i - sincLength/2) * 1/(400 * pow(10,-6)));
    resultVector[i] = sample;
  }
  
  return resultVector;
}

void drawInterp(float[] sincStream)
{
  stroke(255,128,64);
  //float[] sincStream = sinc_vector; 
  int y0 = int(sincStream[sincStream.length/2-scope_width/2] * scope_height/2);
  for (int i=1; i<scope_width; i++) {
    int y1 = int(sincStream[sincStream.length/2-scope_width/2 + i] * scope_height/2);
    line(offset_x+i - 1, y0+vcenter, offset_x+i, y1+vcenter);
    y0 = y1;
  }
}
float[] convolve(float[] signal, float[] filter)
{
  float[] result = new float[signal.length + filter.length - 1];
  for(int outputIndex = 0; outputIndex < result.length; outputIndex++)
  {
    int signalIndex = outputIndex - filter.length + 1;
    float sum = 0;
    for(int filterIndex = 0; filterIndex < filter.length; filterIndex++)
    {
      if( (signalIndex+filterIndex) >= 0  &&  (signalIndex+filterIndex) < signal.length ) //TODO: FIND A WAY TO REMOVE THIS
      {
          result[outputIndex] += filter[filterIndex]*signal[signalIndex+filterIndex];
      }
    }
  }
  return result;
}

float sinc(float x)
{
  if(x==0)
  {
      return 1;
  }
  float y = sin(PI * x) / (PI * x);
  return y;
}
