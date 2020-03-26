FROM continuumio/miniconda3:latest

# This image is just to get the various cli tools I need for the aws eks service
# AWS CLI - Whatever the latest version is
# AWS IAM Authenticator - 1.12.7
# Kubectl - 1.12.7

RUN apt-get update -y; apt-get upgrade -y; \
    apt-get install -y curl vim-tiny vim-athena jq

WORKDIR /tmp

ENV PATH=/root/bin:$PATH
RUN echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
RUN echo 'alias l="ls -lah"' >> ~/.bashrc

RUN pip install --upgrade ipython awscli troposphere typing boto3 paramiko

# Install clis needed for kubernetes + eks

RUN curl -o aws-iam-authenticator \
    https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
RUN chmod +x ./aws-iam-authenticator

RUN mkdir -p ~/bin && cp ./aws-iam-authenticator ~/bin/aws-iam-authenticator

RUN curl -o kubectl \
    https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl ~/bin/kubectl


RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
RUN mv /tmp/eksctl ~/bin/
RUN chmod +x ~/bin/eksctl
RUN eksctl version

RUN curl -L https://github.com/kubernetes/kompose/releases/download/v1.18.0/kompose-linux-amd64 -o kompose
RUN mv kompose ~/bin/kompose
RUN chmod +x ~/bin/kompose

WORKDIR /tmp

ENV HELM_HOST 44134
ENV TILLER_NAMESPACE tiller
#RUN wget https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz
#RUN tar -xvf helm-v3.0.2-linux-amd64.tar.gz
#RUN mv linux-amd64/helm ~/bin/; mv linux-amd64-tiller ~/bin/
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh

# TODO Figure out the metrics server
#COPY metrics-server/deploy_metrics_server.sh ./
#RUN chmod 777 *sh
#RUN ./deploy_metrics_server.sh

# Get terraform

RUN wget https://releases.hashicorp.com/terraform/0.12.20/terraform_0.12.20_linux_amd64.zip \
 && unzip terraform_0.12.20_linux_amd64.zip \
 && mv terraform /usr/local/bin \
 && rm terraform_0.12.20_linux_amd64.zip

WORKDIR /root

#RUN mkdir -p /root/.aws
#COPY config /root/.aws/config
#COPY credentials /root/.aws/credentials
