import 'package:flutter/widgets.dart';

extension Responsive on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Scale a value proportionally to screen width (360dp baseline)
  double rs(double value) => value * screenWidth / 360;

  /// Scale with optional min/max clamp
  double rsc(double value, {double? min, double? max}) {
    final v = rs(value);
    if (min != null && v < min) return min;
    if (max != null && v > max) return max;
    return v;
  }

  /// Standard horizontal page padding
  double get hPad => rsc(20, min: 14, max: 32);

  /// Standard card border radius
  double get cardRadius => rsc(20, min: 14, max: 24);

  /// Standard section gap
  double get gap => rsc(16, min: 10, max: 24);

  bool get isSmallScreen => screenWidth < 360;
  bool get isLargeScreen => screenWidth >= 420;
}
