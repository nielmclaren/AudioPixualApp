import ddf.minim.*;
import ddf.minim.analysis.*;

ddf.minim.Minim minim;
ddf.minim.AudioInput in;
FFT fft;

PImage backgroundImg;

PVector center;
int pixelSize;
ArrayList<Pixel> pixels;

FastBlurrer blurrer;
FileNamer fileNamer;

void setup() {
  size(1280, 720);

  minim = new Minim(this);
  in = minim.getLineIn();
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(10, 1);
  println(fft.avgSize());

  backgroundImg = loadImage("background.png");

  center = new PVector(width/2, height/2);
  pixelSize = 16;
  pixels = getPixels(g);
  
  int blurRadius = 16;
  blurrer = new FastBlurrer(width, height, blurRadius);

  fileNamer = new FileNamer("output/export", "png");
}

void draw() {
  int frameMax = 2000;
  colorMode(HSB);
  fill(216 + map(frameCount % frameMax, 0, frameMax, 0, 255), 128, 255);
  rect(0, 0, width, height);

  fft.forward(in.mix);
  stepPixels();

  noStroke();
  fill(32);
  //drawFft(fft);

  drawPixels();
}

ArrayList<Pixel> getPixels(PGraphics g) {
  ArrayList<Pixel> result = new ArrayList<Pixel>();
  for (int col = 0; col < g.width / pixelSize; col++) {
    for (int row = 0; row < g.height / pixelSize; row++) {
      color c = color(0);
      result.add(new Pixel(c, col * pixelSize, row * pixelSize, pixelSize, pixelSize));
    }
  }
  return result;
}

void drawFft(FFT fft) {
  float bandWidth = (float)width / fft.avgSize();
  for (int i = 0; i < fft.avgSize(); i++) {
    // draw the line for frequency band i, scaling it up so we can see it a bit better
    float h = fft.getAvg(i) * 8;
    rect(i * bandWidth, height - h, bandWidth, h);
  }
}

void stepPixels() {
  float hw = width/2;
  float hh = height/2;
  float maxDistFromCenter = sqrt(hw*hw + hh*hh);

  for (int i = 0; i < pixels.size(); i++) {
    Pixel p = pixels.get(i);
    float d = getDistFromCenter(p);
    int band = constrain(floor(map(d, 0, maxDistFromCenter, 0, fft.avgSize())), 0, fft.avgSize() - 1);
    float maxOffset = map(fft.getAvg(band), 0, 50, 0, 10);
    p.x += random(-maxOffset, maxOffset);
    p.y += random(-maxOffset, maxOffset);
  }

  for (int i = 0; i < pixels.size(); i++) {
    Pixel p = pixels.get(i);
    PVector toOrigin = PVector.sub(new PVector(p.x, p.y), new PVector(p.ox, p.oy));
    toOrigin.mult(0.01);
    p.x -= toOrigin.x;
    p.y -= toOrigin.y;
  }
}

float getDistFromCenter(Pixel p) {
  return PVector.sub(new PVector(p.x, p.y), center).mag();
}

void drawPixels() {
  for (int i = 0; i < pixels.size(); i++) {
    Pixel p = pixels.get(i);
    drawPixel(p);
  }
}

void drawPixel(Pixel p) {
  fill(p.c);
  rect(p.x, p.y, p.w, p.h);
}

void keyReleased() {
  switch (key) {
    case 'r':
      saveRender();
      break;
  }
}

void saveRender() {
  saveFrame(fileNamer.next());
}