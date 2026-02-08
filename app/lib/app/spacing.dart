/// Spacing tokens used throughout the app for consistent layout.
///
/// Usage: `SizedBox(height: AppSpacing.md)` or `EdgeInsets.all(AppSpacing.sm)`.
abstract final class AppSpacing {
  /// 4dp — hairline gaps, icon padding.
  static const double xs = 4;

  /// 8dp — tight spacing between related elements.
  static const double sm = 8;

  /// 16dp — default content padding, card insets.
  static const double md = 16;

  /// 24dp — section separators, generous padding.
  static const double lg = 24;

  /// 32dp — screen-level margins, large gaps.
  static const double xl = 32;

  /// 48dp — hero spacing, minimum tap target size.
  static const double xxl = 48;
}
