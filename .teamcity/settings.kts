import jetbrains.buildServer.configs.kotlin.v2019_2.*
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.*
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.vcs

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2020.1"

project {

    buildType(Build)
}

object Build : BuildType({
    name = "Build"

    vcs {
        root(DslContext.settingsRoot)
    }

    steps {
        nuGetInstaller {
            toolPath = "%teamcity.tool.NuGet.CommandLine.DEFAULT%"
            projects = "src/FrameworkApp/FrameworkApp.sln"
        }
        dotnetMsBuild {
            projects = "src/FrameworkApp/FrameworkApp.sln"
            version = DotnetMsBuildStep.MSBuildVersion.V16
            args = "-restore -noLogo"
            param("dotNetCoverage.dotCover.home.path", "%teamcity.tool.JetBrains.dotCover.CommandLineTools.DEFAULT%")
        }
        powerShell {
            name = "Setup SQL Server in a container to run tests against"
            scriptMode = file {
                path = ".teamcity/Add-SQLServer.ps1"
            }
        }
        nunit {
            name = "Run integration tests"
            nunitPath = "%teamcity.tool.NUnit.Console.DEFAULT%"
            includeTests = """src\FrameworkApp\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll"""
        }
        powerShell {
            name = "Tear down SQL Server container"
            scriptMode = file {
                path = ".teamcity/Remove-SQLServer.ps1"
            }
        }
    }

    triggers {
        vcs {
        }
    }
})
