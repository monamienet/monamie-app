import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monamie_app/ui/core/ui/organization_error_app.dart';
import 'package:monamie_app/data/services/firebase/central_firebase.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';

import 'ui/core/monamie_app.dart';

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

  runApp(const MonAmieApp());
}
