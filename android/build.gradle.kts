plugins {
    id("com.android.application") version "8.9.1" apply false   // ✅ UPDATED
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false   // ✅ UPDATED
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/// 🔥 FIX BUILD DIRECTORY (GOOD PRACTICE)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    layout.buildDirectory.value(newBuildDir.dir(name))
}

/// 🔥 ENSURE APP LOADS FIRST (ONLY ONCE)
subprojects {
    evaluationDependsOn(":app")
}

/// 🧹 CLEAN TASK
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}