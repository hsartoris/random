class Dot {
  Dot(float x, float y, float dV, float h) {
    this.x = x;
    this.y = y;
    this.dV = dV;
    this.heading = h;
    this.hue = random(255);
  }
  float x;
  float y;
  float dV;
  float heading;
  float brightness = 0;
  
  float hue;
  
  void notify(float brightness, float ampl) {
    // for notifying self
    //if (brightness > this.brightness) this.brightness = brightness;
    hue += ampl * ampl/2;
    if (hue >= 255) hue = 0;
  }
  
  void notify(float brightness, float hue2, float ampl) {
    //if (brightness > this.brightness) this.brightness = brightness;
    hue += (hue2 - hue)/HUE_FACTOR;
    hue += ampl * ampl/2;
    if (hue >= 255) hue = 0;
  }
  
  void update(float ampl) {
    x += sin(heading) * dV * (ampl + .1);
    y += cos(heading) * dV * (ampl + .1);
    if (x > width) x = 0;
    else if (x < 0) x = width;
    if (y > height) y = 0;
    else if (y < 0) y = height;
    brightness = max(brightness - BRIGHT_DROP, MINBRIGHT);
  }
}