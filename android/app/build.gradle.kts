plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.yourcompany.epubreader" // or your actual namespace
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.epub_reader"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}


flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))
    implementation("com.google.firebase:firebase-analytics")
    // other dependencies...
}
