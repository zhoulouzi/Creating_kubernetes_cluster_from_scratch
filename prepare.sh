#!/bin/bash
#
#    usage:
#        this script is using for prepare the needed things for creating a kubernetes cluster.
#
######################### change these vars before use.
# cluster level vars: 
CLUSTER_NAME=my-kubernetes-cluster
CLUSTER_API_HOSTNAME=apisever.kubernetes.test
CLUSTER_CIDR=10.0.0.0/16
CLUSTER_DATA_PATH=/data/kubernetes

# docker config vars:
DOCKER_DATA_ROOT_DIR=/data/docker
######################### end

######################### do not change this vars.
# kubelet config vars:
KUBELET_POD_MANIFEST_PATH=$CLUSTER_DATA_PATH/kubelet/manifests/
KUBELET_KUBECONFIG_PATH=$CLUSTER_DATA_PATH/kubelet/kubeconfig
KUBELET_BOOTSTRAPPING_KUBECONFIG_PATH=$CLUSTER_DATA_PATH/kubelet/kubelet-bootstrap.kubeconfig
# kube-proxy config vars:
KUBEPROXY_KUBECONFIG_PATH=$CLUSTER_DATA_PATH/kube-proxy/kubeconfig

# vars for generate
CERTS_DIR=./cfssl_certs
CA_CERT=$CERTS_DIR/ca.pem
CA_KEY=$CERTS_DIR/ca-key.pem
CA_CONFIG=./cfssl_templates/ca_config.json
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
# about ca
## ca key pair generate
if [  -e $CA_CERT  ] && [ -e $CA_KEY ]; then
    echo "The ca key pair has already been generated."
else
    echo "Generate the ca key pair."
    $CFSSL_BIN gencert -initca ./cfssl_config/ca.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/ca
fi

# about api-server
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
    $CFSSL_BIN gencert -ca=$CA_CERT -ca-key=$CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/api-server.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/api-server
fi

# about kube-proxy
## kube-proxy key pair generate
if [ -e $CERTS_DIR/kub-proxy.pem ] && [ -e $CERTS_DIR/kube-proxy-key.pem ];then
    echo "kube_proxy key pair has already been generate"
else
    echo "Generate the kube_proxy key pair"
    $CFSSL_BIN gencert -ca=$CA_CERT -ca-key=$CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/kube-proxy.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kube-proxy
fi

# about kube-admin
## kube-admin key pair generate
if [ -e $CERTS_DIR/kube-admin.pem ] && [ -e $CERTS_DIR/kube-admin-key.pem ];then
    echo "kube-admin key pair has already been generate"
else
    echo "Generate the kube-admin key pair"
    $CFSSL_BIN gencert -ca=$CA_CERT -ca-key=$CA_KEY --config=$CA_CONFIG -profile=kubernetes ./cfssl_config/kube-admin.csr | $CFSSLJSON_BIN -bare $CERTS_DIR/kube-admin
fi

# about kubelet
# kubelet tls bootstrapping
# accroding to the pages on kubernetes docs.  ##https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/
BOOTSTRAPPING_TOKEN=`head -c 16 /dev/urandom | od -An -t x | tr -d ' '`
if [ -e token-auth-file ] ; then
    echo "The token-auth-file has already been generated."
else
    echo "$BOOTSTRAPPING_TOKEN,kubelet-bootstrap,10001,\"system:bootstrappers\"" > $CERTS_DIR/token-auth-file
fi
############## end gen tls key pair


############## start gen kubeconfig file
# kubeconfig for kube-proxy
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig
$KUBECTL_BIN config set-credentials kube-proxy --client-certificate=$CERTS_DIR/kube-proxy.pem --client-key=$CERTS_DIR/kube-proxy-key.pem --embed-certs=true --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kube-proxy --cluster=${CLUSTER_NAME} --user=kube-proxy --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kube-proxy --kubeconfig=$KUBECONFIG_DIR/kube-proxy.kubeconfig

# kubeconfig for cluster admin
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig
$KUBECTL_BIN config set-credentials kube-admin --client-certificate=$CERTS_DIR/kube-admin.pem --client-key=$CERTS_DIR/kube-admin-key.pem --embed-certs=true --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kube-admin --cluster=${CLUSTER_NAME} --user=kube-admin --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kube-admin --kubeconfig=$KUBECONFIG_DIR/kube-admin.kubeconfig

# kubeconfig for kubelet (TLS bootstrapping)
$KUBECTL_BIN config set-cluster ${CLUSTER_NAME} --certificate-authority=$CA_CERT --embed-certs=true --server=https://${CLUSTER_API_HOSTNAME}:6443 --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
$KUBECTL_BIN config set-credentials kubelet-bootstrap --token=${BOOTSTRAPPING_TOKEN} --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
$KUBECTL_BIN config set-context ${CLUSTER_NAME}_kubelet-bootstrap --cluster=${CLUSTER_NAME} --user=kubelet-bootstrap --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
$KUBECTL_BIN config use-context ${CLUSTER_NAME}_kubelet-bootstrap --kubeconfig=$KUBECONFIG_DIR/kubelet-bootstrap.kubeconfig
############## end gen kubeconfig file


# start prepare ansible vars.

# handle vars on ./roles/kubernetes-master/vars/main.yaml.

sed "s/{{CLUSTER_NAME}}/$CLUSTER_NAME/g; \
    s/{{CLUSTER_CIDR}}/$CLUSTER_CIDR/g; \
    s/{{CLUSTER_DATA_PATH}}/$CLUSTER_DATA_PATH/g; \
    s/{{CLUSTER_API_HOSTNAME}}/$CLUSTER_API_HOSTNAME/g; \
    s/{{KUBELET_POD_MANIFEST_PATH}}/$KUBELET_POD_MANIFEST_PATH/g; \
    s/{{KUBELET_KUBECONFIG_PATH}}/$KUBELET_KUBECONFIG_PATH/g; \
    s/{{KUBEPROXY_KUBECONFIG_PATH}}/$KUBEPROXY_KUBECONFIG_PATH/g;" \
    ./role/kubernetes-master/vars/main.yaml.template > ./role/kubernetes-master/vars/main.yaml

