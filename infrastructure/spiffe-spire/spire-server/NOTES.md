# Configure SPIFFE/SPIRE

SPIFFE = Secure Production Identity Framework For Everyone
Spire = SPIFFE Runtime Environment

SPIFFE is a standard for identifying and securing communication between applications. We deploy `spire-server` on Kubernetes and register identities using `spire-agent`.

Identity attestation uses x509pop with certificates signed by a Root CA.

## Deploy `spire-server` on Kubernetes

    helm upgrade --install --create-namespace -n spire-mgmt spire-crds spire-crds \
    --repo https://spiffe.github.io/helm-charts-hardened/

    helm upgrade --install -n spire-mgmt spire spire \
    --repo https://spiffe.github.io/helm-charts-hardened/ \
      -f values.yaml

    # Create an attestation secret
    kubectl -n spire-server create secret generic spire-x509pop-ca \
    --from-file=ca.crt=x509pop-ca.crt

    # Patch the spire-server to pickup the x509pop certificate secret
    kubectl -n spire-server patch statefulset spire-server --type='json' -p='[
      {"op":"add","path":"/spec/template/spec/volumes/-","value":{
        "name":"x509pop-ca",
        "secret":{"secretName":"spire-x509pop-ca"}
      }},
      {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts/-","value":{
        "name":"x509pop-ca",
        "mountPath":"/run/spire/x509pop",
        "readOnly":true
      }}
    ]'

    # YAML for the StatefulSet should look like this:
    spire-server:
      extraVolumes:
        - name: x509pop-ca
          configMap:
            name: spire-x509pop-ca
      extraVolumeMounts:
        - name: x509pop-ca
          mountPath: /run/spire/x509pop
          readOnly: true

## Add secret to Kubernetes `spire-server`

    kubectl -n spire-server create secret generic spire-x509pop-ca \
      --from-file=ca.crt=x509pop-ca.crt

## Restart spire-server

    kubectl -n spire-server rollout restart statefulset spire-server
    kubectl -n spire-server logs -f spire-server-0
