@Library("sailpoint/jenkins-release-utils")_

def GITHUB_URL   = "git@github.com:nirav-radia-sp/test-rules.git"
def JOB_BRANCH   = params.BRANCH != "branch" && params.BRANCH != null ? "${params.BRANCH}" : ""
def pod_template = "pods/prometheus-rules-sync.yaml"
def currTime = "${System.currentTimeMillis()}"

pipeline {

    parameters {
        string (name: 'BRANCH',  defaultValue: 'main', description: 'Branch to Build')
        string (name: 'slack_room', defaultValue: 'team-periscope', description: 'Specify the slack room to announce in')
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: "100"))
    }

    agent {
        kubernetes {
            yaml "${libraryResource pod_template}"
        }
    }

    stages {
        stage('Git Checkout'){
            steps {
                  script {
                      git credentialsId: 'git-automation-ssh', url: GITHUB_URL, branch: JOB_BRANCH
                      withCloudBeesCreds([credentialsId: 'git-automation-ssh']){
                        println("pod_template is ${pod_template}")
                        println("aws env is ${env.AWS_ENVIRONMENT}")
                        println("BRANCH: ${BRANCH}")
                        sh """
                          if [[ "${env.AWS_ENVIRONMENT}" == "prod" || "${env.AWS_ENVIRONMENT}" == "internal" ]]; then
                            if [[ "$BRANCH" != "main" ]]; then
                              echo "Unable to proceed, only master may be deployed to prod and internal"
                              exit 1
                            fi
                          fi
                        """
                      }
                  }
              }
        }//stage Git Checkout
        stage('Validate orphan files'){
          steps{
            script {
              dir("${WORKSPACE}") {
                sh '''
                  #!/bin/bash -e
                  source ${WORKSPACE}/scripts/rulelib.sh
                  valid=\$(orphan_file_validation ''' + env.AWS_ENVIRONMENT.toLowerCase() + ''')
                  if [[ ! -z "${valid}" ]]; then
                    echo "$valid"
                    exit 1
                  fi
                '''
              }
            }
          }
        }
        stage('Assemble Rules') {
          steps {
            script {
                 sh """
                    #!/bin/bash -e
                    source "${WORKSPACE}/scripts/rulelib.sh"
                    assembled=\$(ruletmp_copy "${WORKSPACE}/${currTime}")
                """
            } // script
          }// steps
        }// stage Assemble Rules
    }//stages
  post {
      success {
        script {
            echo "Deployment succeed."
            message = "Deployment of prometheus-dynamic-config rules in ${env.AWS_ENVIRONMENT.toUpperCase()} with branch \"${JOB_BRANCH}\" finished successfully. <${env.BUILD_URL}|Go to pipeline>\n"
            slackStatus = 'success'
            sendSlackNotification(params.slack_room, message, slackStatus)
        }
      }

      failure {
        script {
            echo "Deployment failed."
            message = "Deployment of prometheus-dynamic-config rules in ${env.AWS_ENVIRONMENT.toUpperCase()} with branch \"${JOB_BRANCH}\" failed. <${env.BUILD_URL}|Go to pipeline>\n"
            slackStatus = 'failure'
            sendSlackNotification(params.slack_room, message, slackStatus)
        }
      }

      aborted {
        script {
            echo "Deployment aborted."
            message = "Deployment of prometheus-dynamic-config rules in ${env.AWS_ENVIRONMENT.toUpperCase()} with branch \"${JOB_BRANCH}\" aborted. <${env.BUILD_URL}|Go to pipeline>\n"
            slackStatus = 'failure'
            sendSlackNotification(params.slack_room, message, slackStatus)
        }
      }
    }
}//pipeline
