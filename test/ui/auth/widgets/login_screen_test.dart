import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/membership/organization_membership_check.dart';
import 'package:monamie_app/data/repositories/organization/organization_binder.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/ui/auth/view_models/auth_google_view_model.dart';
import 'package:monamie_app/ui/auth/view_models/login_view_model.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/core/ui/notice_presenter.dart';

// mockito cannot generate a mock of `AuthGoogleViewModel` (its builder
// fails with "Bad state: No element"), so the screen gets a real one that
// never starts: nothing it does here reaches its services.
@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<AuthGoogleService>(),
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<InvitesRepository>(),
  MockSpec<LoginViewModel>(),
  MockSpec<NoticePresenter>(),
  MockSpec<OrganizationBinder>(),
  MockSpec<OrganizationBrandingLoader>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<OrganizationLocalData>(),
  MockSpec<OrganizationMembershipCheck>(),
  MockSpec<UserGoogleRepository>(),
])
import 'login_screen_test.mocks.dart';

/// A [MockLoginViewModel] still restoring, whose restore finishes at once.
MockLoginViewModel _loginViewModel() {
  final controller = MockLoginViewModel();
  when(controller.state).thenReturn(const LoginState());
  when(controller.restoreSession()).thenAnswer((_) async {});
  return controller;
}

/// An [AuthGoogleViewModel] never started (Google not ready yet).
AuthGoogleViewModel _auth() => AuthGoogleViewModel(
  notices: MockNoticePresenter(),
  refreshTheme: () {},
  authGoogle: MockAuthGoogleService(),
  userRepository: MockUserGoogleRepository(),
  trackingStopper: MockBackgroundTrackingStopper(),
  organizationDirectory: MockOrganizationDirectory(),
  brandingLoader: MockOrganizationBrandingLoader(),
  organizationSession: MockOrganizationBinder(),
  organizationLocalData: MockOrganizationLocalData(),
  invitesRepository: MockInvitesRepository(),
  deletionRepository: MockAccountDeletionRepository(),
  membershipCheck: MockOrganizationMembershipCheck(),
);

void main() {
  group('LoginScreen - Unit Test Suite', () {
    testWidgets('Happy Path: the first frame restores the session once', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final controller = _loginViewModel();

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(controller: controller, auth: _auth()),
        ),
      );

      // 3. Assert
      verify(controller.restoreSession()).called(1);
    });

    testWidgets('Edge Case: later frames do not restore the session again', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final controller = _loginViewModel();
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(controller: controller, auth: _auth()),
        ),
      );

      // 2. Act
      await tester.pump(const Duration(seconds: 1));

      // 3. Assert
      verify(controller.restoreSession()).called(1);
    });

    testWidgets(
      'Sad Path: a session still being restored shows the spinner, not the Google button',
      (WidgetTester tester) async {
        // 1. Arrange
        final controller = _loginViewModel();

        // 2. Act
        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(controller: controller, auth: _auth()),
          ),
        );

        // 3. Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
