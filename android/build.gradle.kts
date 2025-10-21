allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ CORRECTION : Simplifier la configuration du buildDir
rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    afterEvaluate {
        // ✅ Configurer le buildDir pour chaque sous-projet
        layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name).get())
    }
}

// ✅ Tâche de nettoyage
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
