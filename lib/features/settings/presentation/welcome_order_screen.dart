// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/settings_repository.dart';
import '../domain/welcome_layout.dart';

/// Lets the user move the welcome page actions up or down.
///
/// The order is shared through [WelcomeLayout] so the welcome page updates as
/// soon as it is rebuilt, and is persisted through the app settings repository
/// when one is available.
class WelcomeOrderScreen extends StatelessWidget {
  const WelcomeOrderScreen({super.key});

  static const Key screenKey = Key('welcome-order-screen');

  static Key itemKey(String id) => Key('welcome-order-item-$id');
  static Key upKey(String id) => Key('welcome-order-up-$id');
  static Key downKey(String id) => Key('welcome-order-down-$id');

  static const Map<String, String> _labels = {
    WelcomeItemId.getStarted: 'Get Started',
    WelcomeItemId.help: 'Help',
    WelcomeItemId.settings: 'Settings',
  };

  static const Map<String, IconData> _icons = {
    WelcomeItemId.getStarted: Icons.arrow_forward_rounded,
    WelcomeItemId.help: Icons.help_outline,
    WelcomeItemId.settings: Icons.settings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Welcome Page Items')),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: WelcomeLayout.order,
        builder: (context, order, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Use the arrows to change where each action appears on the '
                'welcome page.',
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < order.length; index++)
                _buildItem(context, order[index], index, order.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String id,
    int index,
    int itemCount,
  ) {
    return Card(
      key: itemKey(id),
      child: ListTile(
        leading: Icon(_icons[id] ?? Icons.help_outline),
        title: Text(_labels[id] ?? id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: upKey(id),
              tooltip: 'Move ${_labels[id] ?? id} up',
              icon: const Icon(Icons.arrow_upward),
              onPressed: index > 0 ? () => _move(context, id, up: true) : null,
            ),
            IconButton(
              key: downKey(id),
              tooltip: 'Move ${_labels[id] ?? id} down',
              icon: const Icon(Icons.arrow_downward),
              onPressed: index < itemCount - 1
                  ? () => _move(context, id, up: false)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _move(BuildContext context, String id, {required bool up}) async {
    if (up) {
      WelcomeLayout.moveUp(id);
    } else {
      WelcomeLayout.moveDown(id);
    }
    final repository = context.read<SettingsRepository?>();
    await repository?.saveWelcomeOrder(WelcomeLayout.order.value);
  }
}
