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
data class Partner(val id: String, val name: String)

// AGP rejects flavor names starting with "test" and these reserved names.
val reservedPartnerIds = setOf("lint", "main", "debug", "release", "profile")
val partnerIdPattern = Regex("^[a-z][a-z0-9]*$")

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
        Partner(id, name)
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

    flavorDimensions += "partner"
    productFlavors {
        partners.forEach { partner ->
            create(partner.id) {
                dimension = "partner"
                applicationId = "org.monamienet.${partner.id}"
                // Set by key: Flutter keeps applicationName in the same map.
                manifestPlaceholders["appLabel"] = "MonAmie ${partner.name}"
            }
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
