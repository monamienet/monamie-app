import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/firebase_options.dart';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UserGoogleModelAdapter());

  await Firebase.initializeApp(
    //name: 'uffmobileplus',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
