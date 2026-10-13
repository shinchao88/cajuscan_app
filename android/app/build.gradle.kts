plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.marotoweb.cajuscan_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.marotoweb.cajuscan_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Reproduciblity
    // Remove files that vary between builds and break the SHA-256 hash.
    packaging {
        resources {
            excludes += "assets/dexopt/*"
            excludes += "META-INF/*.kotlin_module"
        }
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    val hasKeyProperties = keystorePropertiesFile.exists()
    if (hasKeyProperties) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        // Configure signing dynamically.
        create("release") {
            if (hasKeyProperties) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Use release signing only when properties exist; otherwise use debug signing.
            signingConfig = if (hasKeyProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Optimize the app and maintain FOSS compliance:
            // Enable R8/ProGuard to remove unused code and resources (such as Play Core),
            // reducing APK size and excluding blocked libraries.
            isMinifyEnabled = true 
            isShrinkResources = true
            
            // Regras de Proguard:
            // Use Google's default optimization rules and the project's custom rules.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
}

// Foss compliance
// Block proprietary transitive Google dependencies.
configurations.all {
    resolutionStrategy {
        force("dev.flutter:empty:1.0")
        eachDependency {
            if (requested.group == "com.google.android.play") {
                useTarget("dev.flutter:empty:1.0")
            }
        }
    }
}

// Deterministic Build
// Disable tasks that generate inconsistent binary profiles (fixes classes.dex).
tasks.withType<org.gradle.api.Task>().configureEach {
    if (name.contains("ArtProfile", ignoreCase = true)) {
        enabled = false
    }
}

flutter {
    source = "../.."
}