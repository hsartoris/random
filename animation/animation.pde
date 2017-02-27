class Point {
  final float INIT_VEL = .7;
  final float VEL_RANGE = .3;
  final int INIT_DRAWTIME = 150;
  final int DRAWTIME_VARIANCE = 0;
  final int BRIGHTNESS_FALLOFF = 20;
  final int DISTANCE_LIMIT = 250;
  
  int lineSpeed = 5;
  
  int brightness;
  
  float dx;
  float dy;
  
  float x;
  float y;
  
  boolean draw;
  boolean drawTo;
  int drawCounter;
  
  ArrayList<Point> friends;
  
  Point[] points = null;
  
  public Point() {
    x = random(width);
    y = random(height);
    draw = false;
    drawTo = false;
    drawCounter = 0;
    
    float velocity = INIT_VEL + random(VEL_RANGE * 2) - VEL_RANGE;
    float heading = random(2*PI);
    dx = sin(heading) * velocity;
    dy = cos(heading) * velocity;
    
    friends = new ArrayList<Point>();
    
    brightness = 255;
  }
  
  void update() { // returns true if still
    x += dx;
    y += dy;
    if (!draw && !drawTo) {
      if (x > width) x -= width;
      else if (x < 0) x += width;
      if (y > height) y -= height;
      else if (y < 0) y += height;
    }
    if (drawCounter > 0) drawCounter--;
    else if (draw) {
      draw = false;
      for (Point p : friends) p.drawToToggle(false);
      friends.clear();
    }
    
    if (drawCounter == BRIGHTNESS_FALLOFF) {
      println("hit");
        for (Point p : friends) p.startDrawing(linesPer, points); //  BROKEN AS HELL
    } else if (drawCounter < BRIGHTNESS_FALLOFF) {
      //println("drawcounter < brightness falloff");
      brightness = (int)(255 * (double)drawCounter/BRIGHTNESS_FALLOFF);
    } else if (INIT_DRAWTIME - drawCounter < BRIGHTNESS_FALLOFF) {
     
      brightness = (int)(255 * ((INIT_DRAWTIME - (double)drawCounter)/BRIGHTNESS_FALLOFF));
      
    }
    
    if (friends.size() > 0 && Math.random() < drawChance) friends.get((int)random(friends.size())).startDrawing(linesPer, points);
    
    if (draw) drawLines();
  }
  
  void startDrawing(int n, Point[] ps) {
    if (draw) return;
    if (points == null) points = ps;
    brightness = 255;
    draw = true;
    drawCounter = INIT_DRAWTIME + (int)random(DRAWTIME_VARIANCE * 2) - DRAWTIME_VARIANCE;
    makeFriends(n);
  }
  
  void makeFriends(int n) {
    int count = 0;
    Point[] temp = new Point[points.length];
    for (Point p : points) {
      if (acceptable(p)) {
        temp[count] = p;
        count++;
      }
    }
    if (n > count) n = count;
    n = (int)random(n);
    int ptIdx;
    for (int i = 0; i < n; i++) {
      ptIdx = (int)random(count);
      friends.add(temp[ptIdx]);
      temp[ptIdx].drawToToggle(true);
      //if (Math.random() < growChance) temp[ptIdx].startDrawing(n, points);
    }
  }
  
  void drawToToggle(boolean target) {
    drawTo = target;
  }
  
  void drawToToggle() {
    drawToToggle(!drawTo);
  }
  
  boolean acceptable(Point p) {
    if (this == p) return false;
    if (Math.sqrt(pow(x - p.x,2) + pow(y - p.y,2)) > DISTANCE_LIMIT) { return false; }
    
    
    
    //println("got one");
    return true;
  }
  
  
  
  void drawLines() {
    if (brightness > 0) {
      strokeWeight(2);
      stroke(brightness);
      for (Point p : friends) line(x, y, p.x, p.y);
    }
  }
  
  int distanceFrom(int x, int y) {
    return (int)Math.sqrt(pow(this.x - x, 2) + pow(this.y - y, 2));
  }
}

int numPoints = 75;
Point[] points;
int lineThickness = 5;
double drawChance = .25;
double growChance = 1;
double spawnChance = .1;
boolean debug = false;
int linesPer = 3;


void setup() {
  points = new Point[numPoints];
  for (int i = 0; i < points.length; i++) {
    points[i] = new Point();
  }
  
  for (Point p : points) if (Math.random() < drawChance) p.startDrawing(linesPer, points);
  
  size(1024,768);
}



void draw() {
  if (mousePressed) {
    int mouseRad = 25;
    for (Point p : points) {
      if(p.distanceFrom(mouseX, mouseY) < mouseRad) {
        p.startDrawing(linesPer, points);
        break;
      }
    }
    
    for (Point p : points) {
      if (Math.random() < spawnChance) p.startDrawing(linesPer, points);
    }
  }
  
  background(0);
  stroke(255);
  for (Point p : points) {
    p.update();
    /*
    if (p.draw) ellipse(p.x, p.y, lineThickness, lineThickness);
    else if (debug) {
      stroke(color(255,0,0));
      ellipse(p.x, p.y, lineThickness, lineThickness);
    }
    */
  }
}