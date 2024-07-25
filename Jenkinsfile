pipeline {
  agent any
  stages {
       stage('Checkout') {
            steps {
                git credentialsId: 'GitHub', url: 'git@github.com:75stigers/adminserver.git', branch: 'main'
            }
        }
    stage('Maven Install') {
      agent {
        docker {
          image 'maven:3-openjdk-17'
        }
      }
      steps {
        sh 'mvn clean install'
      }
    }
    stage('Docker Build') {
      agent any
      steps {
        sh 'docker build -t 75stigers/adminserver:latest .'
      }
    }
    stage('Docker Push') {
      agent any
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
          sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
          sh 'docker push 75stigers/adminserver:latest'
        }
      }
    }
  }
}