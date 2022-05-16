import 'package:flutter/material.dart';

/// window size
///
class WindowSize {
  static const int MatchParent = -1;
  static const int WrapContent = -2;
}

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

  // 0001 0001
  static const Center = 17;
  // 0011 0000
  static const Top = 48;
  // 0101 0000
  static const Bottom = 80;
  // 0000 0011
  static const Left = 3;
  // 0000 0101
  static const Right = 5;

  static final _values = {
    GravityType.Center: Center,
    GravityType.CenterTop: Top | Center,
    GravityType.CenterBottom: Bottom | Center,
    GravityType.LeftTop: Top | Left,
    GravityType.LeftCenter: Center | Left,
    GravityType.LeftBottom: Bottom | Left,
    GravityType.RightTop: Top | Right,
    GravityType.RightCenter: Center | Right,
    GravityType.RightBottom: Bottom | Right,
  };

  int? toInt() {
    return _values[this];
  }

  GravityType? fromInt(int? v) {
    if (v == null) return null;
    var r = _values.keys
        .firstWhere((e) => _values[e] == v, orElse: () => GravityType.Unknown);
    return r == GravityType.Unknown ? null : r;
  }

  /// convert offset in topleft to others
  Offset apply(
    Offset o, {
    required double width,
    required double height,
  }) {
    var v = this.toInt();
    if (v == null) return o;

    var dx = o.dx;
    var dy = o.dy;

    var halfWidth = width / 2;
    var halfHeight = height / 2;

    // calcute the x: & 0000 1111 = 15
    // 3 1 5 => -1 0 1 => 0 1 2
    // dx += ((v&15) / 2) * halfWidth;
    // if (v&15 == 1) {
    //   dx += halfWidth;
    // } else if (v&15 == 2) {
    //   dx += width;
    // }

    // // calcute the y: & 1111 0000 = 240
    // // 48 16 80 => 0 1 2
    // dy += ((v&240) / 2) * halfHeight;

    return Offset(dx, dy);
  }
}
