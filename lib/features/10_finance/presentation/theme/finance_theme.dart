import 'package:flutter/material.dart';

/// Single source of truth for all finance UI visuals.
/// Vibrant, colorful, human-centric design with financial theming.
class FinanceTheme {
  FinanceTheme._();

  // ─── Primary Colors - Refined & Sophisticated ───────────────────────────
  static const Color creditColor = Color(0xFF0D9488); // Deep Teal
  static const Color creditColorDark = Color(0xFF0F766E); // Darker Teal
  static const Color debitColor = Color(0xFFE11D48); // Rose/Crimson
  static const Color debitColorDark = Color(0xFFBE123C); // Darker Rose
  static const Color creditColorLight = Color(0xFF2DD4BF); // Sky/Teal

  // Brand accents (Artha logo)
  static const Color brandPrimary = Color(0xFF0891B2); // Teal/Cyan
  static const Color brandSecondary = Color(0xFF16A34A); // Green
  static const Color brandGold = Color(0xFFF59E0B); // Gold/Amber

  // ─── Category Colors - Harmonized Palette ───────────────────────────────
  static const Map<String, Color> categoryColors = {
    'Food': brandGold, // Gold
    'Travel': brandPrimary, // Teal/Cyan
    'Shopping': Color(0xFF0EA5E9), // Sky Blue
    'Bills': Color(0xFF0EA5E9), // Sky Blue
    'Medical': brandSecondary, // Green
    'Entertainment': Color(0xFF06B6D4), // Cyan
    'Transfer': Color(0xFF2563EB), // Blue
    'Payment': brandPrimary, // Teal/Cyan
    'Income': brandSecondary, // Green
    'eSewa': Color(0xFF0D9488), // Deep Teal
    'Khalti': Color(0xFF06B6D4), // Cyan
    'IME Pay': Color(0xFF2563EB), // Blue
    'Connect IPS': brandPrimary, // Teal/Cyan
    'FonePay': Color(0xFFE11D48), // Rose
    'Top-up': brandGold, // Gold
    'ATM': Color(0xFF64748B), // Slate/Slate gray
    'Bank Transfer': Color(0xFF3B82F6), // Blue
    'Remittance': Color(0xFF059669), // Darker Emerald
    'Other': Color(0xFF94A3B8), // Muted Slate
  };

  // ─── Gradient Helpers ─────────────────────────────────────────────────────
  /// Creates a vibrant gradient for credit (green) cards
  static LinearGradient creditGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [creditColorDark, creditColor]
          : [creditColor, creditColorLight],
    );
  }

  /// Creates a vibrant gradient for debit (orange/red) cards
  static LinearGradient debitGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [debitColorDark, debitColor]
          : [debitColor, const Color(0xFFFF8C42)],
    );
  }

  /// Creates a gradient for any category color
  static LinearGradient categoryGradient(
    Color baseColor,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lighter = Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor;
    final darker = Color.lerp(baseColor, Colors.black, 0.2) ?? baseColor;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark ? [darker, baseColor] : [baseColor, lighter],
    );
  }

  /// Gets vibrant color for a category
  static Color getCategoryColor(String? category) {
    if (category == null) return categoryColors['Other']!;
    return categoryColors[category] ?? categoryColors['Other']!;
  }

  // ─── Card Backgrounds (More Vibrant) ────────────────────────────────────
  /// Card/surface background with more opacity for better visibility
  static Color cardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6)
        : Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.8);
  }

  /// Elevated card background for shortcuts and important cards
  static Color cardBackgroundElevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8)
        : Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.95);
  }

  /// Border for balance/summary cards with vibrant tint
  static Color cardBorder(BuildContext context, {required Color tint}) {
    return tint.withOpacity(0.4);
  }

  // ─── Shadows & Elevation ────────────────────────────────────────────────
  /// Shadow for elevated cards
  static List<BoxShadow> cardShadow(
    BuildContext context, {
    double elevation = 2,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
        blurRadius: elevation * 4,
        offset: Offset(0, elevation * 2),
      ),
    ];
  }

  /// Shadow for gradient cards
  static List<BoxShadow> gradientCardShadow(BuildContext context) {
    return cardShadow(context, elevation: 4);
  }

  // ─── Icon/Amount Tints ───────────────────────────────────────────────────
  static Color creditTint(BuildContext context) => creditColor;
  static Color debitTint(BuildContext context) => debitColor;

  // ─── Spacing (same rhythm everywhere) ──────────────────────────────────
  static const double pagePadding = 20;
  static const double cardPadding = 18;
  static const double listItemPaddingH = 16;
  static const double listItemPaddingV = 14;
  static const double gapBetweenCards = 12;
  static const double gapSection = 24;
  static const double gapSectionLarge = 28;

  // ─── Radius (consistent roundness) ───────────────────────────────────────
  static const double radiusCard = 16;
  static const double radiusListTile = 14;
  static const double radiusButton = 14;
  static const double radiusIconBox = 12;

  // ─── Typography ─────────────────────────────────────────────────────────
  static TextStyle amountLarge(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 24,
      letterSpacing: -0.5,
    );
  }

  static TextStyle amountTrailing(
    BuildContext context, {
    required bool isCredit,
  }) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
      color: isCredit ? creditColor : debitColor,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      letterSpacing: 0.15,
    );
  }

  static TextStyle labelCaps(BuildContext context, {required Color color}) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    );
  }

  /// Small caption for dates and secondary info
  static TextStyle caption(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11);
  }

  /// Axis labels and small chart text
  static TextStyle chartAxisLabel(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10);
  }

  /// Pie chart / category distribution palette (vibrant colors)
  static const List<Color> chartPalette = [
    debitColor, // Debit
    brandSecondary, // Green
    brandGold, // Gold
    brandPrimary, // Teal/Cyan
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0EA5E9), // Sky
    Color(0xFF2563EB), // Blue
    Color(0xFF0D9488), // Deep teal
  ];

  /// Bar chart corner radius
  static const double radiusBar = 6;

  // ─── Heatmap Color Scale (low → high spending intensity) ──────────────────
  static const List<Color> heatmapScale = [
    Color(0xFFF0FDF4), // Almost no spend (very light green)
    Color(0xFFBBF7D0), // Low
    Color(0xFFFDE68A), // Moderate (amber tint)
    Color(0xFFFBBF24), // Medium-high
    Color(0xFFF97316), // High (orange)
    Color(0xFFEF4444), // Very high (red)
  ];

  /// Returns a heatmap color based on spending intensity (0.0 - 1.0).
  static Color heatmapColor(double intensity) {
    if (intensity <= 0) return heatmapScale.first;
    if (intensity >= 1) return heatmapScale.last;
    final index = (intensity * (heatmapScale.length - 1)).floor();
    final t = (intensity * (heatmapScale.length - 1)) - index;
    return Color.lerp(
          heatmapScale[index],
          heatmapScale[(index + 1).clamp(0, heatmapScale.length - 1)],
          t,
        ) ??
        heatmapScale[index];
  }

  // ─── Savings Ring Colors ──────────────────────────────────────────────────
  static const Color savingsRingFill = brandSecondary;
  static const Color savingsRingBackground = Color(0xFFE5E7EB);

  /// Gradient for insight carousel cards
  static LinearGradient insightCardGradient(Color baseColor) {
    final lighter = Color.lerp(baseColor, Colors.white, 0.15) ?? baseColor;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [baseColor, lighter],
    );
  }

  // ─── Trend Line Chart Colors ──────────────────────────────────────────────
  static const Color trendLineColor = brandPrimary; // Teal/Cyan
  static const Color trendFillStart = Color(0x400891B2); // 25% teal
  static const Color trendFillEnd = Color(0x000891B2); // Transparent teal
  static const Color trendDotColor = brandGold; // Gold for peak/low
}
