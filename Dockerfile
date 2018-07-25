FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/*

RUN apt-get update -y -q && \
  apt-get install -y curl wget lsb-release
  
RUN AZ_REPO=$(lsb_release -cs) && \
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list && \
  curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - && \
  sudo apt-get install apt-transport-https && \
  apt-get update -y && \
  sudo apt-get install azure-cli

RUN apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" >> /etc/apt/sources.list.d/pgdg.list

RUN apt-get update && \
    apt-get install -y postgresql

ADD start.sh /start.sh
RUN chmod 0755 /start.sh

ENTRYPOINT ["/start.sh"]
