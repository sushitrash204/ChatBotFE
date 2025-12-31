allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.concurrent:concurrent-futures:1.1.0")
            force("androidx.concurrent:concurrent-futures-ktx:1.1.0")
        }
    }
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            dependencies {
                add("implementation", "androidx.concurrent:concurrent-futures:1.1.0")
                add("implementation", "androidx.concurrent:concurrent-futures-ktx:1.1.0")
            }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
