allprojects {
    repositories {
        google()
        mavenCentral()
    }

    dependencyLocking {
        lockAllConfigurations()
        // Kotlin publishes stdlib-common as metadata constraints on Android,
        // not as a release runtime artifact. Locking that virtual entry makes
        // Gradle reject an otherwise reproducible release classpath because
        // there is no artifact to resolve. The concrete stdlib/JDK artifacts
        // remain locked and checksum-verified.
        ignoredDependencies.add("org.jetbrains.kotlin:kotlin-stdlib-common")
        // Flutter selects exactly one engine artifact per target ABI. A lock
        // generated without -Ptarget-platform records all ABIs against the
        // same configuration, which makes a device-specific build fail
        // because the non-target ABIs are intentionally absent. These engine
        // artifacts remain pinned by the checked Flutter SDK revision and by
        // strict SHA-256 entries in verification-metadata.xml; only their
        // mutually-exclusive presence is excluded from lock-state matching.
        ignoredDependencies.add("io.flutter:arm64_v8a_*")
        ignoredDependencies.add("io.flutter:armeabi_v7a_*")
        ignoredDependencies.add("io.flutter:x86_64_*")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
