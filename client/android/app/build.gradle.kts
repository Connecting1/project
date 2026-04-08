plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.login_test"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.login_test"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    api(project(":unityLibrary"))
    // Stub for android.window.OnBackInvokedCallback (Android 13+ API).
    // Unity 2022.3 references it via reflection; without this, nativeRender()
    // throws NoClassDefFoundError every frame on Android < 13 → black screen.
    runtimeOnly(project(":compat-stubs"))
}

flutter {
    source = "../"
}
