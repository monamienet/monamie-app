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

// Each partners/<id>/partner.json becomes one product flavor. The id is
// permanent: it becomes the Play application id (org.monamienet.<id>).
data class Partner(val id: String, val name: String, val splashBackground: String, val resDir: File)

// AGP rejects flavor names starting with "test" and these reserved names.
val reservedPartnerIds = setOf("lint", "main", "debug", "release", "profile")
val partnerIdPattern = Regex("^[a-z][a-z0-9]*$")
val hexColorPattern = Regex("^#[0-9A-Fa-f]{6}$")

// Brand resources each partner must provide under partners/<id>/android/res.
// src/main/res has none of them, so a missing file can never fall back to
// another partner's brand.
val requiredPartnerResources = listOf("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi")
    .map { "mipmap-$it/ic_launcher.png" } + "drawable/launch_image.png"

val partnersDir = rootProject.file("../partners")
val partners: List<Partner> = partnersDir.listFiles()
    .orEmpty()
    .filter { it.resolve("partner.json").isFile }
    .sortedBy { it.name }
    .map { dir ->
        val id = dir.name
        val partnerFile = dir.resolve("partner.json")
        if (!partnerIdPattern.matches(id) || id.startsWith("test") || id in reservedPartnerIds) {
            throw GradleException(
                "Invalid partner id '$id' (${partnerFile.path}): it must match $partnerIdPattern, " +
                    "not start with 'test' and not be one of ${reservedPartnerIds.joinToString()}."
            )
        }
        val json = try {
            groovy.json.JsonSlurper().parseText(partnerFile.readText()) as? Map<*, *>
        } catch (e: groovy.json.JsonException) {
            // The rest of the message dumps the parser's buffer.
            val reason = e.message.orEmpty().lineSequence().first()
            throw GradleException("${partnerFile.path} is not valid JSON: $reason")
        } ?: throw GradleException("${partnerFile.path} must contain a JSON object.")
        val name = (json["name"] as? String)?.takeIf { it.isNotBlank() }
            ?: throw GradleException("${partnerFile.path}: \"name\" must be a non-empty string.")
        val secondary = ((json["colors"] as? Map<*, *>)?.get("secondary") as? String)
            ?.takeIf { hexColorPattern.matches(it) }
            ?: throw GradleException("${partnerFile.path}: \"colors.secondary\" must be a color like \"#RRGGBB\".")
        val resDir = dir.resolve("android/res")
        val missing = requiredPartnerResources.filterNot { resDir.resolve(it).isFile }
        if (missing.isNotEmpty()) {
            throw GradleException(
                "Partner '$id' is missing brand resources in ${resDir.path}: ${missing.joinToString()}."
            )
        }
        Partner(id, name, secondary, resDir)
    }

if (partners.isEmpty()) {
    throw GradleException("No partner found: expected ${partnersDir.path}/<id>/partner.json.")
}

// Without --flavor, Flutter requests e.g. assembleRelease, which builds every
// partner and then fails with a generic "couldn't find the .apk" error (or
// installs a stale APK). Fail before that with the list of valid flavors.
val flavorlessTask = Regex("^(:app:)?(assemble|bundle|install)(Debug|Profile|Release)$")
gradle.startParameter.taskNames.firstOrNull { flavorlessTask.matches(it) }?.let { task ->
    throw GradleException(
        "'$task' does not select a partner. Pass --flavor <id> to flutter run/build. " +
            "Partners: ${partners.joinToString { it.id }}."
    )
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
        // The application id is set per partner flavor (productFlavors below).
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        // Off by default since AGP 9; needed for the per-partner resValue below.
        resValues = true
    }

    flavorDimensions += "partner"
    productFlavors {
        partners.forEach { partner ->
            create(partner.id) {
                dimension = "partner"
                applicationId = "org.monamienet.${partner.id}"
                // Set by key: Flutter keeps applicationName in the same map.
                manifestPlaceholders["appLabel"] = "MonAmie ${partner.name}"
                // Used by drawable[-v21]/launch_background.xml.
                resValue("color", "splash_background", partner.splashBackground)
            }
        }
    }

    // Each flavor only sees its own partner's icons and splash image.
    sourceSets {
        partners.forEach { partner ->
            getByName(partner.id).res.srcDir(partner.resDir)
        }
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

// With flavors, every release variant has its own pre<Flavor>ReleaseBuild task.
val preReleaseBuildTask = Regex("^pre[A-Z]\\w*ReleaseBuild$")

tasks.configureEach {
    if (preReleaseBuildTask.matches(name)) {
        dependsOn(validateReleaseSigning)
    }
}

// The Firebase config (google-services.json) is never versioned: it holds API
// keys and its source of truth is the partner's own Firebase project. Before
// the google-services plugin reads it from src/<id>/ (it only checks for the
// file when its process<Variant>GoogleServices task runs), fetch it with
// `dart run tool/partner.dart firebase <id>`. Only the flavor being built is
// fetched, and only when the file is missing or PARTNER_REFRESH_FIREBASE=1.
val flutterSdkPath = Properties().run {
    rootProject.file("local.properties").inputStream().use { load(it) }
    getProperty("flutter.sdk") ?: throw GradleException("flutter.sdk not set in local.properties")
}
val refreshFirebaseConfig = providers.environmentVariable("PARTNER_REFRESH_FIREBASE").orNull == "1"

val fetchFirebaseConfigTasks = partners.associate { partner ->
    val configFile = file("src/${partner.id}/google-services.json")
    val taskName = "fetchFirebaseConfig${partner.id.replaceFirstChar { it.uppercase() }}"
    partner.id to tasks.register<Exec>(taskName) {
        description = "Fetches ${configFile.path} from Firebase project monamienet-${partner.id}."
        workingDir = rootProject.file("..")
        commandLine("$flutterSdkPath/bin/dart", "run", "tool/partner.dart", "firebase", partner.id)
        onlyIf { refreshFirebaseConfig || !configFile.isFile }
    }
}

// Partner ids are lowercase letters and digits, so the capitalized id ends
// where the build type starts.
val processGoogleServicesTask = Regex("^process([A-Z][a-z0-9]*)(Debug|Profile|Release)GoogleServices$")

tasks.configureEach {
    val id = processGoogleServicesTask.matchEntire(name)?.groupValues?.get(1)?.lowercase()
        ?: return@configureEach
    fetchFirebaseConfigTasks[id]?.let { dependsOn(it) }
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
