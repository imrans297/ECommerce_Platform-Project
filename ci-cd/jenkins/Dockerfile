FROM jenkins/jenkins:lts

USER root

# Install Docker CLI
RUN apt-get update && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

USER jenkins

# Install plugins
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator \
    pipeline-stage-view \
    git \
    docker-workflow \
    credentials-binding \
    nodejs \
    maven-plugin \
    pipeline-utility-steps \
    amazon-ecr \
    aws-credentials \
    kubernetes-cli \
    kubernetes \
    sonar \
    dependency-check-jenkins-plugin \
    warnings-ng \
    htmlpublisher \
    junit \
    jacoco \
    slack \
    email-ext \
    timestamper \
    ws-cleanup \
    build-user-vars-plugin

# Skip setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Create admin user
COPY --chown=jenkins:jenkins init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/