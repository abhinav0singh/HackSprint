allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.name == "isar_flutter_libs") {
            extensions.findByType<com.android.build.gradle.LibraryExtension>()
                ?.namespace = "io.isar.isar_flutter_libs"
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (project.name == "isar_flutter_libs") {
            extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
                namespace = "io.isar.isar_flutter_libs"
                compileSdk = 36
                defaultConfig.minSdk = 21
            }
        }
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
