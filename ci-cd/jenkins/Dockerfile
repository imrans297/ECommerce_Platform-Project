FROM jenkins/jenkins:lts

USER root

# Install Docker CLI
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

USER jenkins

# Install plugins required by Jenkinsfile
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator:596.v8c21c963d92d \
    pipeline-stage-view:2.25 \
    git:5.0.0 \
    github:1.37.3.1 \
    nodejs:1.6.1 \
    maven-plugin:3.22 \
    docker-workflow:563.vd5d2e5c4007f \
    kubernetes:4029.v5712230ccb_f8 \
    kubernetes-cli:1.12.1 \
    aws-credentials:191.vcb_f183ce58b_9 \
    amazon-ecr:1.7 \
    sonar:2.15 \
    htmlpublisher:1.32 \
    warnings-ng:10.5.0 \
    slack:631.v40deea_40323b \
    credentials:1271.v54b_1c35c20e4 \
    credentials-binding:523.vd859a_4b_122e6 \
    timestamper:1.25 \
    ws-cleanup:0.45 \
    ansicolor:1.0.2 \
    configuration-as-code:1670.v564dc8b_982d0

# Skip initial setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Create admin user
COPY --chown=jenkins:jenkins init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/