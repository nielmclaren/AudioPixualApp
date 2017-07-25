import ddf.minim.*;
import ddf.minim.analysis.*;

ddf.minim.Minim minim;
ddf.minim.AudioInput in;
FFT fft;

PImage backgroundImg;

PVector center;
ArrayList<Pixel> pixels0;
ArrayList<Pixel> pixels1;

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
  pixels0 = getPixels(g, 16, 0);
  pixels1 = getPixels(g, 64, 1);
  
  int blurRadius = 16;
  blurrer = new FastBlurrer(width, height, blurRadius);

  fileNamer = new FileNamer("output/export", "png");
}

void draw() {
  blendMode(BLEND);
  fill(0, 64);
  rect(0, 0, width, height);

  fft.forward(in.mix);
  stepPixels(pixels0);
  stepPixels(pixels1);

  noStroke();
  fill(32);
  //drawFft(fft);

  drawPixels(pixels0);
  drawPixels(pixels1);
}

ArrayList<Pixel> getPixels(PGraphics g, int pixelSize, int layer) {
  ArrayList<Pixel> result = new ArrayList<Pixel>();
  for (int col = 0; col < g.width / pixelSize; col++) {
    for (int row = 0; row < g.height / pixelSize; row++) {
      color c = color(random(0, 255), 128, 255, 16 + layer * 16);
      result.add(new Pixel(layer, c, col * pixelSize, row * pixelSize, pixelSize, pixelSize));
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

void stepPixels(ArrayList<Pixel> pixels) {
  float hw = width/2;
  float hh = height/2;
  float maxDistFromCenter = sqrt(hw*hw + hh*hh);

  for (int i = 0; i < pixels.size(); i++) {
    Pixel p = pixels.get(i);
    float d = getDistFromCenter(p);
    int band = constrain(floor(map(d, 0, maxDistFromCenter, 0, fft.avgSize() - 2)), 0, fft.avgSize() - 1);
    float maxOffset = map(fft.getAvg(band), 0, 50, 0, 10) * (1 + (float)frameCount / 10000);
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

void drawPixels(ArrayList<Pixel> pixels) {
  blendMode(ADD);
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