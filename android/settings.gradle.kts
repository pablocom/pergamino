pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "Pergamino"

include(":app")
include(":core:core-common")
include(":core:core-ui")
include(":core:core-data")
include(":core:core-testing")
include(":feature:feature-auth")
