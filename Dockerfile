FROM ubuntu:26.04
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG RUNNER_VERSION="2.337.0"

# Prevents installdependencies.sh from prompting the user and blocking the image creation
ARG DEBIAN_FRONTEND=noninteractive

RUN useradd -m docker

WORKDIR /home/docker/actions-runner

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl ca-certificates git jq uidmap build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip \
    && rm -rf /var/lib/apt/lists

RUN <<EOF
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
EOF

RUN tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists

RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

COPY start.sh start.sh
RUN chmod +x start.sh

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

ENTRYPOINT ["/home/docker/actions-runner/start.sh"]
