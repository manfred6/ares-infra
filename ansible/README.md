# K3s + cert-manager + Traefik/MetalLB + ECK lab

This Ansible folder deploys the lab in four layers:

1. `playbooks/k3s.yml` bootstraps the existing VMs as a 3-server K3s cluster using Flannel/VXLAN and embedded etcd. K3s ServiceLB is disabled; bundled Traefik stays enabled.
2. Role `cert_manager` installs cert-manager, bootstraps a root CA on the provisioning host when needed, creates a constrained intermediate CA signed by that root, installs that intermediate as a cluster-wide CA `ClusterIssuer`, and requests/renews the shared `*.ares.internal` ingress certificate.
3. Role `traefik` installs MetalLB, gives Traefik one MetalLB IP, and configures the cert-manager-managed wildcard certificate as Traefik's default certificate.
4. Role `eck` installs ECK, deploys one Elasticsearch data/master node, Kibana, Fleet Server, and a Fleet-managed Elastic Agent DaemonSet. ECK owns its backend HTTP certificates. Traefik connects to every Elastic backend over HTTPS and verifies the ECK-managed CA/hostname with `ServersTransport`.

There is no plaintext Elastic HTTP hop and no `insecureSkipVerify`.

## PKI model

The root CA stays outside Kubernetes:

```text
provisioning host
  root-ca.crt
  root-ca.key              <-- never leaves this host
       |
       | signs once / rotates rarely
       v
  Ares Lab Issuing CA
       |
       | issuing cert + private key
       v
Kubernetes / cert-manager
       |
       +-- ClusterIssuer: lab-ca
       |
       +-- Certificate: *.ares.internal
                |
                v
          lab-wildcard-tls
                |
                v
             Traefik
                |
                | HTTPS, ECK CA + hostname verified
                v
      Elasticsearch / Kibana / Fleet
```

The intermediate is created with `CA:TRUE`, `pathLen=0`, and critical DNS name constraints for `lab_domain`. Its private key is intentionally stored in Kubernetes so cert-manager can issue and renew certificates. The root private key is not copied into the cluster.

The CA Secret given to cert-manager contains the issuing certificate followed by the root certificate, so cert-manager can provide the intermediate chain with issued leaf certificates. Clients should trust the root CA out-of-band; do not treat a leaf Secret's `ca.crt` as your trust-store source.

## Important: Kubernetes Secret encryption

Because the cert-manager issuing CA private key is stored as a Kubernetes Secret, enabling K3s Secret encryption at rest is recommended. For a cluster that was already bootstrapped without `secrets-encryption`, use the documented K3s `k3s secrets-encrypt` enable/rotation procedure rather than simply toggling the config on all HA nodes at once.

## Before running

The generated inventory should live at `inventory/hosts.ini`. Environment-specific variables live at `inventory/group_vars/all.yml` so Ansible loads them with that inventory.

Update at least:

- `metallb_addresses`
- `traefik_lb_ip`
- `lab_domain`
- `lab_pki_dir`

Create a wildcard DNS record if possible:

```text
*.ares.internal -> 192.168.30.200
```

or create individual records for:

```text
es.ares.internal
kibana.ares.internal
fleet.ares.internal
```

All should resolve to `traefik_lb_ip`.

## Python / Ansible environment

Use a project-local virtualenv rather than the distro Ansible package:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
```

Terraform can generate `ansible.cfg` (or inject `private_key_file`) so the same deployment SSH key is used automatically. If Terraform owns that file, keep `roles_path = ./roles` in the generated `[defaults]` section.


## Native K3s Helm Controller

There is intentionally **no Helm binary dependency on the provisioning host**.
Ansible creates K3s `helm.cattle.io/v1` `HelmChart` resources and the K3s Helm
Controller performs chart installation inside the cluster:

```text
Ansible / kubernetes.core.k8s
        |
        v
Kubernetes API
        |
        v
K3s Helm Controller
        +-- cert-manager
        +-- MetalLB
        +-- ECK operator
```

The bundled K3s Traefik release is configured with a `HelmChartConfig`.
`/usr/local/bin/helm` is not required on the provisioning host or the K3s nodes.

## Run the platform

Your cluster is already bootstrapped, so normally run:

```bash
source .venv/bin/activate
ansible-playbook playbooks/platform.yml
```

Or run the roles independently, in this order:

```bash
ansible-playbook playbooks/cert-manager.yml
ansible-playbook playbooks/traefik.yml
ansible-playbook playbooks/eck.yml
```

To bootstrap everything from scratch:

```bash
ansible-playbook playbooks/site.yml
```

The kubeconfig is fetched to `artifacts/kubeconfig.yaml`.

## Useful checks

```bash
export KUBECONFIG="$PWD/artifacts/kubeconfig.yaml"

kubectl get nodes
kubectl get pods -n cert-manager
kubectl get clusterissuer lab-ca
kubectl get certificate -n kube-system lab-wildcard
kubectl get secret -n kube-system lab-wildcard-tls
kubectl get svc -n kube-system traefik
kubectl get pods -n metallb-system
kubectl get pods -n elastic-system
kubectl get elasticsearch,kibana,agent -n elastic
kubectl get ingressroute,serverstransport -n elastic
```

Expected external endpoints are:

```text
https://kibana.<lab_domain>
https://es.<lab_domain>
https://fleet.<lab_domain>
```

The certificate served by Traefik should chain as:

```text
*.ares.internal -> Ares Lab Issuing CA -> Ares Lab Root CA
```

## Adding another HTTPS service later

For another service behind Traefik, you normally need no new certificate. Add a DNS name beneath `lab_domain` and an `IngressRoute` with:

```yaml
tls: {}
```

Traefik will use the default cert-manager-managed wildcard certificate.

For a service that needs its own certificate instead, request another cert from the same `ClusterIssuer`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example
  namespace: example
spec:
  secretName: example-tls
  dnsNames:
    - example.ares.internal
  issuerRef:
    name: lab-ca
    kind: ClusterIssuer
```

cert-manager will issue and renew it from the in-cluster intermediate.

## ECK TLS

The external TLS certificate is not used for the Traefik-to-ECK hop. ECK generates and rotates its own backend HTTP certificates. The ECK role creates Traefik `ServersTransport` resources that use the stable ECK `*-http-certs-public` Secrets as trust anchors and verify the internal Kubernetes service names.

## Fleet note

The ECK-managed Kubernetes Agents use the in-cluster Elasticsearch and Fleet Server Services. They do not hairpin through MetalLB/Traefik. An additional external Fleet Server host is preconfigured at `https://fleet.<lab_domain>` for policies you create later for machines outside Kubernetes.

External machines should trust your root CA in their normal OS trust store. The server certificate delivered by Traefik includes the intermediate chain, so clients need only the root trust anchor.

## Cleanup

`playbooks/k3s-nuke.yml` is intentionally destructive and removes the entire K3s installation/state from all listed server nodes.

## K3s role

The K3s bootstrap is implemented as `roles/k3s`; `playbooks/k3s.yml` is only the
thin entry point. The role installs a 1- or odd-sized embedded-etcd server set,
uses Flannel/VXLAN, disables K3s ServiceLB (MetalLB provides LoadBalancer
addresses), and configures each node to use OPNsense through systemd-resolved.

Set these in `inventory/group_vars/all.yml`:

```yaml
k3s_dns_server: "192.168.30.1"
k3s_dns_search_domain: "{{ lab_domain }}"
```

The role writes `/etc/systemd/resolved.conf.d/10-k3s-lab-dns.conf` and points
K3s at `/run/systemd/resolve/resolv.conf`, so CoreDNS sees the actual OPNsense
upstream rather than the `127.0.0.53` local stub.
