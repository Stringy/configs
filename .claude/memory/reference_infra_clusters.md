---
name: Infra cluster access
description: How to find, connect to, and use ephemeral infra test clusters (infractl / OpenShift)
type: reference
---

## Infra Clusters

Ephemeral test clusters provisioned via `infractl` on `infra.rox.systems`. Used for running e2e tests, deploying StackRox, and manual testing.

### Finding the active cluster

```bash
# List all clusters with status and remaining lifespan
infractl list

# Cluster names follow pattern: gdth-MM-DD-N (e.g. gdth-03-30-1)
# Look for Status: READY and positive lifespan remaining
```

### Connecting to a cluster

Artifacts are downloaded to `~/infra/<cluster-name>/`. Key files:
- `kubeconfig` — use with kubectl/oc
- `dotenv` — cluster metadata (console URL, credentials, region)
- `cluster-console-url`, `cluster-console-password` — OpenShift web console

```bash
# Download artifacts if not already present
infractl artifacts --download-dir ~/infra/<cluster-name> <cluster-name>

# Set KUBECONFIG to use the cluster
export KUBECONFIG=~/infra/<cluster-name>/kubeconfig
```

**How to apply:** When asked to run something on "my infra cluster" or "the test cluster":
1. Run `infractl list` to find READY clusters owned by ghutton
2. Pick the most recent one (highest date suffix)
3. Check if artifacts exist at `~/infra/<name>/kubeconfig`
4. If not, run `infractl artifacts --download-dir ~/infra/<name> <name>`
5. Set `KUBECONFIG=~/infra/<name>/kubeconfig` before running kubectl/oc commands

### Common operations

```bash
# Create a new cluster
infractl create openshift-4 --lifespan 8h

# Extend lifespan
infractl lifespan <cluster-name> +2h

# Run kubectl commands against the cluster
KUBECONFIG=~/infra/<name>/kubeconfig kubectl get pods -n stackrox

# SSH to cluster nodes (after extracting data.tgz)
~/infra/<name>/data/ssh/deploy/deploy.sh   # deploy bastion first
~/infra/<name>/data/ssh/ssh.sh <node-name>  # then SSH
```

### Flavors

Default is `openshift-4`. Others: `gke-default`, `eks`, `aks`, `rosa`, `rosahcp`, `qa-demo`.

## Local k3s Cluster

A local k3s cluster is installed on the laptop for rapid iteration. Not OpenShift — no SCCs, routes, or operators.

```bash
# Switch to local cluster
# isl   (infra-local)
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Managed by systemd, starts on boot
sudo systemctl start|stop k3s
```

**When to use:** Fast deploy-test cycles during active development, especially detection/policy work. Use infra clusters for full integration testing and OCP-specific features.
