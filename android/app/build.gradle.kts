import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

fun localOrGradleOrEnv(name: String): String {
    val gradleValue = providers.gradleProperty(name).orElse("").get()
    if (gradleValue.isNotBlank()) return gradleValue

    val envValue = providers.environmentVariable(name).orElse("").get()
    if (envValue.isNotBlank()) return envValue

    return localProperties.getProperty(name) ?: ""
}

android {
    namespace = "com.sohojit.frontend_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sohojit.frontend_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_ANDROID_API_KEY"] =
            localOrGradleOrEnv("GOOGLE_MAPS_ANDROID_API_KEY")

        val facebookAppId = localOrGradleOrEnv("FACEBOOK_APP_ID")
        val facebookClientToken = localOrGradleOrEnv("FACEBOOK_CLIENT_TOKEN")
        val facebookSdkEnabled =
            facebookAppId.isNotBlank() && facebookClientToken.isNotBlank()
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
        resValue(
            "string",
            "fb_login_protocol_scheme",
            if (facebookAppId.isNotBlank()) "fb$facebookAppId" else "fb0"
        )
        resValue("bool", "facebook_sdk_enabled", facebookSdkEnabled.toString())
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = rootProject.file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
