#!/usr/bin/env sh

set -eu

TERRAFORM_VERSION=0.12.20
KUBECTL_VERSION=1.17.0

# add dependencies to install cloud tools
apt-get update -y
apt-get install -y curl openssl jq

cd /tmp

# install terraform
curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "/opt/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "/opt/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
mv terraform /usr/local/bin/terraform

# install kubectl
curl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# install helm 3
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | sh