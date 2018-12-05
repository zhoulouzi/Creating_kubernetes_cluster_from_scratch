## 0.0.1 - 2018-12-05
### Changes
- Reorganize addon_config dir for cluster level addons.
- Add CHANGELOG.md
- Add node-probelem-detector manual install config yaml.
- Add config to kube-apiserver for [Configure the Aggregation Layer](https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/)

### Kubernetes cluster info

#### Kubernetes Components
- kubelet v1.12.3
- kube-proxy v1.12.3
- docker-ce 18.06
- etcd 3.2.18
- kube-apiserver v1.12.3
- kube-controller-manager v1.12.3
- kube-scheduler v1.12.3

#### Kubernetes Addons

- calico  v3.1.3 --> v3.3.1
- cert-manager v0.5.2
- coredns 1.2.0
- kubernetes-dashboard v1.10.0
- dns-horizontal-autoscaler 1.3.0
- heapster v1.5.4
- metrics-server v0.3.1
- nginx-ingress 0.18.0 ---> 0.21.0
- node-problem-detector v0.4.1