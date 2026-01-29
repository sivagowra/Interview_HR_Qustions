node {
    stage("Code") {
        git "https://github.com/devops0014/one.git"
    }

    stage("Build") {
        sh 'mvn clean package'
    }

    stage("CQA") {
        withSonarQubeEnv(credentialsId: 'sonar') {
            def mavenHome = tool name: 'maven', type: 'maven'
            def mavenCMD = "${mavenHome}/bin/mvn"
            sh "${mavenCMD} sonar:sonar"
        }
    }
}
