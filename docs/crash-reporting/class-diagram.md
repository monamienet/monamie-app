# Crash reporting: class diagram

Components added by issue #243 (Crashlytics base setup). Reports from every
organization and plan go to the central project `monamienet-app` (the
`[DEFAULT]` Firebase app) and carry no personal data.

```mermaid
classDiagram
    direction LR

    class CrashReportingService {
        <<interface>>
        +start() Future~void~
        +recordFlutterFatalError(FlutterErrorDetails details) Future~void~
        +recordError(Object error, StackTrace? stackTrace, bool fatal) Future~void~
    }

    class FirebaseCrashReportingService {
        -FirebaseCrashlytics _crashlytics
        +start() Future~void~
        +recordFlutterFatalError(FlutterErrorDetails details) Future~void~
        +recordError(Object error, StackTrace? stackTrace, bool fatal) Future~void~
    }

    class NoOpCrashReportingService {
        +start() Future~void~
        +recordFlutterFatalError(FlutterErrorDetails details) Future~void~
        +recordError(Object error, StackTrace? stackTrace, bool fatal) Future~void~
    }

    class FirebaseCrashlytics {
        <<plugin firebase_crashlytics>>
        +setCrashlyticsCollectionEnabled(bool enabled)
        +recordFlutterFatalError(FlutterErrorDetails details)
        +recordError(Object error, StackTrace? stack, bool fatal)
    }

    class appDependencies {
        <<function, lib/config/dependencies.dart>>
        +appDependencies(CrashReportingService crashReporting, ...) List~Provider~
    }

    class createCrashReportingService {
        <<function, lib/config/dependencies.dart>>
        +createCrashReportingService() CrashReportingService
    }

    class main {
        <<function, lib/main.dart>>
        FlutterError.onError
        PlatformDispatcher.instance.onError
    }

    class TestApp {
        <<test, test/support/test_app.dart>>
        +dependencies
    }

    CrashReportingService <|.. FirebaseCrashReportingService : implements
    CrashReportingService <|.. NoOpCrashReportingService : implements
    FirebaseCrashReportingService --> FirebaseCrashlytics : forwards to

    createCrashReportingService ..> FirebaseCrashReportingService : creates on mobile
    createCrashReportingService ..> NoOpCrashReportingService : creates on web (kIsWeb)

    main ..> createCrashReportingService : calls after CentralFirebase.initialize()
    main --> CrashReportingService : start(), wires both error handlers
    main ..> appDependencies : passes crashReporting

    appDependencies o-- CrashReportingService : Provider.value
    TestApp o-- NoOpCrashReportingService : Provider.value
```

## Reading the diagram

- **Contract and implementations** live in `lib/data/services/crash_reporting/`,
  one file each. Only the Firebase implementation imports the plugin, as
  `tool/check_layers.dart` requires.
- **Error flow**: `main` sets `FlutterError.onError` to
  `recordFlutterFatalError` and `PlatformDispatcher.instance.onError` to
  `recordError(fatal: true)`; both end in the plugin's fatal path.
- **Debug builds**: `FirebaseCrashReportingService.start()` turns collection
  off when `kDebugMode`.
- **Why `main` creates the service**: it must exist before `runApp`, so
  `appDependencies` receives it instead of building it.
- **Tests**: `TestApp` provides `NoOpCrashReportingService`, and
  `test/config/dependencies_test.dart` checks `appDependencies` provides the
  same types.
