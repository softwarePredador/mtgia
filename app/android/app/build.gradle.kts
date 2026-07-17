import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.mtgia.mtg_app"
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
        applicationId = "com.mtgia.mtg_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            // Use a real keystore when key.properties is available; keep the
            // debug fallback so local release validation still works.
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }
}

flutter {
    source = "../.."
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

// Flutter generates `GeneratedPluginRegistrant.java` under src/main/java.
// In some setups it may include a hard reference to `integration_test` which is
// not on the release classpath, breaking release compilation.
//
// We patch the generated file to register test-only plugins via reflection so:
// - release builds compile (no compile-time dependency on IntegrationTestPlugin)
// - debug / integration builds can still register the plugin when present
val patchGeneratedPluginRegistrant by tasks.registering {
    doLast {
        val registrant =
            file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (!registrant.exists()) return@doLast

        val original = registrant.readText()
        val optionalPluginClasses =
            listOf(
                "dev.flutter.plugins.integration_test.IntegrationTestPlugin",
                "pl.leancode.patrol.PatrolPlugin",
            )
        var patched = original
        for (className in optionalPluginClasses) {
            val target = "flutterEngine.getPlugins().add(new $className());"
            val replacement =
                """
try {
  final Class<?> clazz = Class.forName("$className");
  final Object plugin = clazz.getDeclaredConstructor().newInstance();
  flutterEngine.getPlugins().add((io.flutter.embedding.engine.plugins.FlutterPlugin) plugin);
} catch (ClassNotFoundException e) {
  // Test-only plugin is not available on some build variants (e.g. release).
}
""".trimIndent()
            patched = patched.replace(target, replacement)
        }

        if (patched != original) {
            registrant.writeText(patched)
        }
    }
}

tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
    dependsOn(patchGeneratedPluginRegistrant)
}
