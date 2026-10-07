Below, nesting indicates dependency (*in* depends on *out*).

- Create a new Firebase Project
    - Enable Firestore (***manually***)
    - Enable Google as a login provider (***manually***)
    - Generate sha-(1|256) fingerprints with `cd android/ && ./gradlew signingReport`
        - add fingerprints to the corresponding app in Firebase (***manually***)
            - add `google-services.json`, `GoogleService-Info.plist` and `firebase_options.dart` with `flutterfire configure --project=monamienet-<client_name> -y`
- Change package name `dart run change_app_package_name:main org.monamienet.<client_name>`
- Change app name with `dart run rename_app:main all="MonAmie <client_name>"`
- Create a new google group $g$ (***manually***)
    - Assign $g$ to `rootGroupEmail`