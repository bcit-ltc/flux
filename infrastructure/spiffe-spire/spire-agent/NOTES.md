# Configure SPIFFE/spire-agent

- SPIFFE = Secure Production Identity Framework For Everyone
- Spire = SPIFFE Runtime Environment
- spire-agent = Requests and stores SVID's (Spiffe Verifiable Identity Documents); registered as an entry in `spire-server`.

## Deploy `spire-agent` on a VM

### Retrieve SPIRE binary
    wget https://github.com/spiffe/spire/releases/download/v1.14.1/spire-1.14.1-linux-amd64-musl.tar.gz
    tar zvxf spire-1.14.1-linux-amd64-musl.tar.gz
    sudo cp -r spire-1.14.1/. /opt/spire/

## Retrieve an x509pop bootstrap certificate for the agent

    export CLIENT_CN="" && \
    export TRUST_DOMAIN="" && \
    vault write -format=json pki/sica/v2/issue/spire-x509pop common_name="${CLIENT_CN}.${TRUST_DOMAIN}" \
      ttl="72h" > cert_bundle.json && \
    jq -r .data.certificate < cert_bundle.json > x509pop.crt && \
    jq -r .data.private_key < cert_bundle.json > x509pop.key && \
    jq -r .data.issuing_ca < cert_bundle.json > x509pop-ca.crt && \
    rm cert_bundle.json

## Retrieve SPIRE bootstrap bundle

    kubectl -n spire-server exec spire-server-0 -- \
      spire-server bundle show -format pem > bootstrap.bundle

## Add secret to Kubernetes `spire-server`

    kubectl -n spire-server create secret generic spire-x509pop-ca \
      --from-file=ca.crt=x509pop-ca.crt

## Restart spire-server

    kubectl -n spire-server rollout restart statefulset spire-server
    kubectl -n spire-server logs -f spire-server-0

## Copy certificates and bootstrap bundle to agent

    export REMOTE_USER="" && \
    export REMOTE_HOST="" && \
    rsync -av x509pop.key ${REMOTE_USER}@${REMOTE_HOST}/etc/spire.d/x509pop.key && \
    rsync -av x509pop.crt ${REMOTE_USER}@${REMOTE_HOST}/etc/spire.d/x509pop.crt && \
    rsync -av x509pop-ca.crt ${REMOTE_USER}@${REMOTE_HOST}/etc/spire.d/x509pop-ca.crt && \
    rsync -av bootstrap.bundle ${REMOTE_USER}@${REMOTE_HOST}/etc/spire.d/bootstrap.bundle

## Add `spire` user/group

    sudo useradd --system --home /nonexistent --shell /usr/sbin/nologin spire || true

## Add directories and set permissions

    sudo install -d -o spire -g spire -m 0750 /etc/spire.d/conf/server /etc/spire.d/conf/agent
    sudo install -d -o spire -g spire -m 0750 /var/lib/spire/server /var/lib/spire/agent
    sudo install -d -o spire -g spire -m 0755 /etc/spire.d

## Configure certificates and bootstrap bundle

    sudo install -o spire -g spire -m 0600 x509pop.key /etc/spire.d/x509pop.key
    sudo install -o spire -g spire -m 0644 x509pop.crt /etc/spire.d/x509pop.crt
    sudo install -o spire -g spire -m 0644 x509pop-ca.crt      /etc/spire.d/x509pop-ca.crt
    sudo install -o spire -g spire -m 0644 bootstrap.bundle    /etc/spire.d/bootstrap.bundle  
    
    sudo systemctl restart spire-agent

## Retrieve the PARENT SPIFFEID

    kubectl -n spire-server exec spire-server-0 -- spire-server agent list | grep -A4 x509pop

## Add an agent attestation entry

    kubectl -n spire-server exec spire-server-0 -- spire-server entry create \
      -parentID spiffe://${TRUST_DOMAIN}/spire/agent/x509pop/${PARENT_ID}-> \
      -spiffeID spiffe://${TRUST_DOMAIN}/workload/${AGENT_ID} \
      -selector unix:uid:0

    kubectl -n spire-server exec spire-server-0 -- spire-server agent selectors show -spiffeID ${X509POP_AGENT_SPIFFE_ID}
