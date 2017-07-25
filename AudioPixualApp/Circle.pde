class Circle {
  public int layer;
  public color c;
  public float weight;
  public float x;
  public float y;
  public float r;
  public float ox;
  public float oy;
  public float or;

  Circle(int layerArg, color cArg, float weightArg, float xArg, float yArg, float rArg) {
    layer = layerArg;
    c = cArg;
    weight = weightArg;
    x = xArg;
    y = yArg;
    r = rArg;

    ox = xArg;
    oy = yArg;
    or = rArg;
  }
}