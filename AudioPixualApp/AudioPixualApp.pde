
import ddf.minim.*;
import ddf.minim.analysis.*;
import java.util.Random;

Random random;

ddf.minim.Minim minim;
ddf.minim.AudioInput in;
FFT fft;

PImage backgroundImg;

PVector center;
float maxRadius;

ArrayList<Pixel> pixels0;
ArrayList<Pixel> pixels1;

ArrayList<Circle> circles;

PGraphics buffer;
FastBlurrer blurrer;
FileNamer fileNamer;
FileNamer animationFolderNamer;
FileNamer animationFileNamer;
int animationFramesRemaining;
int numAnimationFrames;

void setup() {
  size(1280, 720, P2D);

  random = new Random();

  minim = new Minim(this);
  in = minim.getLineIn();
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(10, 1);
  println(fft.avgSize());

  backgroundImg = loadImage("background.png");

  buffer = createGraphics(width, height, P2D);
  int blurRadius = 4;
  blurrer = new FastBlurrer(width, height, blurRadius);

  fileNamer = new FileNamer("output/export", "png");
  animationFolderNamer = new FileNamer("output/anim", "/");
  animationFramesRemaining = 0;
  numAnimationFrames = 300;

  reset();
}

void reset() {
  center = new PVector(width/2, height/2);
  maxRadius = height * 0.6;

  pixels0 = getPixels(g, 16, 0);
  pixels1 = getPixels(g, 64, 1);

  circles = getCircles(g);
}

void draw() {
  buffer.beginDraw();
  buffer.image(backgroundImg, 0, 0);

  fft.forward(in.mix);
  stepPixels(pixels0);
  stepPixels(pixels1);

  stepCircles(circles);

  drawPixels(buffer, pixels0);
  drawPixels(buffer, pixels1);
  buffer.endDraw();

  buffer.loadPixels();
  blurrer.blur(buffer.pixels);
  buffer.updatePixels();

  buffer.beginDraw();
  drawCircles(buffer, circles);
  buffer.endDraw();

  float m = 50;
  g.background(4);
  g.image(buffer, m, m, width - 2 * m, height - 2 * m);

  if (animationFramesRemaining-- > 0) {
    saveFrame(animationFileNamer.next());
  }
}

ArrayList<Pixel> getPixels(PGraphics g, int pixelSize, int layer) {
  ArrayList<Pixel> result = new ArrayList<Pixel>();
  for (int col = 0; col <= g.width / pixelSize; col++) {
    for (int row = 0; row <= g.height / pixelSize; row++) {
      colorMode(HSB);
      color c = color(0, 128 + layer * 64);
      result.add(new Pixel(layer, c, col * pixelSize, row * pixelSize, pixelSize, pixelSize));
    }
  }
  return result;
}

ArrayList<Circle> getCircles(PGraphics g) {
  ArrayList<Circle> result = new ArrayList<Circle>();
  int numCircles = 30;
  for (int i = 0; i < numCircles; i++) {
    colorMode(RGB);
    float weight = random(0.5, 3);
    float x = random(1) < 0.2 ? random(width) : center.x;
    float y = center.y;
    float r = map((float)random.nextGaussian(), -1, 1, 0, maxRadius);
    color c = color(250, 252, 168, map(r, 0, maxRadius, 255, 32));
    result.add(new Circle(0, c, weight, x, y, r));
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
    PVector toCenter = PVector.sub(new PVector(p.x, p.y), center);
    float d = toCenter.mag();
    int band = constrain(floor(map(d, 0, maxDistFromCenter, 0, fft.avgSize() - 2)), 0, fft.avgSize() - 1);
    float maxOffset = map(fft.getAvg(band), 0, 50, 0, 10) * (1 + (float)frameCount / 10000);
    PVector offset = toCenter.copy();
    offset.mult(random(maxOffset) / d);
    p.x += offset.x;
    p.y += offset.y;
  }

  for (int i = 0; i < pixels.size(); i++) {
    Pixel p = pixels.get(i);
    PVector toOrigin = PVector.sub(new PVector(p.x, p.y), new PVector(p.ox, p.oy));
    toOrigin.mult(0.2);
    p.x -= toOrigin.x;
    p.y -= toOrigin.y;
  }
}

void stepCircles(ArrayList<Circle> circles) {
  for (int i = 0; i < circles.size(); i++) {
    Circle circle = circles.get(i);
    int band = constrain(floor(map(circle.r, 0, maxRadius, fft.avgSize() - 4, 0)), 0, fft.avgSize() - 4);
    float maxOffset = map(fft.getAvg(band), 0, 50, 0, 10);
    circle.r += random(-maxOffset, maxOffset);
  }
}

void drawPixels(PGraphics g, ArrayList<Pixel> pixels) {
  for (int i = 0; i < pixels.size(); i++) {
    Pixel p = pixels.get(i);
    drawPixel(g, p);
  }
}

void drawPixel(PGraphics g, Pixel p) {
  g.fill(p.c);
  g.noStroke();
  g.rect(p.x, p.y, p.w, p.h);
}

void drawCircles(PGraphics g, ArrayList<Circle> circles) {
  for (int i = 0; i < circles.size(); i++) {
    Circle p = circles.get(i);
    drawCircle(g, p);
  }
}

void drawCircle(PGraphics g, Circle c) {
  g.noFill();
  g.stroke(c.c);
  g.strokeWeight(c.weight);
  g.ellipseMode(RADIUS);
  g.ellipse(c.x, c.y, c.r, c.r);
}

void keyReleased() {
  switch (key) {
    case 'a':
      startSaveAnimation();
      break;
    case 'e':
      reset();
      break;
    case 'r':
      saveRender();
      break;
  }
}

void startSaveAnimation() {
  animationFramesRemaining = numAnimationFrames;
  animationFileNamer = new FileNamer(animationFolderNamer.next() + "frame", "png");
}

void saveRender() {
  saveFrame(fileNamer.next());
}