/// window size
const int WindowMatchParent = -1;
const int WindowWrapContent = -2;


enum GravityType {
  Center,
  CenterTop,
  CenterBottom,
  LeftTop,
  LeftCenter,
  LeftBottom,
  RightTop,
  RightCenter,
  RightBottom,

  Unknown,
}

extension GravityTypeConverter on GravityType {

  // ignore: slash_for_doc_comments
  /**
    public static final int AXIS_CLIP = 8;
    public static final int AXIS_PULL_AFTER = 4;
    public static final int AXIS_PULL_BEFORE = 2;
    public static final int AXIS_SPECIFIED = 1;
    public static final int AXIS_X_SHIFT = 0;
    public static final int AXIS_Y_SHIFT = 4;
    public static final int BOTTOM = 80;
    public static final int CENTER = 17;
    public static final int CENTER_HORIZONTAL = 1;
    public static final int CENTER_VERTICAL = 16;
    public static final int CLIP_HORIZONTAL = 8;
    public static final int CLIP_VERTICAL = 128;
    public static final int DISPLAY_CLIP_HORIZONTAL = 16777216;
    public static final int DISPLAY_CLIP_VERTICAL = 268435456;
    public static final int END = 8388613;
    public static final int FILL = 119;
    public static final int FILL_HORIZONTAL = 7;
    public static final int FILL_VERTICAL = 112;
    public static final int HORIZONTAL_GRAVITY_MASK = 7;
    public static final int LEFT = 3;
    public static final int NO_GRAVITY = 0;
    public static final int RELATIVE_HORIZONTAL_GRAVITY_MASK = 8388615;
    public static final int RELATIVE_LAYOUT_DIRECTION = 8388608;
    public static final int RIGHT = 5;
    public static final int START = 8388611;
    public static final int TOP = 48;
    public static final int VERTICAL_GRAVITY_MASK = 112;
   */

  static const Center = 17;
  static const Top = 48;
  static const Bottom = 80;
  static const Left = 3;
  static const Right = 5;

  static final _values = {
    GravityType.Center: Center,
    GravityType.CenterTop: Center | Top,
    GravityType.CenterBottom: Center | Bottom,
    GravityType.LeftTop: Left | Top,
    GravityType.LeftCenter: Left | Center,
    GravityType.LeftBottom: Left | Bottom,
    GravityType.RightTop: Right | Top,
    GravityType.RightCenter: Right | Center,
    GravityType.RightBottom: Right | Bottom,
  };

  int? toInt() {
    return _values[this];
  }

  GravityType? fromInt(int? v) {
    if (v == null) return null;
    var r = _values.keys.firstWhere((e) => _values[e] == v, orElse: () => GravityType.Unknown);
    return r == GravityType.Unknown ? null : r;
  }
}