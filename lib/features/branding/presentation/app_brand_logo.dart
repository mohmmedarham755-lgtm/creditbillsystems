import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_logo_provider.dart';

class AppBrandLogo extends StatelessWidget {
  final double size;

  const AppBrandLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final bytes = context.watch<AppLogoProvider?>()?.logoBytes;
    final fallback = Icon(
      Icons.credit_card_rounded,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );

    if (bytes == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
