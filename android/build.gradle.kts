allprojects {
    repositories {
        google()
        mavenCentral()
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

// Workaround compileSdk: alcuni plugin transitivi (es. passkeys_doctor) fissano
// compileSdk = 35, ma package_info_plus richiede che i consumer compilino contro
// l'API 36+, facendo fallire checkReleaseAarMetadata. Forziamo compileSdk = 36 su
// ogni modulo Android via la nuova DSL `com.android.build.api.dsl` (l'unica letta
// da AGP 9). Il blocco `evaluationDependsOn(":app")` sopra può aver già valutato
// alcuni sottoprogetti, quindi se sono già valutati applichiamo subito, altrimenti
// in afterEvaluate (così vince sull'assegnazione del plugin).
subprojects {
    fun Project.forceCompileSdk36() {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { it.compileSdk = 36 }
        extensions.findByType(com.android.build.api.dsl.ApplicationExtension::class.java)
            ?.let { it.compileSdk = 36 }
    }
    if (state.executed) forceCompileSdk36() else afterEvaluate { forceCompileSdk36() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
