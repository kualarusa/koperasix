android {
    namespace = "com.kpulampung.koperasi_anggota"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kpulampung.koperasi_anggota"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // KONFIGURASI KUNCI UNTUK KOTLIN DSL (.kts)
    signingConfigs {
        create("release") {
            storeFile = file("key.jks")
            storePassword = "android"
            keyAlias = "key"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}