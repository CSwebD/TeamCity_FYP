import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.nodeJS
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

project {
    // Define the VCS root for the GitHub repository
    vcsRoot(HttpsGithubComCSwebDTeamCityTestGitRefsHeadsMain)

    // Define the build configuration
    buildType(BuildAndTestWithoutDocker)
}

object BuildAndTestWithoutDocker : BuildType({
    name = "Build and Test Without Docker"

    // Associate the VCS root with this build configuration
    vcs {
        root(HttpsGithubComCSwebDTeamCityTestGitRefsHeadsMain)
    }

    // Define the build steps
    steps {
        nodeJS {
            name = "Install Dependencies"
            shellScript = "npm install"
        }
        nodeJS {
            name = "Run Tests"
            shellScript = "npm run test"
        }
        nodeJS {
            name = "Build Application"
            shellScript = "npm run build"
        }
    }
})

object HttpsGithubComCSwebDTeamCityTestGitRefsHeadsMain : GitVcsRoot({
    name = "TeamCityTest Main Branch"
    url = "https://github.com/CSwebD/TeamCityTest.git"
    branch = "refs/heads/main"
    branchSpec = "+:refs/heads/*"
})
