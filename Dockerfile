FROM ubuntu:19.04

ENV TF_VERSION=0.12.7
RUN apt-get update && \
    apt-get install --yes --no-install-recommends ca-certificates curl unzip zip putty-tools=0.70-6 && \
    curl -o terraform.zip -L https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip && \
    unzip terraform.zip && \
    mv terraform /usr/bin/terraform

CMD terraform init && terraform apply