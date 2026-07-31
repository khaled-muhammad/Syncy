plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningValues =
    mapOf(
        "ANDROID_KEYSTORE_PATH" to providers.environmentVariable("ANDROID_KEYSTORE_PATH").orNull,
        "ANDROID_KEYSTORE_PASSWORD" to providers.environmentVariable("ANDROID_KEYSTORE_PASSWORD").orNull,
        "ANDROID_KEY_ALIAS" to providers.environmentVariable("ANDROID_KEY_ALIAS").orNull,
        "ANDROID_KEY_PASSWORD" to providers.environmentVariable("ANDROID_KEY_PASSWORD").orNull,
    )

val missingReleaseSigningValues =
    releaseSigningValues
        .filterValues { it.isNullOrBlank() }
        .keys

val releaseBuildRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }

if (releaseBuildRequested && missingReleaseSigningValues.isNotEmpty()) {
    throw GradleException(
        "Release signing is not configured. Missing environment variable(s): " +
            missingReleaseSigningValues.joinToString() +
            ". See docs/android-signing.md.",
    )
}

android {
    namespace = "com.example.syncy"
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
        applicationId = "com.example.syncy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (missingReleaseSigningValues.isEmpty()) {
                val keystoreFile = file(checkNotNull(releaseSigningValues["ANDROID_KEYSTORE_PATH"]))

                if (releaseBuildRequested && !keystoreFile.isFile) {
                    throw GradleException(
                        "Release keystore does not exist at ${keystoreFile.absolutePath}.",
                    )
                }

                storeFile = keystoreFile
                storePassword = releaseSigningValues["ANDROID_KEYSTORE_PASSWORD"]
                keyAlias = releaseSigningValues["ANDROID_KEY_ALIAS"]
                keyPassword = releaseSigningValues["ANDROID_KEY_PASSWORD"]
            }
        }
    }

    buildTypes {
        debug {
            // Keep diagnostic builds installable beside a signed release so
            // testing never clears the user's paired-device state.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            // Never fall back to the machine-specific debug key for a distributable build.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
