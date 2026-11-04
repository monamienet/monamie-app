import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monamie_app/ui/core/ui/organization_error_app.dart';
import 'package:monamie_app/data/services/firebase/central_firebase.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/config/dependencies.dart';
import 'package:provider/provider.dart';

import 'ui/core/monamie_app.dart';

Future<void> main() async {
  // Web URLs without `#`: the server answers every path with index.html
  // (tool/serve_web.dart locally). Does nothing on Android and iOS.
  usePathUrlStrategy();
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

  // Errors nothing else caught go to the crash reports: those the framework
  // caught (build, layout, gestures) and those of asynchronous code.
  final crashReporting = createCrashReportingService();
  await crashReporting.start();
  FlutterError.onError = crashReporting.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    crashReporting.recordError(error, stackTrace, fatal: true);
    return true;
  };

  // The organization remembered from the last sign-in, if any: the app opens in
  // its brand without asking the central project again.
  final session = createOrganizationSession();
  final brandingLoader = createBrandingLoader();
  // The language chosen, read before the first frame so it is drawn in it.
  final language = createLanguageRepository();
  await language.restore();
  final binding = await session.restore();
  if (binding != null) {
    // Picks up branding changes for the next launch, without changing the
    // look of this one.
    brandingLoader.readBranding(binding).then(session.storeBranding).ignore();
  }

  runApp(
    MultiProvider(
      providers: appDependencies(
        organizationSession: session,
        brandingLoader: brandingLoader,
        languageRepository: language,
        crashReporting: crashReporting,
      ),
      child: const MonAmieApp(),
    ),
  );
}
