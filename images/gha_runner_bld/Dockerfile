FROM ghcr.io/actions/actions-runner:latest

ARG VAULT_VERSION=1.15.0-1
ARG TERRAFORM_VERSION=1.5.7-1
ARG ANSIBLE_PIP_VERSION=8.4.0

LABEL maintainer="sortns@gmail.com"
LABEL VAULT_VERSION=${VAULT_VERSION}
LABEL TERRAFORM_VERSION=${TERRAFORM_VERSION}
LABEL ANSIBLE_VERSION="2.15.4"


RUN apt update -y && apt install -y wget lsb-release ca-certificates gnupg software-properties-common && \
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list 
    

RUN apt update -y && apt install -y \
        terraform=${TERRAFORM_VERSION} \
        vault=${VAULT_VERSION} \
        python3-pip \
		git \
		openssh-client \
		sshpass \
		unzip &&\
	apt clean autoclean && \
    apt autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN pip install ansible==${ANSIBLE_PIP_VERSION}

RUN ansible-galaxy collection install ansible.windows && \
    ansible-galaxy collection install amazon.aws && \
    ansible-galaxy collection install community.aws && \
    ansible-galaxy collection install community.zabbix:==1.8.0 && \
	ansible-galaxy collection install community.hashi_vault:==5.0.0 && \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /root/.cache/pip



WORKDIR /home/runner/

CMD [ "/home/runner/run.sh" ]
