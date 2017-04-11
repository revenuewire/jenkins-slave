node {
   stage('Preparation') { // for display purposes
      // Get some code from a GitHub repository
      checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/revenuewire/jenkins-slave.git']]])
   }

   stage('Docker') {
        echo 'Docker Build'
          withCredentials([string(credentialsId: 'RWDockerHubPassword', variable: 'DOCKER_PASSWORD')]) {
            sh '''docker login -u rwdeveloper -p $DOCKER_PASSWORD'''
            sh '''docker build --pull -t revenuewire/jenkins-slave:latest .'''
            sh '''docker push revenuewire/jenkins-slave:latest'''
          }
          echo 'Docker Successful'
   }
   
   stage('Results') {
      echo 'All Done.'
   }
}