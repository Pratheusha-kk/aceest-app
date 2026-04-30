FROM mirror.gcr.io/jenkins/jenkins:lts-jdk17

USER root

ARG SONAR_SCANNER_VERSION=5.0.1.3006
ENV SONAR_SCANNER_HOME=/opt/sonar-scanner
ENV PATH="${SONAR_SCANNER_HOME}/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      chromium \
      chromium-driver \
      curl \
      docker-cli \
      docker.io \
      git \
      jq \
      kubernetes-client \
      python3 \
      python3-pip \
      python3-venv \
      unzip \
      wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip" -O /tmp/sonar-scanner.zip \
    && unzip -q /tmp/sonar-scanner.zip -d /opt \
    && mv "/opt/sonar-scanner-${SONAR_SCANNER_VERSION}" "${SONAR_SCANNER_HOME}" \
    && ln -s "${SONAR_SCANNER_HOME}/bin/sonar-scanner" /usr/local/bin/sonar-scanner \
    && rm /tmp/sonar-scanner.zip

USER jenkins

RUN jenkins-plugin-cli --plugins \
      workflow-aggregator \
      git \
      credentials-binding \
      timestamper \
      blueocean
