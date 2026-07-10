import 'package:flutter/material.dart';

/// Screen-width breakpoints:
///   mobile  < 600 dp
///   tablet  600 – 1199 dp
///   desktop ≥ 1200 dp
class Responsive {
  Responsive._();

  static const double _mobileMax = 600;
  static const double _tabletMax = 1200;
  static const double maxContentWidth = 1400;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _mobileMax && w < _tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _tabletMax;

  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _tabletMax;

  /// Returns the value matching the current breakpoint.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  /// Column count used throughout item grids.
  static int gridColumns(BuildContext context) =>
      value(context, mobile: 2, tablet: 3, desktop: 4);
}

/// Widget that renders one of three layouts based on screen width.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return desktop;
    if (Responsive.isTablet(context)) return tablet ?? desktop;
    return mobile;
  }
}

/// Constrains desktop content to [Responsive.maxContentWidth] and centres it.
class DesktopConstraint extends StatelessWidget {
  const DesktopConstraint({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: child,
      ),
    );
  }
}
