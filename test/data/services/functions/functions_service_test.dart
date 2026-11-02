import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';
import 'package:monamie_app/data/services/firebase/organization_firebase.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFunctions>(),
  MockSpec<HttpsCallable>(),
  MockSpec<HttpsCallableResult<Object?>>(),
  MockSpec<OrganizationFirebase>(),
])
import 'functions_service_test.mocks.dart';

// `FunctionsService.call` is shared by both subclasses; it is exercised
// through `OrganizationFunctionsService`, whose project comes from
// `CurrentOrganizationFirebase` and can be replaced by a mock. The central
// subclass reads `Firebase.app()`, which needs a platform.

late MockFirebaseFunctions firebaseFunctions;
late MockHttpsCallable callable;

/// Makes the callable answer [data].
void callableAnswers(Object? data) {
  final result = MockHttpsCallableResult();
  when(result.data).thenReturn(data);
  when(callable.call<Object?>(any)).thenAnswer((_) async => result);
}

/// Makes the callable fail with [error].
void callableFails(Object error) =>
    when(callable.call<Object?>(any)).thenAnswer((_) async => throw error);

void main() {
  setUp(() {
    firebaseFunctions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    when(
      firebaseFunctions.httpsCallable(any, options: anyNamed('options')),
    ).thenReturn(callable);
    final organization = MockOrganizationFirebase();
    when(organization.functions).thenReturn(firebaseFunctions);
    CurrentOrganizationFirebase.set(organization);
  });

  tearDown(CurrentOrganizationFirebase.debugReset);

  group('FunctionsService.call - Unit Test Suite', () {
    test('Happy Path: calls the named function with the data and returns '
        'what it returned', () async {
      // 1. Arrange
      callableAnswers({'ok': true});

      // 2. Act
      final data = await const OrganizationFunctionsService().call(
        'setBranding',
        {'organizationId': 'rotasul'},
      );

      // 3. Assert
      expect(data, {'ok': true});
      verify(
        firebaseFunctions.httpsCallable(
          'setBranding',
          options: anyNamed('options'),
        ),
      ).called(1);
      verify(callable.call<Object?>({'organizationId': 'rotasul'})).called(1);
    });

    test('Edge Case: the timeout defaults to 60 seconds', () async {
      // 1. Arrange
      callableAnswers(null);

      // 2. Act
      await const OrganizationFunctionsService().call('setBranding', {});

      // 3. Assert
      final options =
          verify(
                firebaseFunctions.httpsCallable(
                  any,
                  options: captureAnyNamed('options'),
                ),
              ).captured.single
              as HttpsCallableOptions;
      expect(options.timeout, const Duration(seconds: 60));
    });

    test('Edge Case: a given timeout reaches the callable', () async {
      // 1. Arrange
      callableAnswers(null);

      // 2. Act
      await const OrganizationFunctionsService().call(
        'setBranding',
        {},
        timeout: const Duration(seconds: 90),
      );

      // 3. Assert
      final options =
          verify(
                firebaseFunctions.httpsCallable(
                  any,
                  options: captureAnyNamed('options'),
                ),
              ).captured.single
              as HttpsCallableOptions;
      expect(options.timeout, const Duration(seconds: 90));
    });

    test('Sad Path: a FirebaseFunctionsException becomes a FunctionsFailure '
        'with its code and message', () async {
      // 1. Arrange
      callableFails(
        FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Sem permissão.',
        ),
      );

      // 2. Act
      final call = const OrganizationFunctionsService().call('setBranding', {});

      // 3. Assert
      await expectLater(
        call,
        throwsA(
          isA<FunctionsFailure>()
              .having((f) => f.code, 'code', 'permission-denied')
              .having((f) => f.message, 'message', 'Sem permissão.'),
        ),
      );
    });

    test('Sad Path: any other error passes through as it came', () async {
      // 1. Arrange
      final error = StateError('offline');
      callableFails(error);

      // 2. Act
      final call = const OrganizationFunctionsService().call('setBranding', {});

      // 3. Assert
      await expectLater(call, throwsA(same(error)));
    });
  });

  group('FunctionsFailure - Unit Test Suite', () {
    test('Happy Path: toString names the code and the message', () {
      // 1. Arrange
      const failure = FunctionsFailure('not-found', 'Grupo não encontrado.');

      // 2. Act
      final text = failure.toString();

      // 3. Assert
      expect(text, 'FunctionsFailure(not-found: Grupo não encontrado.)');
    });
  });
}
