import 'package:flutter/material.dart';

/// Responsive design utilities for AgroWeather Guide
/// Handles breakpoints for mobile, tablet, and web layouts
class Responsive {
  /// Breakpoint definitions
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Max content width for web/desktop to prevent over-stretching
  static const double maxContentWidth = 1200;
  static const double maxMobileWidth = 600;

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Check if web platform (desktop or large tablet)
  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Get responsive grid count (for GridView)
  static int getGridCount(BuildContext context,
      {int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) return baseSize * 1.1;
    if (isTablet(context)) return baseSize * 1.05;
    return baseSize;
  }

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return (maxContentWidth - 64) / 2; // 2 columns with spacing
    } else if (isTablet(context)) {
      return screenWidth - 48;
    }
    return screenWidth - 32;
  }

  /// Constrain content width for large screens
  static BoxConstraints getContentConstraints(BuildContext context) {
    return BoxConstraints(
      maxWidth: isWeb(context) ? maxContentWidth : double.infinity,
    );
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context) {
    if (isDesktop(context)) return 16.0;
    if (isTablet(context)) return 14.0;
    return 12.0;
  }
}

/// Responsive wrapper widget that centers content on large screens
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: Responsive.getContentConstraints(context),
        child: child,
      ),
    );
  }
}

/// Responsive grid that adjusts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double? spacing;
  final double? runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.spacing,
    this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = Responsive.getGridCount(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    final defaultSpacing = Responsive.getSpacing(context);

    return GridView.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: runSpacing ?? defaultSpacing,
      crossAxisSpacing: spacing ?? defaultSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// Responsive layout that switches between single and double column
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!;
    } else if (Responsive.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Responsive card with adaptive sizing
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? Responsive.getPadding(context);

    return Card(
      elevation: elevation ?? 2,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(Responsive.isWeb(context) ? 20 : 16),
      ),
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );
  }
}
