import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';
import 'package:monamie_app/app/data/firebase/firebase_app_partner_firebase.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_error_app.dart';
import 'package:monamie_app/app/config/partner/partner_loader.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/firebase_options.dart';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/routes/app_pages.dart';
import 'app/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Partner.init(await _loadPartner());
  } on PartnerLoadException catch (error) {
    // A build without its partner cannot run; say why on screen and in the log.
    debugPrint(error.toString());
    runApp(PartnerErrorApp(message: error.message));
    return;
  }

  await Hive.initFlutter();
  Hive.registerAdapter(UserGoogleModelAdapter());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  CurrentPartnerFirebase.set(FirebaseAppPartnerFirebase(Firebase.app()));

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: Partner.current.displayName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}

/// Web has no `--flavor`: it reads the partner staged by
/// `dart run tool/partner.dart web <id>`. Other platforms read their
/// flavor-only asset.
Future<PartnerConfig> _loadPartner() async {
  if (!kIsWeb) {
    return loadPartnerConfig(bundle: rootBundle, flavor: appFlavor);
  }
  final client = http.Client();
  try {
    return await loadWebPartner(client: client, base: Uri.base);
  } finally {
    client.close();
  }
}
