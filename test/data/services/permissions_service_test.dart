import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/services/permissions_service.dart';

/// The permission_handler plugin's channel: the only place where the
/// service meets the platform, so these tests answer it.
const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

/// `Permission.value` of each [AppPermission] in the plugin's protocol.
const _permissionValues = {
  AppPermission.locationAlways: 4,
  AppPermission.locationWhenInUse: 5,
  AppPermission.notification: 17,
};

/// `PermissionStatus.value` in the plugin's protocol, with the status the
/// service must translate it to.
const _statuses = [
  (0, AppPermissionStatus.denied),
  (1, AppPermissionStatus.granted),
  (2, AppPermissionStatus.restricted),
  (3, AppPermissionStatus.limited),
  (4, AppPermissionStatus.permanentlyDenied),
  (5, AppPermissionStatus.provisional),
];

/// The calls the channel received, in order.
late List<MethodCall> _calls;

/// Answers every status check and every request with [status], and
/// opening the settings with [opened].
void _answer({int status = 0, Object? opened = true}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        _calls.add(call);
        switch (call.method) {
          case 'checkPermissionStatus':
            return status;
          case 'requestPermissions':
            return {
              for (final permission in call.arguments as List)
                permission: status,
            };
          case 'openAppSettings':
            return opened;
        }
        return null;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _calls = []);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('PermissionsService.request - Unit Test Suite', () {
    for (final (value, expected) in _statuses) {
      test(
        'Happy Path: the plugin status $value is ${expected.name}',
        () async {
          // 1. Arrange
          _answer(status: value);
          const service = PermissionsService();

          // 2. Act
          final status = await service.request(AppPermission.notification);

          // 3. Assert
          expect(status, expected);
        },
      );
    }

    for (final MapEntry(key: permission, value: value)
        in _permissionValues.entries) {
      test('Edge Case: ${permission.name} asks the plugin for permission '
          '$value', () async {
        // 1. Arrange
        _answer(status: 1);
        const service = PermissionsService();

        // 2. Act
        await service.request(permission);

        // 3. Assert
        expect(_calls.single.method, 'requestPermissions');
        expect(_calls.single.arguments, [value]);
      });
    }

    test('Sad Path: a plugin failure reaches the caller', () async {
      // 1. Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (_) async {
            throw PlatformException(code: 'boom');
          });
      const service = PermissionsService();

      // 2. Act
      final request = service.request(AppPermission.locationAlways);

      // 3. Assert
      await expectLater(request, throwsA(isA<PlatformException>()));
    });
  });

  group('PermissionsService.isGranted - Unit Test Suite', () {
    test('Happy Path: granted is granted', () async {
      // 1. Arrange
      _answer(status: 1);
      const service = PermissionsService();

      // 2. Act
      final granted = await service.isGranted(AppPermission.locationWhenInUse);

      // 3. Assert
      expect(granted, isTrue);
      expect(_calls.single.method, 'checkPermissionStatus');
      expect(_calls.single.arguments, 5);
    });

    test('Edge Case: limited is not granted', () async {
      // 1. Arrange
      _answer(status: 3);
      const service = PermissionsService();

      // 2. Act
      final granted = await service.isGranted(AppPermission.locationAlways);

      // 3. Assert
      expect(granted, isFalse);
    });

    test('Sad Path: permanently denied is not granted', () async {
      // 1. Arrange
      _answer(status: 4);
      const service = PermissionsService();

      // 2. Act
      final granted = await service.isGranted(AppPermission.notification);

      // 3. Assert
      expect(granted, isFalse);
    });
  });

  group('PermissionsService.isPermanentlyDenied - Unit Test Suite', () {
    test('Happy Path: permanently denied is permanently denied', () async {
      // 1. Arrange
      _answer(status: 4);
      const service = PermissionsService();

      // 2. Act
      final denied = await service.isPermanentlyDenied(
        AppPermission.notification,
      );

      // 3. Assert
      expect(denied, isTrue);
      expect(_calls.single.arguments, 17);
    });

    test('Edge Case: denied (it can still be asked) is not for good', () async {
      // 1. Arrange
      _answer(status: 0);
      const service = PermissionsService();

      // 2. Act
      final denied = await service.isPermanentlyDenied(
        AppPermission.locationWhenInUse,
      );

      // 3. Assert
      expect(denied, isFalse);
    });

    test('Sad Path: granted is not permanently denied', () async {
      // 1. Arrange
      _answer(status: 1);
      const service = PermissionsService();

      // 2. Act
      final denied = await service.isPermanentlyDenied(
        AppPermission.locationAlways,
      );

      // 3. Assert
      expect(denied, isFalse);
    });
  });

  group('PermissionsService.openSettings - Unit Test Suite', () {
    test('Happy Path: answers true when the settings opened', () async {
      // 1. Arrange
      _answer(opened: true);
      const service = PermissionsService();

      // 2. Act
      final opened = await service.openSettings();

      // 3. Assert
      expect(opened, isTrue);
      expect(_calls.single.method, 'openAppSettings');
    });

    test('Edge Case: a null answer counts as not opened', () async {
      // 1. Arrange
      _answer(opened: null);
      const service = PermissionsService();

      // 2. Act
      final opened = await service.openSettings();

      // 3. Assert
      expect(opened, isFalse);
    });

    test('Sad Path: answers false when the settings could not open', () async {
      // 1. Arrange
      _answer(opened: false);
      const service = PermissionsService();

      // 2. Act
      final opened = await service.openSettings();

      // 3. Assert
      expect(opened, isFalse);
    });
  });

  group('AppPermissionStatus getters - Unit Test Suite', () {
    test('Happy Path: only granted is granted', () {
      // 1. Arrange
      const all = AppPermissionStatus.values;

      // 2. Act
      final granted = all.where((s) => s.isGranted);

      // 3. Assert
      expect(granted, [AppPermissionStatus.granted]);
    });

    test('Edge Case: only permanentlyDenied is permanently denied', () {
      // 1. Arrange
      const all = AppPermissionStatus.values;

      // 2. Act
      final denied = all.where((s) => s.isPermanentlyDenied);

      // 3. Assert
      expect(denied, [AppPermissionStatus.permanentlyDenied]);
    });

    test('Sad Path: provisional and limited are not granted', () {
      // 1. Arrange
      const partial = [
        AppPermissionStatus.provisional,
        AppPermissionStatus.limited,
      ];

      // 2. Act
      final granted = partial.map((s) => s.isGranted);

      // 3. Assert
      expect(granted, [false, false]);
    });
  });
}
