import 'package:flutter/material.dart';
import '../theme/finance_theme.dart';

/// Maps categories to icons and provides consistent visualization
class CategoryIcon {
  CategoryIcon._();

  /// Icon mapping for categories
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Travel': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Medical': Icons.local_hospital_rounded,
    'Entertainment': Icons.movie_rounded,
    'Transfer': Icons.swap_horiz_rounded,
    'Payment': Icons.payment_rounded,
    'Income': Icons.trending_up_rounded,
    'eSewa': Icons.account_balance_wallet_rounded,
    'Khalti': Icons.account_balance_wallet_rounded,
    'IME Pay': Icons.account_balance_wallet_rounded,
    'Connect IPS': Icons.account_balance_wallet_rounded,
    'FonePay': Icons.account_balance_wallet_rounded,
    'Top-up': Icons.phone_android_rounded,
    'ATM': Icons.atm_rounded,
    'Bank Transfer': Icons.account_balance_rounded,
    'Remittance': Icons.send_rounded,
    'Other': Icons.category_rounded,
  };

  /// Gets icon for a category
  static IconData getIcon(String? category) {
    if (category == null) return categoryIcons['Other']!;
    return categoryIcons[category] ?? categoryIcons['Other']!;
  }

  /// Gets color for a category
  static Color getColor(String? category) {
    return FinanceTheme.getCategoryColor(category);
  }

  /// Creates a colorful category icon widget
  static Widget build({
    required String? category,
    double size = 24,
    bool useGradient = false,
    BuildContext? context,
  }) {
    final icon = getIcon(category);
    final color = getColor(category);
    
    if (useGradient && context != null) {
      return Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          gradient: FinanceTheme.categoryGradient(color, context),
          borderRadius: BorderRadius.circular(FinanceTheme.radiusIconBox),
          boxShadow: FinanceTheme.cardShadow(context, elevation: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size),
      );
    }
    
    return Container(
      width: size + 16,
      height: size + 16,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(FinanceTheme.radiusIconBox),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
