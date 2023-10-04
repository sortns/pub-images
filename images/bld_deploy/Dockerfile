# Original credit: https://github.com/kylemanna/docker-openvpn

FROM ubuntu:latest



ARG VAULT_VERSION=1.14.3
ARG ANSIBLE_VERSION=2.14.2
ARG TERRAFORM_VERSION=1.5.0


LABEL maintainer="sortns@gmail.com"
LABEL VAULT_VERSION=${VAULT_VERSION}
LABEL ANSIBLE_VERSION=${ANSIBLE_VERSION}


RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list && \
    apt update -y 

RUN apt install -y \
        terraform==${TERRAFORM_VERSION} \
        vault==${VAULT_VERSION} \
		git \
		openssh-client \
		sshpass \
		wget \
		unzip &&\
	apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/


RUN ansible-galaxy collection install ansible.windows && \
    ansible-galaxy collection install amazon.aws && \
    ansible-galaxy collection install community.aws && \
    ansible-galaxy collection install community.zabbix:==1.8.0 && \
	ansible-galaxy collection install community.hashi_vault:==5.0.0 && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /root/.cache/pip



WORKDIR /home

CMD [ "bash" ]
