import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/membership/organization_membership_check.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/ui/core/monamie_app.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/core/themes/app_theme.dart';
import 'package:provider/provider.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<AuthGoogleService>(),
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<GoogleBondCheck>(),
  MockSpec<InvitesRepository>(),
  MockSpec<OrganizationBrandingLoader>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<OrganizationLocalData>(),
  MockSpec<OrganizationMembershipCheck>(),
  MockSpec<OrganizationSession>(),
  MockSpec<UserGoogleRepository>(),
])
import 'monamie_app_test.mocks.dart';

/// Opens the app over the data layer it reads (mocks, provided as
/// `appDependencies` is in `main`). Its real sign-in controller starts:
/// the mocked Google Sign-In initializes at once, so *Login* shows the
/// Google button. Not `pumpAndSettle`, in case a spinner stays.
Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthGoogleService>.value(value: MockAuthGoogleService()),
        Provider<UserGoogleRepository>.value(value: MockUserGoogleRepository()),
        Provider<BackgroundTrackingStopper>.value(
          value: MockBackgroundTrackingStopper(),
        ),
        Provider<OrganizationDirectory>.value(
          value: MockOrganizationDirectory(),
        ),
        Provider<OrganizationBrandingLoader>.value(
          value: MockOrganizationBrandingLoader(),
        ),
        Provider<OrganizationSession>.value(value: MockOrganizationSession()),
        Provider<OrganizationLocalData>.value(
          value: MockOrganizationLocalData(),
        ),
        Provider<InvitesRepository>.value(value: MockInvitesRepository()),
        Provider<AccountDeletionRepository>.value(
          value: MockAccountDeletionRepository(),
        ),
        Provider<OrganizationMembershipCheck>.value(
          value: MockOrganizationMembershipCheck(),
        ),
        Provider<GoogleBondCheck>.value(value: MockGoogleBondCheck()),
      ],
      child: const MonAmieApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  provideDummy<Result<List<Invite>>>(const Ok(<Invite>[]));
  provideDummy<Result<AccountDeletion?>>(const Ok(null));

  group('MonAmieApp (app scope) - Widget Test Suite', () {
    testWidgets('Happy Path: the app opens on Login, whose route finds the '
        'sign-in controller above the router', (tester) async {
      // 1. Arrange
      // (nothing: the app builds its own controller and router)

      // 2. Act
      await _pumpApp(tester);

      // 3. Assert
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: the router starts on the theme of the bound '
        'organization', (tester) async {
      // 1. Arrange
      final expected = AppTheme.lightTheme;

      // 2. Act
      await _pumpApp(tester);

      // 3. Assert
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, expected);
      expect(app.themeMode, ThemeMode.light);
    });

    testWidgets('Sad Path: closing the app releases the router, the '
        'controller and the theme without errors', (tester) async {
      // 1. Arrange
      await _pumpApp(tester);

      // 2. Act
      await tester.pumpWidget(const SizedBox());

      // 3. Assert
      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}
