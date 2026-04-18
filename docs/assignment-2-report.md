# Assignment 2 Report

## Project Overview

ACEest Fitness & Gym is implemented as a Flask-based web application and API that exposes program catalog, program detail, calorie estimation, health checks, and deployment metadata. The project was extended to support a full DevOps-oriented delivery workflow with automated testing, static analysis, containerization, registry publishing, and Kubernetes deployment strategies. The current repository also includes the historical ACEest desktop application versions supplied during the course, allowing the project evolution to be traced from the original Tkinter implementation to the web-ready CI/CD target.

## CI/CD Architecture

The repository is managed with Git and is structured so every application change, pipeline change, and infrastructure change can be versioned together. Jenkins acts as the CI/CD orchestrator through a declarative `Jenkinsfile`. The pipeline checks out the repository, creates an isolated Python virtual environment, installs dependencies, performs linting with `flake8`, executes the automated test suite with `pytest`, and runs SonarQube static analysis. After code quality gates pass, Jenkins builds a Docker image for the Flask app, runs a smoke test against a live container, and can optionally push the image to Docker Hub or another OCI-compatible registry.

For delivery, the pipeline supports Kubernetes deployment through a single parameterized shell script. The selected strategy and image tag are passed from Jenkins into `scripts/deploy_strategy.sh`, which applies the correct manifests and updates deployment images using `kubectl set image`. This keeps the deployment stage consistent across strategies while still meeting the assignment requirement to demonstrate blue-green deployment, canary release, shadow deployment, A/B testing, and rolling updates.

## Testing And Quality Assurance

The project includes unit and integration tests under `tests/`. Unit tests exercise the Flask endpoints directly using Flask’s test client. Integration tests start the application as a process and validate the API over HTTP, including the new `/version` endpoint that exposes runtime release metadata such as deployment strategy and traffic segment. This makes the deployment strategies visible and verifiable when running in Docker or Kubernetes.

Static analysis is integrated using SonarQube, while `flake8` provides fast feedback on Python style issues during each Jenkins build. Together, these checks ensure that code is validated before image creation and before Kubernetes rollout. A smoke test script is also provided so the running container can be validated quickly using `/health`, `/version`, `/programs`, and `/estimate-calories`.

## Deployment Strategies

Five Kubernetes deployment models are implemented:

1. Rolling update gradually replaces pods while maintaining service availability.
2. Blue-green deployment runs stable and candidate environments side by side, allowing instant promotion or rollback by switching the active service.
3. Canary deployment routes a small fraction of traffic to the candidate release using a replica ratio between stable and canary pods.
4. Shadow deployment mirrors production requests to a hidden candidate deployment for observation without affecting user responses.
5. A/B testing exposes two variants and routes selected users to the experiment version through an ingress rule and request header.

These strategies reduce deployment risk because a faulty candidate can be isolated quickly. The application exposes deployment metadata through response headers and `/version`, making it easier to confirm which version handled a request during demos and assessment.

## Challenges And Mitigation

The main challenge was that the initial repository already contained CI components, but they were tightly coupled to one specific environment. This was mitigated by replacing the pipeline with parameterized steps that work with generic Jenkins credentials, registry settings, and Kubernetes clusters. Another challenge was demonstrating rollout strategies in a small educational Flask app. That was addressed by adding runtime metadata so each deployment strategy becomes observable and easy to explain during evaluation.

## Automation Outcomes

The final repository now provides a single submission package that contains:

- the Flask application source
- automated unit and integration tests
- a Jenkins pipeline for CI/CD
- Docker packaging
- SonarQube configuration
- Kubernetes manifests for five rollout strategies
- deployment helper scripts
- historical ACEest version snapshots

This implementation satisfies the assignment goal of delivering an end-to-end automated DevOps workflow with clear support for quality checks, container-based delivery, and rollback-friendly deployment strategies.
