import 'package:flutter/material.dart';

class AppColors {
  // Primary Agronomic Palette
  static const Color primary = Color(0xFF2E7D32); // Agro Forest Green
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color accent = Color(0xFFF57C00); // Earth Orange

  // Severity Colors for Pest Levels
  static const Color severityLow = Color(0xFF4CAF50); // 1-5 (Green)
  static const Color severityMedium = Color(0xFFFFB300); // 6-15 (Amber)
  static const Color severityHigh = Color(0xFFFF5722); // 16-30 (Deep Orange)
  static const Color severityCritical = Color(0xFFD32F2F); // >30 (Red)

  // Surface & Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  
  // Dark Theme
  static const Color backgroundDark = Color(0xFF121814);
  static const Color surfaceDark = Color(0xFF1E2621);
  static const Color cardBgDark = Color(0xFF253029);

  // Text
  static const Color textPrimary = Color(0xFF1C2826);
  static const Color textSecondary = Color(0xFF607274);
  static const Color divider = Color(0xFFE0E0E0);

  /// Returns color based on pest quantity
  static Color getSeverityColor(int quantity) {
    if (quantity <= 5) return severityLow;
    if (quantity <= 15) return severityMedium;
    if (quantity <= 30) return severityHigh;
    return severityCritical;
  }

  /// Returns label for pest severity
  static String getSeverityLabel(int quantity) {
    if (quantity <= 5) return 'Baixa';
    if (quantity <= 15) return 'Média';
    if (quantity <= 30) return 'Alta';
    return 'Crítica';
  }
}
