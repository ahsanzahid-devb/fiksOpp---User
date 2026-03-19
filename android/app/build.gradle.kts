plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Must match the applicationId already registered on Google Play (cannot be changed there).
    namespace = "buzz.inoor.fiksopp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "buzz.inoor.fiksopp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Same as Groovy build.gradle: read pubspec so versionCode is never stale from local.properties.
        val pubspecFile = rootProject.projectDir.parentFile.resolve("pubspec.yaml")
        var resolvedCode = flutter.versionCode
        var resolvedName = flutter.versionName
        if (pubspecFile.exists()) {
            val verLine = pubspecFile.readLines()
                .firstOrNull { it.trimStart().startsWith("version:") }
            if (verLine != null) {
                val raw = verLine.substringAfter("version:").trim().removeSurrounding("\"")
                val plus = raw.indexOf('+')
                if (plus > 0) {
                    resolvedName = raw.substring(0, plus).trim()
                    val digits = raw.substring(plus + 1).filter { it.isDigit() }
                    digits.toIntOrNull()?.let { resolvedCode = it }
                }
            }
        }
        versionCode = resolvedCode
        versionName = resolvedName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
