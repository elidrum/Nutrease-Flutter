plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Auto-create env.json from the versioned env.json.template (mirrors Android's
// local.properties). This runs during Gradle configuration — i.e. on every IDE
// sync and every build — so a freshly cloned repo gets env.json automatically.
// env.json itself is gitignored: fill in your real Supabase keys there.
run {
    val envJson = rootProject.file("../env.json")
    val envTemplate = rootProject.file("../env.json.template")
    if (!envJson.exists() && envTemplate.exists()) {
        envTemplate.copyTo(envJson)
        logger.lifecycle(
            "env.json created from env.json.template — set your Supabase keys before running.",
        )
    }
}

android {
    namespace = "com.example.nutrease_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nutrease_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
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
