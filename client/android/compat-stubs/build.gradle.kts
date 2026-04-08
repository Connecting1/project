plugins {
    id("com.android.library")
}

android {
    // compileSdk 32 (Android 12L): OnBackInvokedCallback was added in API 33,
    // so it does NOT exist in API 32's android.jar — no duplicate class conflict.
    namespace = "com.example.login_test.compat"
    compileSdk = 32

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}
