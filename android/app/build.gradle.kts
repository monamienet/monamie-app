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
    namespace = "org.monamienet.aquariustur"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.monamienet.aquariustur"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
        val guide = "See docs/pt-br/publicar-teste-interno.md (step 2)."
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
