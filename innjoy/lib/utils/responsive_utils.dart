import 'package:flutter/material.dart';

/// ResponsiveUtils - Tüm cihazlarda tutarlı görünüm için merkezi responsive sistem
class ResponsiveUtils {
  // Ekran boyutlarını al
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Yüzdeye göre genişlik (0.0 - 1.0)
  static double wp(BuildContext context, double percentage) =>
      screenWidth(context) * percentage;

  // Yüzdeye göre yükseklik (0.0 - 1.0)
  static double hp(BuildContext context, double percentage) =>
      screenHeight(context) * percentage;

  // Ekran genişliğine göre ölçeklenmiş font boyutu
  // Clamping ile çok küçük/büyük olmayı engeller
  static double sp(BuildContext context, double size) {
    final width = screenWidth(context);
    // 375 (iPhone SE) referans ekran genişliği
    final scaleFactor = width / 375;
    // Font boyutlarını 0.85x - 1.3x arasında tut
    final clampedScale = scaleFactor.clamp(0.85, 1.3);
    return size * clampedScale;
  }

  // Ekran genişliğine göre ölçeklenmiş spacing/padding
  // Clamping ile tutarlı spacing sağlar
  static double spacing(BuildContext context, double baseSpacing) {
    final width = screenWidth(context);
    final scaleFactor = width / 375;
    // Spacing'i 0.9x - 1.2x arasında tut (daha konservatif)
    final clampedScale = scaleFactor.clamp(0.9, 1.2);
    return baseSpacing * clampedScale;
  }

  // Ekran tipi kontrolü
  static bool isSmallScreen(BuildContext context) =>
      screenWidth(context) < 360;

  static bool isMediumScreen(BuildContext context) =>
      screenWidth(context) >= 360 && screenWidth(context) < 400;

  static bool isLargeScreen(BuildContext context) =>
      screenWidth(context) >= 400 && screenWidth(context) < 600;

  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;

  // Kolay kullanım için getter metodları
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
        horizontal: spacing(context, 16),
        vertical: spacing(context, 12),
      );

  static EdgeInsets cardPadding(BuildContext context) => EdgeInsets.all(
        spacing(context, 12),
      );

  static double buttonHeight(BuildContext context) => hp(context, 0.06);

  static double inputHeight(BuildContext context) => hp(context, 0.065);

  // Icon boyutu da clamped scaling kullanır
  static double iconSize(BuildContext context) => sp(context, 24);

  // BorderRadius değerleri
  static double borderRadiusSmall(BuildContext context) =>
      spacing(context, 8);

  static double borderRadiusMedium(BuildContext context) =>
      spacing(context, 12);

  static double borderRadiusLarge(BuildContext context) =>
      spacing(context, 16);

  // Font boyutları
  static double fontSizeSmall(BuildContext context) => sp(context, 12);
  static double fontSizeRegular(BuildContext context) => sp(context, 14);
  static double fontSizeMedium(BuildContext context) => sp(context, 16);
  static double fontSizeLarge(BuildContext context) => sp(context, 18);
  static double fontSizeXLarge(BuildContext context) => sp(context, 20);
  static double fontSizeXXLarge(BuildContext context) => sp(context, 24);
  static double fontSizeTitle(BuildContext context) => sp(context, 28);
}

/// Extension metodları - Daha kısa kullanım için
extension ResponsiveContext on BuildContext {
  double get screenWidth => ResponsiveUtils.screenWidth(this);
  double get screenHeight => ResponsiveUtils.screenHeight(this);

  double wp(double percentage) => ResponsiveUtils.wp(this, percentage);
  double hp(double percentage) => ResponsiveUtils.hp(this, percentage);
  double sp(double size) => ResponsiveUtils.sp(this, size);
  double spacing(double baseSpacing) =>
      ResponsiveUtils.spacing(this, baseSpacing);

  bool get isSmallScreen => ResponsiveUtils.isSmallScreen(this);
  bool get isMediumScreen => ResponsiveUtils.isMediumScreen(this);
  bool get isLargeScreen => ResponsiveUtils.isLargeScreen(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);

  EdgeInsets get pagePadding => ResponsiveUtils.pagePadding(this);
  EdgeInsets get cardPadding => ResponsiveUtils.cardPadding(this);

  double get buttonHeight => ResponsiveUtils.buttonHeight(this);
  double get inputHeight => ResponsiveUtils.inputHeight(this);
  double get iconSize => ResponsiveUtils.iconSize(this);

  double get borderRadiusSmall => ResponsiveUtils.borderRadiusSmall(this);
  double get borderRadiusMedium => ResponsiveUtils.borderRadiusMedium(this);
  double get borderRadiusLarge => ResponsiveUtils.borderRadiusLarge(this);

  double get fontSizeSmall => ResponsiveUtils.fontSizeSmall(this);
  double get fontSizeRegular => ResponsiveUtils.fontSizeRegular(this);
  double get fontSizeMedium => ResponsiveUtils.fontSizeMedium(this);
  double get fontSizeLarge => ResponsiveUtils.fontSizeLarge(this);
  double get fontSizeXLarge => ResponsiveUtils.fontSizeXLarge(this);
  double get fontSizeXXLarge => ResponsiveUtils.fontSizeXXLarge(this);
  double get fontSizeTitle => ResponsiveUtils.fontSizeTitle(this);
}
