// Branded onboarding screen shown when the app launches.
//
// Introduces the three core jobs — cards, bills and payments — then hands over
// to [AuthGate] through the primary call to action.

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/presentation/auth_gate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.onGetStarted});

  /// Optional hook for hosts or tests that want to handle the hand-off.
  final VoidCallback? onGetStarted;

  static const Key screenKey = Key('welcome-screen');
  static const Key heroKey = Key('welcome-hero');
  static const Key featuresKey = Key('welcome-features');
  static const Key getStartedKey = Key('welcome-get-started');

  void _handleGetStarted(BuildContext context) {
    final action = onGetStarted;
    if (action != null) {
      action();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final brand = isDark ? AppColors.brandPrimaryDark : AppColors.brandPrimary;
    final chipBackground =
        isDark ? AppColors.surfaceRaisedDark : AppColors.brandPrimaryLight;

    return Scaffold(
      key: screenKey,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), AppColors.brandPrimary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(context),
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Every bill. One clear view.',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Track cards, catch due dates, and log payments in '
                        'seconds — all in one calm place.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      KeyedSubtree(
                        key: featuresKey,
                        child: Row(
                          children: [
                            _buildFeatureChip(
                              context,
                              icon: Icons.credit_card_rounded,
                              label: 'Cards',
                              background: chipBackground,
                              foreground: brand,
                            ),
                            const SizedBox(width: 10),
                            _buildFeatureChip(
                              context,
                              icon: Icons.receipt_long_rounded,
                              label: 'Bills',
                              background: chipBackground,
                              foreground: brand,
                            ),
                            const SizedBox(width: 10),
                            _buildFeatureChip(
                              context,
                              icon: Icons.payments_rounded,
                              label: 'Payments',
                              background: chipBackground,
                              foreground: brand,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Semantics(
                        button: true,
                        label: 'Get Started button',
                        child: ElevatedButton.icon(
                          key: getStartedKey,
                          onPressed: () => _handleGetStarted(context),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Get Started'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Private by design. Your data stays with you.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      key: heroKey,
      height: 300,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBrandRow(context),
              const SizedBox(height: 24),
              _buildIllustration(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandRow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: const Icon(
            Icons.credit_card_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credit Bill System',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Stay ahead of every bill',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 6,
            child: Transform.rotate(
              angle: -0.045,
              child: Container(
                height: 108,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.credit_card_rounded,
                          color: AppColors.brandPrimary,
                          size: 22,
                        ),
                        Text(
                          'CBS',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '•••• 4821',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 2,
            child: _buildFloatingChip(
              context,
              icon: Icons.event_note_rounded,
              label: 'Due soon',
              color: AppColors.healthModerate,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 16,
            child: _buildFloatingChip(
              context,
              icon: Icons.check_circle_rounded,
              label: 'Paid',
              color: AppColors.healthHealthy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: foreground),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
