#!/bin/bash

set -e
set -o pipefail

# Docker
echo "install docker"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin coreutils gpg

echo "install hashicorp repo"
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -y
sudo apt-get install -y nomad=${NOMAD_VERSION}

# Java
echo "install java"
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update -y 
sudo apt-get install -y openjdk-21-jdk
JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

# exec2 task driver
echo "install exec2 task driver"
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) test" | sudo tee /etc/apt/sources.list.d/hashicorp-test.list
sudo apt-get update -y && sudo apt-get install -y nomad-driver-exec2

sudo cat << EOF > /etc/nomad.d/nomad.hcl

data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"
datacenter = "${DC}"

# Enable the client
client {
  enabled = true
  options {
    "driver.raw_exec.enable"    = "1"
    "docker.privileged.enabled" = "true"
  }
  server_join {
   retry_join = ["${RETRY_JOIN}"]
  }

}

plugin "nomad-driver-exec2" {
  config {
    unveil_by_task  = true
  }
}

acl {
  enabled = ${ACL_ENABLED}
}
EOF

if ${NOMAD_TLS_ENABLED}
then

# install CA and key
sudo cat << EOF > /etc/nomad.d/nomad-agent-ca.pem
${NOMAD_CA_PEM}
EOF

# install client cert and key
sudo cat << EOF > /etc/nomad.d/global-client-nomad.pem
${NOMAD_CLIENT_PEM}
EOF

sudo cat << EOF > /etc/nomad.d/global-client-nomad-key.pem
${NOMAD_CLIENT_KEY}
EOF

sudo cat << EOF >> /etc/nomad.d/nomad.hcl
# Require TLS
tls {
  http = true
  rpc  = true

  ca_file   = "/etc/nomad.d/nomad-agent-ca.pem"
  cert_file = "/etc/nomad.d/global-client-nomad.pem"
  key_file  = "/etc/nomad.d/global-client-nomad-key.pem"

  verify_server_hostname = true
  verify_https_client    = ${NOMAD_TLS_VERIFY_HTTPS_CLIENT}
}
EOF

export NOMAD_ADDR=https://localhost:4646
echo "export NOMAD_ADDR=https://localhost:4646" >> /home/ubuntu/.bashrc
fi

systemctl daemon-reload
systemctl enable nomad
systemctl start nomad
