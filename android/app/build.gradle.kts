plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.nimo_app"

    compileSdk = 36   // ✅ FIXED

    ndkVersion = "28.2.13676358"   // ✅ REQUIRED BY jni plugin

    defaultConfig {
        applicationId = "com.example.nimo_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36   // ✅ FIXED

        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false   // ✅ IMPORTANT FIX
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
