import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/services/language_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform interface is a transitive dependency of shared_preferences
// and provides its official in-memory backend for tests.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('LanguagePreferencesService - Unit Test Suite', () {
    test('Happy Path: a written language is read back', () async {
      // 1. Arrange
      final service = LanguagePreferencesService();

      // 2. Act
      await service.write('en');
      final read = await service.read();

      // 3. Assert
      expect(read, 'en');
    });

    test('Happy Path: a new service reads what another one wrote', () async {
      // 1. Arrange
      await LanguagePreferencesService().write('pt');

      // 2. Act
      final read = await LanguagePreferencesService().read();

      // 3. Assert
      expect(read, 'pt');
    });

    test('Edge Case: nothing stored reads as null', () async {
      // 1. Arrange
      final service = LanguagePreferencesService();

      // 2. Act
      final read = await service.read();

      // 3. Assert
      expect(read, isNull);
    });

    test('Edge Case: writing again replaces the language', () async {
      // 1. Arrange
      final service = LanguagePreferencesService();
      await service.write('pt');

      // 2. Act
      await service.write('en');

      // 3. Assert
      expect(await service.read(), 'en');
    });

    test('Edge Case: the language is stored under its key', () async {
      // 1. Arrange
      final service = LanguagePreferencesService();

      // 2. Act
      await service.write('en');

      // 3. Assert
      expect(
        await SharedPreferencesAsync().getString(
          LanguagePreferencesService.key,
        ),
        'en',
      );
    });
  });
}
