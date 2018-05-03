import ddf.minim.*;
import ddf.minim.analysis.*;

int numDots = 200;
Dot[] dots = new Dot[numDots];

final float MINDIST = 5;
final float MAXDIST = 150;
final float MINBRIGHT = 30;
final float HUE_FACTOR = 5;

final float ampOff = .2;
final float BRIGHT_DROP = 1;

AudioInput in;
FFT fft;
//Amplitude amp;
Minim minim;

int bands = 256;
float[] spectrum = new float[bands];

void setup() {
  size(1000,750,P3D);
  //fullScreen(P3D);
  for (int i = 0; i < numDots; i++) {
    dots[i] = new Dot(random(width), random(height), random(3), random(2 * PI));
  }
  colorMode(HSB);
  minim = new Minim(this);
  //amp = new Amplitude(this);
  in = minim.getLineIn();
  fft = new FFT(in.bufferSize(), in.sampleRate());
  //amp.input(in);
}

float dist;
float bright;
float amplitude;
float max = 0;
float min = 1;
float bass;

boolean prepped = false;
float ampl;

void draw() {
  while(!prepped) updateAudio();
  ampl = updateAudio();
  println(ampl);
  strokeWeight(2);
  lights();
  fill(255);
  background(0);
  for (int i = 0; i < numDots; i++) {
    dots[i].update(ampl);
    pushMatrix();
    translate(dots[i].x, dots[i].y);
    for (int j = 0; j < numDots; j++) {
      if (j == i || j < i) continue;
      dist = sqrt(pow(dots[j].x - dots[i].x,2) + pow(dots[j].y - dots[i].y,2));
      if (dist < MAXDIST) {
        bright = map(dist, MAXDIST, MINDIST, MINBRIGHT, 255);
        
        dots[i].notify(bright, ampl);
        dots[j].notify(bright, dots[i].hue, ampl);
        
        stroke((dots[i].hue + dots[j].hue)/2, bright, bright);
        fill((dots[i].hue + dots[j].hue)/2, bright, bright);
        //line(0,0,dots[j].x-dots[i].x, dots[j].y-dots[i].y);
      }
    }
    bright = spectrum[int(spectrum.length * ((float)i/numDots))] * 10;
    dots[i].notify(bright, ampl);
    stroke(dots[i].hue, dots[i].brightness, dots[i].brightness);
    fill(dots[i].hue, dots[i].brightness, dots[i].brightness);
    ellipse(0,0,5,5);
    popMatrix();
  }
}

float updateAudio() {
  // returns rms amplitude, scaled appropriately
  fft.forward(in.mix);
  amplitude = in.mix.level();
  bass = 0;
  for (int i = 0; i < bands/4; i++) bass += spectrum[i];
  println(bass);
  if (amplitude > max) max = amplitude;
  else if (amplitude < min) min = amplitude;
  if (max > min) prepped = true;
  return (amplitude - min) * (1 - ampOff)/(max - min) + ampOff;
}