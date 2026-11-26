import 'package:flutter/foundation.dart';

import 'settings_repository.dart';

/// Identifiers for the reorderable actions shown on the welcome page.
abstract final class WelcomeItemId {
  static const String getStarted = 'get_started';
  static const String help = 'help';
  static const String settings = 'settings';
}

/// Shared, observable order of the welcome page actions.
///
/// The default keeps the primary action first. A stored order can be loaded
/// through [load]; the Settings screen writes changes back through the same
/// repository so the layout survives a restart.
abstract final class WelcomeLayout {
  static const List<String> defaultOrder = [
    WelcomeItemId.getStarted,
    WelcomeItemId.help,
    WelcomeItemId.settings,
  ];

  static const Set<String> validIds = {
    WelcomeItemId.getStarted,
    WelcomeItemId.help,
    WelcomeItemId.settings,
  };

  static final ValueNotifier<List<String>> order = ValueNotifier<List<String>>(
    List<String>.unmodifiable(defaultOrder),
  );

  /// Returns a safe order: known ids only, no duplicates, all ids present.
  static List<String> normalize(List<String>? ids) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids ?? const <String>[]) {
      final trimmed = id.trim();
      if (validIds.contains(trimmed) && seen.add(trimmed)) {
        result.add(trimmed);
      }
    }
    for (final id in defaultOrder) {
      if (seen.add(id)) result.add(id);
    }
    return result;
  }

  /// Loads a persisted order, falling back to [defaultOrder].
  static Future<void> load(SettingsRepository repository) async {
    setOrder(await repository.getWelcomeOrder() ?? defaultOrder);
  }

  /// Applies a new order without notifying listeners when nothing changed.
  static void setOrder(List<String> ids) {
    final next = List<String>.unmodifiable(normalize(ids));
    if (_sameOrder(order.value, next)) return;
    order.value = next;
  }

  static void moveUp(String id) => _move(id, -1);

  static void moveDown(String id) => _move(id, 1);

  static void _move(String id, int offset) {
    final current = List<String>.from(order.value);
    final index = current.indexOf(id);
    final target = index + offset;
    if (index < 0 || target < 0 || target >= current.length) return;
    current.removeAt(index);
    current.insert(target, id);
    setOrder(current);
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
