class Pixel {
  public int layer;
  public color c;
  public float x;
  public float y;
  public float w;
  public float h;
  public float ox;
  public float oy;
  public float ow;
  public float oh;

  Pixel(int layerArg, color cArg, float xArg, float yArg, float wArg, float hArg) {
    layer = layerArg;
    c = cArg;
    x = xArg;
    y = yArg;
    w = wArg;
    h = hArg;

    ox = xArg;
    oy = yArg;
    ow = wArg;
    oh = hArg;
  }
}