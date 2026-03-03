# SPIFFE-helper

This is a small agent that fetches SVID certificates and reloads a service when the new certificats are retrieved. 

## Install binary

    wget https://github.com/spiffe/spiffe-helper/releases/download/v0.11.0/spiffe-helper_v0.11.0_Linux-x86_64.tar.gz
    tar -zxf spiffe-helper_v0.11.0_Linux-x86_64.tar.gz
    sudo install -m 0755 spiffe-helper /usr/local/bin/spiffe-helper

## Create spiffe-helper user

    sudo useradd --system --no-create-home --shell /usr/sbin/nologin spiffe-helper

## Create directories and set permissions

    sudo mkdir -p /var/lib/spiffe/haproxy
    sudo chown spiffe-helper:spiffe-helper /var/lib/spiffe/haproxy
    sudo chmod 0750 /var/lib/spiffe/haproxy

    sudo mkdir -p /etc/spiffe-helper
    sudo chown root:spiffe-helper /etc/spiffe-helper
    sudo chmod 0750 /etc/spiffe-helper
        
## Create /etc/spiffe-helper/haproxy.conf

    # Copy from local until repo is pushed
    #wget -O /etc/spiffe-helper/haproxy.conf https://raw.githubusercontent.com/bcit-ltc/flux/refs/heads/main/infrastructure/spiffe-helper/haproxy.conf

    sudo chown root:spiffe-helper /etc/spiffe-helper/haproxy.conf
    sudo chmod 0640 /etc/spiffe-helper/haproxy.conf

## Create /etc/sudoers.d/spiffe-helper so spiffe-helper can restart haproxy

    # Copy from local until repo is pushed
    #wget -O /etc/sudoers.d/spiffe-helper https://raw.githubusercontent.com/bcit-ltc/flux/refs/heads/main/infrastructure/spiffe-helper/sudoers.d/spiffe-helper

    sudo install -o root -g root -m 0440 sudoers.d/spiffe-helper /etc/sudoers.d/spiffe-helper
    sudo visudo -cf /etc/sudoers.d/spiffe-helper

## Create /etc/systemd/system/spiffe-helper-haproxy.service

    # Copy from local until repo is pushed
    #wget -O /etc/systemd/system/spiffe-helper-haproxy.service https://raw.githubusercontent.com/bcit-ltc/flux/refs/heads/main/infrastructure/spiffe-helper/spiffe-helper-haproxy.service

    sudo install -o root -g root -m 0644 spiffe-helper-haproxy.service /etc/systemd/system/spiffe-helper-haproxy.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now spiffe-helper-haproxy.service

# Create spire-server entry for spiffe-helper user

    kubectl -n spire-server exec spire-server-0 -- spire-server entry create \
      -parentID spiffe://${TRUST-DOMAIN}/spire/agent/x509pop/${PARENT_SPIFFE_ID} \
      -spiffeID spiffe://${TRUST-DOMAIN}/workload/${AGENT_SPIFFE_ID}/spiffe-helper \
      -selector unix:user:spiffe-helper

# Confirm spire-agent can retrieve certificates

    sudo -u spiffe-helper spire-agent api fetch x509 -socketPath /run/spire/agent/api.sock

# Point HAProxy to use certs

    # In haproxy.cfg:
    frontend dataplane
        bind *:5555 ssl \
            crt /var/lib/spiffe/haproxy/svid.pem \
            key /var/lib/spiffe/haproxy/svid_key.pem \
            ca-file /var/lib/spiffe/haproxy/svid_bundle.pem \
            verify required

    # In haproxy-operator config:
    --tls-certificate=/var/lib/spiffe/haproxy/svid.pem
    --tls-key=/var/lib/spiffe/haproxy/svid_key.pem
    --tls-ca=/var/lib/spiffe/haproxy/svid_bundle.pem
