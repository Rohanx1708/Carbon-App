/// Width breakpoints for hybrid phone / tablet / desktop layouts.
abstract final class AppBreakpoints {
  static const double phone = 600;
  static const double tablet = 840;
  static const double desktop = 1100;

  /// Bottom nav vs side rail.
  static const double navigationRail = tablet;

  /// Single vs multi-column lists.
  static const double listTwoColumns = 720;
  static const double listThreeColumns = 1100;

  /// Extended rail labels.
  static const double navigationRailExtended = desktop;
}
