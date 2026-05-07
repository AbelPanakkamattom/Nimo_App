plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nimo_app"

    compileSdk = 36

    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.example.nimo_app"

        minSdk = 24

        targetSdk = 36

        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility =
            JavaVersion.VERSION_17

        targetCompatibility =
            JavaVersion.VERSION_17

        // ✅ REQUIRED FOR
        // flutter_local_notifications
        isCoreLibraryDesugaringEnabled =
            true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false

            isShrinkResources = false

            signingConfig =
                signingConfigs.getByName(
                    "debug"
                )
        }
    }
}

dependencies {

    // ✅ REQUIRED FOR
    // flutter_local_notifications
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}

flutter {
    source = "../.."
}