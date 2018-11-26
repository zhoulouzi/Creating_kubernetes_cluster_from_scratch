
# Creating a HA kubernetes cluster from Scratch.

This project is helping you to creating a HA kubernetes cluster step by step.

**Install Overview:**

|  | version | service management |
| :--- | :----: | ----: |
| docker | 17.03.2 | systemd |
| kubelet | 1.11.0 | systemd |
| kube-proxy | 1.11.0 | systemd |
| etcd | 3.2.18 | kubelet/docker |
| kube-apiserver | 1.11.0 | kubelet/docker |
| kube-controller-manager | 1.11.0 | kubelet/docker  |
| kube-scheduler| 1.11.0 | kubelet/docker  |

**Arch：**
![arch ](https://res.cloudinary.com/ddvxfzzbe/image/upload/v1543227461/kuberetes%E6%9E%B6%E6%9E%84%E5%9B%BE_uimtft.png)
**Docs:**
[Creating a Custom Cluster from Scratch](https://kubernetes.io/docs/setup/scratch/)
[docker install official document](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
[installing calico  for kubernetes](https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/calico)

**Setup:**

 1. Download the tarball from the release page [kubernetes release page](https://github.com/kubernetes/kubernetes/releases).
	
		$tar -zxvf kubernetes.tar.gz
		$cd kubernetes/cluster/ && bash get-kube.sh
		$cd kubernetes/cluster/kubernetes/server && tar -zxvf kubernetes-server-linux-amd64.tar.gz
		$ls kubernetes/server/bin/ 
	Copy the kubelet、kube-proxy  to  the binaries dir.

 2. change the cluster info in prepare.sh and ansible hosts and my-kubernetes-cluster.yaml
here is my cluster config. you may change thess vars later.
ansible hosts:

		all:
		  children:
		    kubernetes:
		      children:
		        master:
		          hosts:
		            master1.kubernetes.test: 
		              ansible_host: 172.16.0.101
		            master2.kubernetes.test:
		              ansible_host: 172.16.0.102
		            master3.kubernetes.test:
		              ansible_host: 172.16.0.103
		          vars:
		            ansible_user: root
		        node:
		          hosts:
		            node1.kubernetes.test:
		              ansible_host: 172.16.0.104
			        node2.kubernetes.test:
		              ansible_host: 172.16.0.105
		            node3.kubernetes.test:
		              ansible_host: 172.16.0.106
		          vars:
		            ansible_user: root
	prepare.sh

		CLUSTER_NAME=my-kubernetes-cluster
		CLUSTER_API_HOSTNAME=apisever.kubernetes.test
		CLUSTER_CIDR=10.0.0.0/16
		CLUSTER_DATA_PATH=/data/kubernetes
		CLUSTER_MASTER_LIST=("master1.kubernetes.test"  "master2.kubernetes.test"  "master3.kubernetes.test")
		DOCKER_DATA_ROOT_DIR=/data/docker
	
 3.  Generate tls keys、kubeconfig files、ansible vars.

	$bash prepare.sh
		  ...
 4.  use ansible-playbook to bootstarp the cluster.

	$ansible-playbook my-kubernetes-cluster.yaml

 5.  the cluster has been setup ready for work.

**Check everything is work.**

**etcd cluster overview:**

	$etcdctl member list
	8947ad53cf2dcb09: name=master2 peerURLs=http://172.16.0.102:2380 clientURLs=http://172.16.0.102:2379 isLeader=false
	902b43a26fe9e976: name=master3 peerURLs=http://172.16.0.103:2380 clientURLs=http://172.16.0.103:2379 isLeader=false
	c130f4a591f954a9: name=master1 peerURLs=http://172.16.0.101:2380 clientURLs=http://172.16.0.101:2379 isLeader=true
	
**kube-apiserver overview:**
	
	NAMESPACE     NAME                                              READY     STATUS    RESTARTS   AGE
	kube-system   kube-apiserver-master1.kubernetes.test            1/1       Running   0         1m
	kube-system   kube-apiserver-master2.kubernetes.test            1/1       Running   0         1m
	kube-system   kube-apiserver-master3.kubernetes.test            1/1       Running   0         1m

**kube-controller-manager overview:**

	NAMESPACE     NAME                                              READY     STATUS    RESTARTS   AGE
	kube-system   kube-controller-manager-master1.kubernetes.test   1/1       Running   0          1m
	kube-system   kube-controller-manager-master2.kubernetes.test   1/1       Running   0          1m
	kube-system   kube-controller-manager-master3.kubernetes.test   1/1       Running   0          1m
 
 **kube-scheduler overview:**
 
	kube-system   kube-scheduler-master1.kubernetes.test            1/1       Running   17         3d
	kube-system   kube-scheduler-master2.kubernetes.test            1/1       Running   16         5d
	kube-system   kube-scheduler-master3.kubernetes.test            1/1       Running   12         6d
