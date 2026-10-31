import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_error_app.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/organization/organization_branding_loader.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';

import 'app/routes/app_pages.dart';
import 'app/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserGoogleModelAdapter());

  try {
    await CentralFirebase.initialize();
  } on CentralFirebaseException catch (error) {
    // A web build without its staged config cannot sign in; say why.
    debugPrint(error.toString());
    runApp(OrganizationErrorApp(message: error.message));
    return;
  }

  // The organization remembered from the last sign-in, if any: the app opens in
  // its brand without asking the central project again.
  final session = OrganizationSession();
  final binding = await session.restore();
  if (binding != null) {
    // Picks up branding changes for the next launch, without changing the
    // look of this one.
    OrganizationBrandingLoader()
        .readBranding(binding)
        .then(session.storeBranding)
        .ignore();
  }

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: Organization.current?.name ?? MonAmieBrand.name,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
