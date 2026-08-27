FROM ubuntu:26.04

ARG RUNNER_VERSION="2.337.0"

# Prevents installdependencies.sh from prompting the user and blocking the image creation
ARG DEBIAN_FRONTEND=noninteractive

RUN useradd -m docker
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl git sudo jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip \
    && rm -rf /var/lib/apt/lists

WORKDIR /home/docker/actions-runner

RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

COPY start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# since the config and run script for actions are not allowed to be run by root,
# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

ENTRYPOINT ["/home/docker/actions-runner/start.sh"]
