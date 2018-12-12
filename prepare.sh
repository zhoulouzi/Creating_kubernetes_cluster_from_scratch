#!/bin/bash
#
#    usage:
#        this script is using for prepare the needed things for creating a kubernetes cluster.
#
######################### Vars For your enviroment (change these vars before use).
# cluster level vars: 
CLUSTER_NAME=my-kubernetes-cluster
CLUSTER_API_HOSTNAME=apisever.kubernetes.test
CLUSTER_CIDR=10.0.0.0/16
CLUSTER_DATA_PATH=/data/kubernetes
CLUSTER_MASTER_LIST=("master1.kubernetes.test" "master2.kubernetes.test" "master3.kubernetes.test")

# docker config vars:
DOCKER_DATA_ROOT_DIR=/data/docker
######################### end

######################### Vars For TLS or Kubeconfig (DO not change!)
# Kubelet config vars:
KUBELET_POD_MANIFEST_PATH=$CLUSTER_DATA_PATH/kubelet/manifests/
KUBELET_KUBECONFIG_PATH=$CLUSTER_DATA_PATH/kubelet/kubeconfig
KUBELET_BOOTSTRAPPING_KUBECONFIG_PATH=$CLUSTER_DATA_PATH/kubelet/kubelet-bootstrap.kubeconfig
# kube-proxy config vars:
KUBEPROXY_KUBECONFIG_PATH=$CLUSTER_DATA_PATH/kube-proxy/kubeconfig

# Vars for generate
CERTS_DIR=./cfssl_certs
# Three CA PATH:
CA_CONFIG=./cfssl_config/ca_config.json
# 1.Kubernetes CA:
KUBERNETES_CA_CERT=$CERTS_DIR/kubernetes-ca.pem
KUBERNETES_CA_KEY=$CERTS_DIR/kubernetes-ca-key.pem
# 2.Etcd CA:
ETCD_CA_CERT=$CERTS_DIR/etcd-ca.pem
ETCD_CA_KEY=$CERTS_DIR/etcd-ca-key.pem
# 3.Kubernetes-front-proxy CA:
KUBERNETES_FRONT_PROXY_CA_CERT=$CERTS_DIR/kubernetes-front-proxy-ca.pem
KUBERNETES_FRONT_PROXY_CA_KEY=$CERTS_DIR/kubernetes-front-proxy-ca-key.pem

KUBECONFIG_DIR=./kubeconfig
######################### end

if [ `uname` = "Darwin" ]; then
    KUBECTL_BIN=./bin/kubectl-mac
    CFSSL_BIN=./bin/cfssl-mac
    CFSSLJSON_BIN=./bin/cfssljson-mac
else
    KUBECTL_BIN=./bin/kubectl
    CFSSL_BIN=./bin/cfssl
    CFSSLJSON_BIN=./bin/cfssljson
fi

############## start gen tls key pair
mkdir -p $CERTS_DIR

# Three CA:
# 1. Kubernetes CA:
if [  -e $KUBERNETES_CA_CERT  ] && [ -e $KUBERNETES_CA_KEY ]; then
    echo "The kubernetes-ca key pair has already been generated."
else
    echo "Generate the kubernetes-ca key pair."
    $CFSSL_BIN gencert -initca ./cfssl_config/kubernetes_ca.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kubernetes-ca
fi

# 2.Etcd CA:
if [  -e $ETCD_CA_CERT  ] && [ -e $ETCD_CA_KEY ]; then
    echo "The etcd-ca key pair has already been generated."
else
    echo "Generate the etcd-ca key pair."
    $CFSSL_BIN gencert -initca ./cfssl_config/etcd_ca.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/etcd-ca
fi

# 3.Kubernetes-front-proxy CA:
if [  -e $KUBERNETES_FRONT_PROXY_CA_CERT  ] && [ -e $KUBERNETES_FRONT_PROXY_CA_KEY ]; then
    echo "The kubernetes-front-proxy-ca key pair has already been generated."
else
    echo "Generate the kubernetes-front-proxy-ca key pair."
    $CFSSL_BIN gencert -initca ./cfssl_config/kubernetes-front-proxy_ca.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kubernetes-front-proxy-ca
fi

# Certs for components.
# api-server certs sign by Kubernetes CA
## gen api-server.csr for cfssl
if [ -e ./cfssl_config/api-server.csr ];then
    echo "the api-server.csr has already been generate"
else
    echo "Generate the api-server.csr"
    sed "s/{{CLUSTER_API_HOSTNAME}}/$CLUSTER_API_HOSTNAME/g;" ./cfssl_config/api-server.csr.template > ./cfssl_config/api-server.csr
fi
## api server key pair generate
if [ -e $CERTS_DIR/api-server.pem ] && [ -e $CERTS_DIR/api-server-key.pem ];then
    echo "api-server key pair has already been generate"
else
    echo "Generate the api-server key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/api-server.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/api-server
fi

# api-server kubelet-client key pair sign by Kubernetes CA
if [ -e $CERTS_DIR/apiserver-kubelet-client.pem ] && [ -e $CERTS_DIR/apiserver-kubelet-client-key.pem ];then
    echo "apiserver-kubelet-client key pair has already been generate"
else
    echo "Generate the apiserver-kubelet-client key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/apiserver-kubelet-client.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/apiserver-kubelet-client
fi

## kube-controller-manager certs sign by Kubernetes CA
if [ -e $CERTS_DIR/kube-controller-manager.pem ] && [ -e $CERTS_DIR/kube-controller-manager-key.pem ];then
    echo "kube-controller-manager key pair has already been generate"
else
    echo "Generate the kube-controller-manager key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/kube-controller-manager.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kube-controller-manager
fi

## kube-scheduler certs sign by Kubernetes CA
if [ -e $CERTS_DIR/kube-scheduler.pem ] && [ -e $CERTS_DIR/kube-scheduler.pem ];then
    echo "kube-scheduler key pair has already been generate"
else
    echo "Generate the kube-scheduler key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/kube-scheduler.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kube-scheduler
fi

# kube-proxy certs sign by Kubernetes CA
## kube-proxy key pair generate
if [ -e $CERTS_DIR/kube-proxy.pem ] && [ -e $CERTS_DIR/kube-proxy-key.pem ];then
    echo "kube_proxy key pair has already been generate"
else
    echo "Generate the kube_proxy key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/kube-proxy.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kube-proxy
fi

# kube-admin certs sign by Kubernetes CA
## kube-admin key pair generate
if [ -e $CERTS_DIR/kube-admin.pem ] && [ -e $CERTS_DIR/kube-admin-key.pem ];then
    echo "kube-admin key pair has already been generate"
else
    echo "Generate the kube-admin key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/kube-admin.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kube-admin
fi

# about kubelet
## master kubelet key pair generate
for i in "${CLUSTER_MASTER_LIST[@]}"; do
    if [ -e $CERTS_DIR/kubelet-$i.pem ] && [ -e $CERTS_DIR/kubelet-$i-key.pem ];then
        echo "Node $i's key pair has already been generate "
    else
        echo "Generate th Node $i's key pair"
        sed "s/{{HOSTNAME}}/$i/g" ./cfssl_config/kubelet.csr.template > ./cfssl_config/kubelet-$i.csr
        $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/kubelet-$i.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kubelet-$i
    fi
done

## kubelet tls bootstrapping
### accroding to the pages on kubernetes docs.  ##https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/
#TODO Diff with kubeadm,Use Token authentication file instead of Bootstrap Tokens for kubelet-tls-bootstrapping.
BOOTSTRAPPING_TOKEN=`head -c 16 /dev/urandom | od -An -t x | tr -d ' '`
if [ -e token-auth-file ] ; then
    echo "The token-auth-file has already been generated."
else
    echo "$BOOTSTRAPPING_TOKEN,kubelet-bootstrap,10001,\"system:bootstrappers\"" > $CERTS_DIR/token-auth-file
fi

## service-accounts key pair 
## service-accounts key pair generate
if [ -e $CERTS_DIR/service-accounts.pem ] && [ -e $CERTS_DIR/service-accounts-key.pem ];then
    echo "service-accounts key pair has already been generate"
else
    echo "Generate the service-accounts key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_CA_CERT -ca-key=$KUBERNETES_CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/service-accounts.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/service-accounts
fi

# Sign by kubernetes-front-proxy CA
# front-proxy-client key pair sign by kubernetes-front-proxy-ca
if [ -e $CERTS_DIR/front-proxy-client.pem ] && [ -e $CERTS_DIR/front-proxy-client-key.pem ];then
    echo "front-proxy-client key pair has already been generate"
else
    echo "Generate the front-proxy-client key pair"
    $CFSSL_BIN gencert -ca=$KUBERNETES_FRONT_PROXY_CA_CERT -ca-key=$KUBERNETES_FRONT_PROXY_CA_KEY --config=$CA_CONFIG -profile=kubernetes-front-proxy ./cfssl_config/front-proxy-client.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/front-proxy-client
fi

############## end gen tls key pair


############## start gen kubeconfig file
# kubeconfig for kube-proxy
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$KUBERNETES_CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig
$KUBECTL_BIN config set-credentials kube-proxy --client-certificate=$CERTS_DIR/kube-proxy.pem --client-key=$CERTS_DIR/kube-proxy-key.pem --embed-certs=true --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kube-proxy --cluster=${CLUSTER_NAME} --user=kube-proxy --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kube-proxy --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig

# kubeconfig for kube-controller-manager
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$KUBERNETES_CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kube-controller-manager.kubeconfig
$KUBECTL_BIN config set-credentials kube-controller-manager --client-certificate=$CERTS_DIR/kube-controller-manager.pem --client-key=$CERTS_DIR/kube-controller-manager-key.pem --embed-certs=true --kubeconfig=$KUBECONFIG_DIR/kube-controller-manager.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kube-controller-manager --cluster=${CLUSTER_NAME} --user=kube-controller-manager --kubeconfig=$KUBECONFIG_DIR/kube-controller-manager.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kube-controller-manager --kubeconfig=$KUBECONFIG_DIR/kube-controller-manager.kubeconfig

# kubeconfig for kube-scheduler
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$KUBERNETES_CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kube-scheduler.kubeconfig
$KUBECTL_BIN config set-credentials kube-scheduler --client-certificate=$CERTS_DIR/kube-scheduler.pem --client-key=$CERTS_DIR/kube-scheduler-key.pem --embed-certs=true --kubeconfig=$KUBECONFIG_DIR/kube-scheduler.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kube-scheduler --cluster=${CLUSTER_NAME} --user=kube-scheduler --kubeconfig=$KUBECONFIG_DIR/kube-scheduler.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kube-scheduler --kubeconfig=$KUBECONFIG_DIR/kube-scheduler.kubeconfig

# kubeconfig for cluster admin
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$KUBERNETES_CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig
$KUBECTL_BIN config set-credentials kube-admin --client-certificate=$CERTS_DIR/kube-admin.pem --client-key=$CERTS_DIR/kube-admin-key.pem --embed-certs=true --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kube-admin --cluster=${CLUSTER_NAME} --user=kube-admin --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kube-admin --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig

# kubeconfig for kubelet (master)
for i in "${CLUSTER_MASTER_LIST[@]}"; do
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$KUBERNETES_CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kubelet-$i.kubeconfig
$KUBECTL_BIN config set-credentials kubelet --client-certificate=$CERTS_DIR/kubelet-$i.pem --client-key=$CERTS_DIR/kubelet-$i-key.pem --embed-certs=true --kubeconfig=$KUBECONFIG_DIR/kubelet-$i.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kubelet --cluster=${CLUSTER_NAME} --user=kubelet --kubeconfig=$KUBECONFIG_DIR/kubelet-$i.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kubelet --kubeconfig=$KUBECONFIG_DIR/kubelet-$i.kubeconfig
done

# kubeconfig for kubelet (TLS bootstrapping)
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$KUBERNETES_CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
$KUBECTL_BIN config set-credentials kubelet-bootstrap --token=${BOOTSTRAPPING_TOKEN} --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kubelet-bootstrap --cluster=${CLUSTER_NAME} --user=kubelet-bootstrap --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kubelet-bootstrap --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
############## end gen kubeconfig file


# start prepare ansible vars.
# handle vars on ./roles/kubernetes/vars/main.yaml.
sed "s@{{CLUSTER_NAME}}@$CLUSTER_NAME@g; \
    s@{{CLUSTER_CIDR}}@$CLUSTER_CIDR@g; \
    s@{{CLUSTER_DATA_PATH}}@$CLUSTER_DATA_PATH@g; \
    s@{{CLUSTER_API_HOSTNAME}}@$CLUSTER_API_HOSTNAME@g; \
    s@{{KUBELET_POD_MANIFEST_PATH}}@$KUBELET_POD_MANIFEST_PATH@g; \
    s@{{KUBELET_KUBECONFIG_PATH}}@$KUBELET_KUBECONFIG_PATH@g; \
    s@{{KUBELET_BOOTSTRAPPING_KUBECONFIG_PATH}}@$KUBELET_BOOTSTRAPPING_KUBECONFIG_PATH@g; \
    s@{{KUBEPROXY_KUBECONFIG_PATH}}@$KUBEPROXY_KUBECONFIG_PATH@g;" \
    ./roles/kubernetes/vars/main.yaml.template > ./roles/kubernetes/vars/main.yaml

