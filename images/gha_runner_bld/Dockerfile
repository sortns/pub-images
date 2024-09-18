FROM ghcr.io/actions/actions-runner:latest

ARG VAULT_VERSION=1.17.5
ARG TERRAFORM_VERSION=1.9.6
ARG ANSIBLE_PIP_VERSION=10.4.0

LABEL maintainer="sortns@gmail.com"
LABEL VAULT_VERSION=${VAULT_VERSION}
LABEL TERRAFORM_VERSION=${TERRAFORM_VERSION}
LABEL ANSIBLE_VERSION=${ANSIBLE_PIP_VERSION}



RUN sudo apt update -y && sudo apt install -y wget unzip lsb-release ca-certificates gnupg software-properties-common 

RUN wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
	&& sudo unzip vault_${VAULT_VERSION}_linux_amd64.zip -d /usr/bin/ \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && sudo unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin/ 

RUN sudo apt update -y && sudo apt install -y \
        python3-pip \
		git \
		openssh-client \
		sshpass \
		unzip &&\
  	sudo apt clean autoclean && \
    sudo apt autoremove --yes && \
    sudo rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN sudo pip install ansible==${ANSIBLE_PIP_VERSION}


RUN ansible-galaxy collection install ansible.windows && \
    ansible-galaxy collection install amazon.aws && \
    ansible-galaxy collection install community.aws && \
    ansible-galaxy collection install community.zabbix:==1.8.0 && \
	ansible-galaxy collection install community.hashi_vault:==5.0.0 && \
	sudo rm -rf /var/lib/apt/lists/* && \
	sudo rm -rf /root/.cache/pip

ADD ./images/gha_runner_bld/.terraformrc /home/runner/
# ADD ./images/gha_runner_bld/pki-ca.crt /usr/local/share/ca-certificates/

# RUN sudo update-ca-certificates

WORKDIR /home/runner/

CMD [ "/home/runner/run.sh" ]
