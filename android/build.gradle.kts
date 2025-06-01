// android/build.gradle.kts

plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false // ✅ Required for Firebase
}

buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.3.15") // ✅ Firebase plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory config (optional - you can keep it or remove if unsure)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
