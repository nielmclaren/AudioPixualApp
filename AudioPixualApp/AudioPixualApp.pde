import ddf.minim.*;
import ddf.minim.analysis.*;

ddf.minim.Minim minim;
ddf.minim.AudioInput in;
FFT fft;

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

  pixelSize = 16;
  pixels = getPixels(g);
  
  int blurRadius = 16;
  blurrer = new FastBlurrer(width, height, blurRadius);

  fileNamer = new FileNamer("output/export", "png");
}

void draw() {
  background(0);
  fft.forward(in.mix);
  stepPixels();

  noStroke();
  fill(32);
  drawFft(fft);

  drawPixels();
}

ArrayList<Pixel> getPixels(PGraphics g) {
  ArrayList<Pixel> result = new ArrayList<Pixel>();
  for (int col = 0; col < g.width / pixelSize; col++) {
    for (int row = 0; row < g.height / pixelSize; row++) {
      color c = color(random(128, 255), 128, 128);
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
  for (int i = 0; i < pixels.size(); i++) {
    Pixel p = pixels.get(i);
    p.x += random(-3, 3);
    p.y += random(-3, 3);
  }
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