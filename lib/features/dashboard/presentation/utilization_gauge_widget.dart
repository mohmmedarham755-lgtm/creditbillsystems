import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/credit_calculator.dart';

/// A standalone 270\u00B0 circular radial credit utilization gauge widget.
///
/// Pure presentation: accepts [utilizationPercentage] and an optional
/// [healthTier] override. Derives tier and label from [CreditCalculator]
/// when no tier is supplied. No Firebase, Firestore, AuthProvider, or
/// repository dependencies.
class UtilizationGaugeWidget extends StatefulWidget {
  /// The utilization percentage to display. Values outside 0\u2013100 are clamped
  /// for the visual arc only; the center text shows the actual value.
  final double utilizationPercentage;

  /// Optional tier override. When omitted, the tier is derived from
  /// [utilizationPercentage] via [CreditCalculator.getHealthTier].
  final CreditHealthTier? healthTier;

  const UtilizationGaugeWidget({
    super.key,
    required this.utilizationPercentage,
    this.healthTier,
  });

  @override
  State<UtilizationGaugeWidget> createState() => _UtilizationGaugeWidgetState();
}

class _UtilizationGaugeWidgetState extends State<UtilizationGaugeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  /// The raw percentage, with non-finite values treated as 0.0.
  double get _safePercentage {
    final value = widget.utilizationPercentage;
    if (value.isNaN || value.isInfinite) return 0.0;
    return value;
  }

  /// Visual arc fraction clamped to 0.0\u20131.0. Negative or above-100 values
  /// never draw beyond the 270\u00B0 sweep.
  double get _clampedFraction {
    return _safePercentage.clamp(0.0, 100.0) / 100.0;
  }

  /// Center percentage text. Negative and non-finite values show 0.0\u0025;
  /// values above 100\u0025 show the actual value.
  String get _percentageText {
    final value = _safePercentage;
    if (value < 0.0) return '0.0%';
    return '${value.toStringAsFixed(1)}%';
  }

  /// Derived health tier, honoring an explicit override when supplied.
  CreditHealthTier get _tier {
    if (widget.healthTier != null) return widget.healthTier!;
    return CreditCalculator.getHealthTier(_safePercentage);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _tierColor(CreditHealthTier tier, bool isDark) {
    switch (tier) {
      case CreditHealthTier.healthy:
        return isDark ? AppColors.healthHealthyDark : AppColors.healthHealthy;
      case CreditHealthTier.moderate:
        return isDark ? AppColors.healthModerateDark : AppColors.healthModerate;
      case CreditHealthTier.highRisk:
        return isDark ? AppColors.healthRiskDark : AppColors.healthRisk;
    }
  }

  Color _tierBackgroundColor(CreditHealthTier tier, bool isDark) {
    switch (tier) {
      case CreditHealthTier.healthy:
        return isDark
            ? AppColors.healthHealthyBg
            : AppColors.healthHealthyBg;
      case CreditHealthTier.moderate:
        return isDark
            ? AppColors.healthModerateDark
            : AppColors.healthModerateBg;
      case CreditHealthTier.highRisk:
        return isDark ? AppColors.healthRiskDark : AppColors.healthRiskBg;
    }
  }

  String _tierName(CreditHealthTier tier) {
    switch (tier) {
      case CreditHealthTier.healthy:
        return 'Healthy';
      case CreditHealthTier.moderate:
        return 'Moderate';
      case CreditHealthTier.highRisk:
        return 'High Risk';
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Credit Utilization'),
        content: const Text(
          'Credit utilization is the percentage of your total credit limit '
          'currently in use. Staying below 30% is generally considered healthy '
          'and supports your credit score. Utilization above 50% is high risk. '
          'This gauge shows your aggregate utilization across all cards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tier = _tier;
    final color = _tierColor(tier, isDark);
    final label = CreditCalculator.getHealthTierLabel(tier);
    final fraction = _animation.value * _clampedFraction;

    return Semantics(
      label:
          'Credit utilization is $_percentageText, categorized as '
          '${_tierName(tier)}.',
      button: true,
      child: GestureDetector(
        onTap: () => _showInfoDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _GaugePainter(
                        fraction: fraction,
                        trackColor: isDark
                            ? AppColors.borderSubtleDark
                            : AppColors.borderSubtle,
                        progressColor: color,
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _percentageText,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _tierBackgroundColor(tier, isDark),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter for the 270\u00B0 radial gauge track and progress arc.
class _GaugePainter extends CustomPainter {
  final double fraction;
  final Color trackColor;
  final Color progressColor;

  _GaugePainter({
    required this.fraction,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;
    final strokeWidth = 16.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = pi; // 9 o'clock (left side)
    const fullSweep = 3 * pi / 2; // 270\u00B0

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      trackPaint,
    );

    if (fraction > 0.0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        fraction * fullSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) {
    return old.fraction != fraction ||
        old.trackColor != trackColor ||
        old.progressColor != progressColor;
  }
}
