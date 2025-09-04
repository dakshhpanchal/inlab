plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // updated syntax for Kotlin plugin
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.inlab"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Enable desugaring for Java 8+ APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.inlab"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // in case QR lib or Firebase is added later
    }

    buildTypes {
        release {
            // Using debug keys for now
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // This helps avoid duplicate class issues in some libs
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0"
            )
        }
    }
}

dependencies {
    // Required for Java 8+ API desugaring (QR Scanner needs this)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Kotlin standard library
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.25")
}

flutter {
    source = "../.."
}
