import 'package:flutter/widgets.dart';

/// 앱 전역에서 쓰는 반응형 레이아웃 기준을 관리한다.
class AppResponsive {
  const AppResponsive._();

  static const tabletBreakpoint = 768.0;
  static const desktopBreakpoint = 1200.0;
  static const compactContentMaxWidth = 520.0;
  static const mediumContentMaxWidth = 560.0;
  static const clientListPaneWidth = 360.0;
  static const attendeeChipMaxWidth = 220.0;

  static double widthOf(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static bool isMobileWidth(BuildContext context) {
    return widthOf(context) < tabletBreakpoint;
  }

  static bool isTabletWidth(BuildContext context) {
    final width = widthOf(context);
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktopWidth(BuildContext context) {
    return widthOf(context) >= desktopBreakpoint;
  }

  static bool useRailNavigation(BuildContext context) {
    return !isMobileWidth(context);
  }

  static bool useSplitClientLayout(BuildContext context) {
    return !isMobileWidth(context);
  }
}
