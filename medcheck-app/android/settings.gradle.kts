pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")

gradle.settingsEvaluated {
    gradle.rootProject {
        subprojects {
            afterEvaluate {
                if (name == "app") return@afterEvaluate

                if (extensions.findByName("android") != null) {
                    val androidExt = extensions.getByType(com.android.build.gradle.BaseExtension::class)
                    androidExt.compileSdkVersion(36)
                    androidExt.buildFeatures.buildConfig = true
                    androidExt.compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_11
                        targetCompatibility = JavaVersion.VERSION_11
                    }

                    if (androidExt.namespace == null) {
                        val manifestFile = androidExt.sourceSets.getByName("main").manifest.srcFile
                        val resolvedNamespace = if (manifestFile.exists()) {
                            val parsedManifest = groovy.xml.XmlParser().parse(manifestFile)
                            parsedManifest.attribute("package")?.toString()
                                ?: "com.alexis.pill_reminder_app.$name"
                        } else {
                            "com.alexis.pill_reminder_app.$name"
                        }
                        androidExt.namespace = resolvedNamespace
                        println("✓ Namespace asignado a $name: $resolvedNamespace")
                    }
                }

                tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class).configureEach {
                    kotlinOptions {
                        jvmTarget = JavaVersion.VERSION_11.toString()
                    }
                }
            }
        }
    }
}
