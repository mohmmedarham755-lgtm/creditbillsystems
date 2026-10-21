import 'package:flutter/material.dart';

/// Semantic color palette defined in DESIGN.md for the Credit Bill System.
class AppColors {
  AppColors._();

  // Light Mode Palette
  static const Color surfaceBase = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color brandPrimary = Color(0xFF2563EB);
  static const Color brandPrimaryLight = Color(0xFFEFF6FF);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Status & Health Tiers (Light Mode)
  static const Color healthHealthy = Color(0xFF10B981);       // <30% Utilization
  static const Color healthHealthyBg = Color(0xFFECFDF5);
  static const Color healthModerate = Color(0xFFF59E0B);      // 30-50% Utilization
  static const Color healthModerateBg = Color(0xFFFFFBEB);
  static const Color healthRisk = Color(0xFFEF4444);          // >50% Utilization
  static const Color healthRiskBg = Color(0xFFFEF2F2);

  // Dark Mode Palette
  static const Color surfaceBaseDark = Color(0xFF0B0F19);
  static const Color surfaceCardDark = Color(0xFF151D2C);
  static const Color surfaceRaisedDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color brandPrimaryDark = Color(0xFF3B82F6);
  static const Color borderSubtleDark = Color(0xFF1E293B);
  static const Color healthHealthyDark = Color(0xFF34D399);
  static const Color healthModerateDark = Color(0xFFFBBF24);
  static const Color healthRiskDark = Color(0xFFF87171);
}
