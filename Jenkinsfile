pipeline {
  agent any

  options {
    timestamps()
  }

  parameters {
    string(name: 'RELEASE_VERSION', defaultValue: '', description: 'Optional Docker version tag (e.g., 1.0, 1.1). Leave empty for normal builds.')
  }

  environment {
    IMAGE_NAME = "aceest-app"
    IMAGE_TAG  = "aceest-${BUILD_NUMBER}"

    // Jenkins "Configure System" -> SonarQube servers -> Name
    // Must match exactly, otherwise withSonarQubeEnv() fails.
    SONARQUBE_SERVER = "LocalSonar"

    // SonarScanner CLI must be available on the Jenkins agent.
    // Either install it so `sonar-scanner` is on PATH, or configure it in Jenkins tools and adjust pipeline accordingly.
    SONAR_SCANNER_TOOL = "sonar-scanner"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('SonarQube: Static Analysis') {
      steps {
          sh '''
            set -euxo pipefail
            export PATH="/opt:$PATH"
            sonar --version
            # Only install secrets once, not every build
            sonar plugins list || sonar install secrets
            ls -al
            sonar analyze --file sonar-project.properties
          '''
      }
    }
    stage('Python: Unit Tests (PyUnit)') {
      steps {
        sh '''
          set -euxo pipefail
          python3 -m venv .venv
          . .venv/bin/activate
          python -m pip install --upgrade pip
          python -m pip install -r requirements.txt
          python -m unittest discover -s tests -p "test_*.py"
        '''
      }
    }


    stage('Docker: Build Image') {
      steps {
        sh '''
          set -euxo pipefail

          # Derive a safe branch name for docker tags
          BRANCH_RAW="${BRANCH_NAME:-unknown}"
          BRANCH_SAFE="$(echo "$BRANCH_RAW" | tr '[:upper:]' '[:lower:]' | sed -E 's#[^a-z0-9_.-]+#-#g')"

          # Short git SHA for traceability
          GIT_SHA="$(git rev-parse --short=8 HEAD 2>/dev/null || echo nogit)"

          # Tag set:
          # 1) immutable tag for every build: <branch>-<build>-<sha>
          # 2) moving tag for convenience:      <branch>-latest
          IMMUTABLE_TAG="${BRANCH_SAFE}-${BUILD_NUMBER}-${GIT_SHA}"
          BRANCH_LATEST_TAG="${BRANCH_SAFE}-latest"

          echo "Building image with tags:"
          echo " - ${IMAGE_NAME}:${IMMUTABLE_TAG}"
          echo " - ${IMAGE_NAME}:${BRANCH_LATEST_TAG}"

          docker build -t ${IMAGE_NAME}:${IMMUTABLE_TAG} .
          docker tag ${IMAGE_NAME}:${IMMUTABLE_TAG} ${IMAGE_NAME}:${BRANCH_LATEST_TAG}

          # Optional release tag (only when you pass RELEASE_VERSION)
          if [ -n "${RELEASE_VERSION:-}" ]; then
            RELEASE_TAG="v${RELEASE_VERSION}"
            echo " - ${IMAGE_NAME}:${RELEASE_TAG}"
            docker tag ${IMAGE_NAME}:${IMMUTABLE_TAG} ${IMAGE_NAME}:${RELEASE_TAG}
          fi

          docker image ls ${IMAGE_NAME} | head -n 20
        '''
      }
    }

    stage('Docker: Smoke Test Container') {
      steps {
        sh '''
          set -euxo pipefail

          # Run container in background
          CID=$(docker run -d -p 5000:5000 ${IMAGE_NAME}:${IMAGE_TAG})

          # Give the app time to start
          sleep 3

          # Smoke test endpoints (requires curl available on Jenkins agent)
          curl -fsS http://localhost:5000/ | head -c 200
          curl -fsS http://localhost:5000/programs | head -c 200

          # Cleanup
          docker rm -f "$CID"
        '''
      }
    }
  }

  post {
    always {
      // Clean python venv created during build
      sh 'rm -rf .venv || true'
    }
    failure {
      echo 'Build failed. Check test output / docker build logs above.'
    }
  }
}
