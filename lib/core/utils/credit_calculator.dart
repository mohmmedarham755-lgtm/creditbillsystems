/// Credit health tier classification based on utilization percentage.
enum CreditHealthTier {
  /// Utilization < 30.0% (Optimal, builds credit score)
  healthy,

  /// Utilization between 30.0% and 50.0% (Warning zone)
  moderate,

  /// Utilization > 50.0% (High risk, harms credit score)
  highRisk,
}

/// Pure domain utility for credit calculations free of UI framework dependencies.
class CreditCalculator {
  CreditCalculator._();

  /// Calculates credit utilization rate: (totalBalance / totalLimit) * 100.
  ///
  /// Returns 0.0 if total credit limit is <= 0.
  /// Result is rounded to 1 decimal place.
  static double calculateUtilization({
    required double totalBalance,
    required double totalLimit,
  }) {
    if (totalLimit <= 0.0) {
      return 0.0;
    }
    if (totalBalance <= 0.0) {
      return 0.0;
    }

    final rawPercentage = (totalBalance / totalLimit) * 100.0;
    return double.parse(rawPercentage.toStringAsFixed(1));
  }

  /// Determines the health tier based on utilization percentage.
  static CreditHealthTier getHealthTier(double percentage) {
    if (percentage < 30.0) {
      return CreditHealthTier.healthy;
    } else if (percentage <= 50.0) {
      return CreditHealthTier.moderate;
    } else {
      return CreditHealthTier.highRisk;
    }
  }

  /// Formatted guidance text corresponding to each tier.
  static String getHealthTierLabel(CreditHealthTier tier) {
    switch (tier) {
      case CreditHealthTier.healthy:
        return 'Healthy Usage (<30%)';
      case CreditHealthTier.moderate:
        return 'Moderate Usage (30-50%)';
      case CreditHealthTier.highRisk:
        return 'High Risk Usage (>50%)';
    }
  }
}
