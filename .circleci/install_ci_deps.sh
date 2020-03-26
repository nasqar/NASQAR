#!/usr/bin/env sh

set -eu

TERRAFORM_VERSION=0.12.20
KUBECTL_VERSION=1.17.0

# add dependencies to install cloud tools
apt-get update -y
apt-get install -y curl openssl

cd /tmp

# install terraform
curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "/opt/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "/opt/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
mv terraform /usr/local/bin/terraform

# install kubectl
curl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# install helm 3
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

curl -o aws-iam-authenticator \
    https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator

mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
