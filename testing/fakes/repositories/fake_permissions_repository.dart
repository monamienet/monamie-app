import 'dart:ui' show AppLifecycleState;

import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';

import 'fake_outcomes.dart';

/// [PermissionsRepository] without the system: the statuses are plain
/// [ValueNotifier]s a test sets, and asking for a permission grants it when
/// [grantOnRequest] is true (the person taps "Permitir"), else leaves it
/// denied. Opening the battery settings lifts the restriction when
/// [grantOnRequest] is true. Every action is recorded.
class FakePermissionsRepository
    with FakeOutcomes
    implements PermissionsRepository {
  FakePermissionsRepository({this.grantOnRequest = true});

  /// Whether the person grants what is asked.
  bool grantOnRequest;

  @override
  final ValueNotifier<bool> hasWhenInUseLocationPermission = ValueNotifier(
    false,
  );

  @override
  final ValueNotifier<bool> hasAlwaysLocationPermission = ValueNotifier(false);

  @override
  final ValueNotifier<bool> hasNotificationPermission = ValueNotifier(false);

  @override
  final ValueNotifier<bool> isBackgroundRestricted = ValueNotifier(false);

  @override
  Future<void> start() => run('start', const [], () {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      calls.add((method: 'didChangeAppLifecycleState', arguments: [state]));

  @override
  Future<bool> refreshBackgroundRestriction() => run(
    'refreshBackgroundRestriction',
    const [],
    () => isBackgroundRestricted.value,
  );

  @override
  Future<void> requestWhenInUsePermission() =>
      run('requestWhenInUsePermission', const [], () {
        if (grantOnRequest) hasWhenInUseLocationPermission.value = true;
      });

  @override
  Future<void> requestAlwaysPermission() =>
      run('requestAlwaysPermission', const [], () {
        if (!grantOnRequest) return;
        hasWhenInUseLocationPermission.value = true;
        hasAlwaysLocationPermission.value = true;
      });

  @override
  Future<void> requestNotificationPermission() =>
      run('requestNotificationPermission', const [], () {
        if (grantOnRequest) hasNotificationPermission.value = true;
      });

  @override
  bool arePermissionsGranted() =>
      hasAlwaysLocationPermission.value &&
      hasNotificationPermission.value &&
      !isBackgroundRestricted.value;

  @override
  Future<void> openBackgroundUsageSettings() =>
      run('openBackgroundUsageSettings', const [], () {
        if (grantOnRequest) isBackgroundRestricted.value = false;
      });

  @override
  Future<void> notifyGpsDisabled() => run('notifyGpsDisabled', const [], () {});

  @override
  void dispose() {
    hasWhenInUseLocationPermission.dispose();
    hasAlwaysLocationPermission.dispose();
    hasNotificationPermission.dispose();
    isBackgroundRestricted.dispose();
  }
}
