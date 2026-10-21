import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "org.monamienet.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // One app for every partner: each partner's Firebase project and
        // branding are bound at runtime, after sign-in. Permanent on Play.
        applicationId = "org.monamienet.app"
        // The launcher and Play name; the partner's name shows inside the app.
        manifestPlaceholders["appLabel"] = "MonAmie"
        // Used by drawable[-v21]/launch_background.xml.
        resValue("color", "splash_background", "#FFFFFF")
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        // Off by default since AGP 9; needed for the resValue above.
        resValues = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Always signs with the upload key from android/key.properties.
            // validateReleaseSigning fails the build when it is missing instead
            // of falling back to the debug key, which Google Play rejects.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

val releaseSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

val validateReleaseSigning by tasks.registering {
    description = "Fails fast when the release signing config is incomplete."
    val propertiesFile = keystorePropertiesFile
    val properties = keystoreProperties
    val appDir = projectDir
    doLast {
        val guide = "See docs/pt-br/publicar-teste-interno.md (step B1)."
        if (!propertiesFile.exists()) {
            throw GradleException("Release signing: ${propertiesFile.path} not found. $guide")
        }
        val missing = releaseSigningKeys.filter { properties.getProperty(it).isNullOrBlank() }
        if (missing.isNotEmpty()) {
            throw GradleException("Release signing: key.properties is missing ${missing.joinToString()}. $guide")
        }
        val storeFile = appDir.resolve(properties.getProperty("storeFile"))
        if (!storeFile.isFile) {
            throw GradleException("Release signing: keystore not found at ${storeFile.path}. $guide")
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") {
        dependsOn(validateReleaseSigning)
    }
}

// The Firebase config (google-services.json) is never versioned: it holds API
// keys and its source of truth is the central MonAmie project (monamienet-app),
// used for sign-in. Partners' projects are bound at runtime, not here. Before
// the google-services plugin reads it (it only checks for the file when its
// process<Variant>GoogleServices task runs), fetch it with
// `dart run tool/partner.dart firebase`, only when the file is missing or
// REFRESH_FIREBASE_CONFIG=1.
val flutterSdkPath = Properties().run {
    rootProject.file("local.properties").inputStream().use { load(it) }
    getProperty("flutter.sdk") ?: throw GradleException("flutter.sdk not set in local.properties")
}
val refreshFirebaseConfig = providers.environmentVariable("REFRESH_FIREBASE_CONFIG").orNull == "1"

val fetchFirebaseConfig by tasks.registering(Exec::class) {
    val configFile = file("google-services.json")
    description = "Fetches ${configFile.path} from the central Firebase project monamienet-app."
    workingDir = rootProject.file("..")
    commandLine("$flutterSdkPath/bin/dart", "run", "tool/partner.dart", "firebase")
    onlyIf { refreshFirebaseConfig || !configFile.isFile }
}

val processGoogleServicesTask = Regex("^process\\w*GoogleServices$")

tasks.configureEach {
    if (processGoogleServicesTask.matches(name)) {
        dependsOn(fetchFirebaseConfig)
    }
}

// Flutter < 3.47 stages libapp.so (the compiled Dart code) in
// intermediates/flutter/<variant>/jniLibs. For flavored variants, AGP 9 merges
// that folder but leaves it out of the merge task's tracked inputs, so after a
// Dart-only change the merge is UP-TO-DATE and the APK keeps the previous
// libapp.so. Tracking the folder here makes the merge rerun. Fixed upstream in
// Flutter 3.47 (flutter/flutter#188119); remove this block after upgrading.
val mergeJniLibFoldersTask = Regex("^merge(\\w+)JniLibFolders$")

tasks.configureEach {
    val variant = mergeJniLibFoldersTask.matchEntire(name)?.groupValues?.get(1)
        ?.replaceFirstChar { it.lowercase() }
        ?: return@configureEach
    inputs.files(layout.buildDirectory.dir("intermediates/flutter/$variant/jniLibs"))
        .withPropertyName("flutterJniLibs")
        .withPathSensitivity(PathSensitivity.RELATIVE)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // MonAmieApplication.kt creates the partner FirebaseApp natively. Same
    // BoM as firebase_core 4.15.0 (its android/gradle.properties); Gradle
    // picks the higher one if the plugin moves ahead.
    implementation(platform("com.google.firebase:firebase-bom:34.19.0"))
    implementation("com.google.firebase:firebase-common")
}
