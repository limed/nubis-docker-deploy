# Docker image containing all dependencies for running terraform in Nubis

FROM ubuntu:16.04

# Do not add a 'v' as pert of the version string (ie: v1.1.3)
#+ This causes issues with extraction due to GitHub's methodology
#+ Where necesary the 'v' is specified in code below
ENV AwCliVersion=1.10.38 \
    AwsVaultVersion=3.7.1 \
    TerraformVersion=0.10.7 \
    UnicredsVersion=1.5.1 \
    Toml2JSONVersion=0.1.0

# Intall package dependencies
RUN apt-get -q update \
    && apt-get install --no-install-recommends -qy \
        curl \
        git \
        jq=1.5* \
        python-setuptools \
        python-wheel \
        python-pip=8.1.* \
        unzip \
        rsync \
    && pip install awscli==${AwCliVersion} \
    && pip install -v toml2json==${Toml2JSONVersion} \
    && mkdir -p /nubis/work /nubis/bin \
    && chmod 777 /nubis/work \
    && apt-get clean -y \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && apt-get purge -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

WORKDIR /nubis

# Install aws-vault
RUN ["/bin/bash", "-c", "set -o pipefail && mkdir -p /nubis/bin \
    && curl --silent -L --out /nubis/bin/aws-vault https://github.com/99designs/aws-vault/releases/download/v${AwsVaultVersion}/aws-vault-linux-amd64 \
    && chmod +x /nubis/bin/aws-vault" ]

# Install Terraform
RUN ["/bin/bash", "-c", "set -o pipefail \
    && curl --silent -L --out /nubis/terraform_${TerraformVersion}_linux_amd64.zip https://releases.hashicorp.com/terraform/${TerraformVersion}/terraform_${TerraformVersion}_linux_amd64.zip \
    && unzip /nubis/terraform_${TerraformVersion}_linux_amd64.zip -d /nubis/bin \
    && rm -f /nubis/terraform_${TerraformVersion}_linux_amd64.zip" ]

# Install Unicreds
RUN ["/bin/bash", "-c", "set -o pipefail \
    && curl --silent -L https://github.com/Versent/unicreds/releases/download/${UnicredsVersion}/unicreds_${UnicredsVersion}_linux_amd64.tar.gz \
    | tar --extract --gunzip --directory=/nubis/bin" ]

# Copy over the nubis-deploy-wrapper script
COPY [ "nubis-deploy-wrapper", "/nubis/" ]

ENV PATH /nubis/bin:$PATH

ENTRYPOINT [ "/nubis/nubis-deploy-wrapper" ]

CMD [ "plan" ]
