allprojects {
    repositories {
        google()
        mavenCentral()
        flatDir {
            dirs("${project(":unityLibrary").projectDir}/libs")
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
    project.evaluationDependsOn(":app")
}

// Portability fix: Unity exports ndkPath with an absolute local path (e.g. "C:/Program Files/Unity/...").
// This override ensures that any subproject using ndkPath is switched to ndkVersion instead,
// so the project builds correctly on any machine without manual edits to unityLibrary/build.gradle.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            val androidExt = ext as? com.android.build.gradle.BaseExtension ?: return@let
            if (androidExt.ndkPath != null && androidExt.ndkPath!!.isNotEmpty()) {
                androidExt.ndkVersion = "23.1.7779620"
                androidExt.ndkPath = ""
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
