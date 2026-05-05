pipeline {
  parameters {
    string(name: 'ECR_REPOSITORY', defaultValue: '', description: 'Target ECR repository URL (e.g. <account_id>.dkr.ecr.<region>.amazonaws.com/<repo-name>). Get it from: terraform output -raw ecr_repository_url')
    string(name: 'GITOPS_REPO_URL', defaultValue: 'https://github.com/ElinaSitailo/goit-dev-ops-gitops.git', description: 'GitOps repository URL that stores Helm values')
    string(name: 'GITOPS_BRANCH', defaultValue: 'main', description: 'Branch in GitOps repository to update')
    string(name: 'GITOPS_VALUES_FILE', defaultValue: 'charts/django-app/values.yaml', description: 'Path to Helm values.yaml in GitOps repository')
  }

  agent {
    kubernetes {
      label 'kaniko-git'
      defaultContainer 'git'
      yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-kaniko-git
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2-debug
      command:
        - cat
      tty: true
      workingDir: /workspace
      volumeMounts:
        - name: workspace-volume
          mountPath: /workspace
    - name: git
      image: alpine/git:2.47.2
      command:
        - cat
      tty: true
      workingDir: /workspace
      volumeMounts:
        - name: workspace-volume
          mountPath: /workspace
    - name: yq
      image: mikefarah/yq:4.44.3
      command:
        - cat
      tty: true
      workingDir: /workspace
      volumeMounts:
        - name: workspace-volume
          mountPath: /workspace
    - name: aws-cli
      image: amazon/aws-cli:2.22.35
      command:
        - cat
      tty: true
      workingDir: /workspace
      volumeMounts:
        - name: workspace-volume
          mountPath: /workspace
  volumes:
    - name: workspace-volume
      emptyDir: {}
'''
    }
  }

  environment {
    AWS_REGION = 'eu-north-1'
    ECR_REPOSITORY = "${params.ECR_REPOSITORY}"
    GITOPS_REPO = "${params.GITOPS_REPO_URL}"
    GITOPS_BRANCH = "${params.GITOPS_BRANCH}"
    VALUES_FILE = "${params.GITOPS_VALUES_FILE}"
    IMAGE_TAG = ''
  }

  options {
    disableConcurrentBuilds()
  }

  stages {
    stage('Checkout Source') {
      steps {
        checkout scm
        script {
          sh 'git config --global --add safe.directory "${WORKSPACE}"'
          def shortSha = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
          env.IMAGE_TAG = "${env.BUILD_NUMBER}-${shortSha}"
        }
      }
    }

    stage('ECR Auth') {
      // Kaniko does not inherit Jenkins env vars — we write config.json explicitly.
      // aws-cli fetches the ECR token and saves it to $WORKSPACE/.docker/config.json
      // which Kaniko reads via --docker-config in the next stage.
      steps {
        container('aws-cli') {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']
          ]) {
            sh """
              set -eu
              ECR_REGISTRY="\$(echo "${ECR_REPOSITORY}" | cut -d/ -f1)"
              ECR_TOKEN="\$(aws ecr get-login-password --region "${AWS_REGION}")"
              AUTH_B64="\$(printf 'AWS:%s' "\${ECR_TOKEN}" | base64 | tr -d '\\n')"

              mkdir -p "${WORKSPACE}/.docker"
              printf '{"auths":{"%s":{"auth":"%s"}}}' "\${ECR_REGISTRY}" "\${AUTH_B64}" \
                > "${WORKSPACE}/.docker/config.json"

              echo "ECR auth config written for registry: \${ECR_REGISTRY}"
            """
          }
        }
      }
    }

    stage('Build and Push to ECR') {
      // Kaniko reads ECR credentials from the config.json prepared in the previous stage.
      steps {
        container('kaniko') {
          sh """
            /kaniko/executor \
              --context "${WORKSPACE}/app" \
              --dockerfile "${WORKSPACE}/app/Dockerfile" \
              --docker-config "${WORKSPACE}/.docker" \
              --destination "${ECR_REPOSITORY}:${IMAGE_TAG}" \
              --destination "${ECR_REPOSITORY}:latest"
          """
        }
      }
    }

    stage('Update Helm values in GitOps repo') {
      steps {
        container('yq') {
          withCredentials([
            usernamePassword(credentialsId: 'gitops-repo-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')
          ]) {
            sh """
              set -eu

              rm -rf gitops-repo
              git clone --branch "${GITOPS_BRANCH}" "https://\${GIT_USERNAME}:\${GIT_TOKEN}@\${GITOPS_REPO#https://}" gitops-repo

              cd gitops-repo

              IMAGE_TAG="${IMAGE_TAG}" yq e '.image.tag = strenv(IMAGE_TAG)' -i "${VALUES_FILE}"

              git config user.email "jenkins@local"
              git config user.name "jenkins-bot"
              git add "${VALUES_FILE}"

              if git diff --cached --quiet; then
                echo "No values.yaml changes detected."
                exit 0
              fi

              git commit -m "ci: update django image tag to ${IMAGE_TAG}"
              git push origin "${GITOPS_BRANCH}"
            """
          }
        }
      }
    }
  }
}
