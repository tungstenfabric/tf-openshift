
# Example of installation on AWS

Deployment procedure is based on OCP4.6 this [installation procedure](https://docs.openshift.com/container-platform/4.6/installing/installing_aws/installing-aws-customizations.html)

## Prerequisities
Prerequisities that have to be fulfilled in order to depeloy TF with operator on Openshift:
* Openshift pull secrets ([download](https://cloud.redhat.com/openshift/install/pull-secret))
* Configured AWS account with proper permissions and resolvable base domain configured in Route53 ([documentation](https://docs.openshift.com/container-platform/4.6/installing/installing_aws/installing-aws-account.html#installing-aws-account))
* Any SSH key generated on local machine to provide during installation
* openshift-install binary and oc client tool (4.6) ([download](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.6))
* git, jq, python3 are installed on the orchestrating node

## Deployment

### 1. Create install config with:
```bash
export INSTALL_DIR=~/openshift-dir
./openshift-install create install-config --dir=$INSTALL_DIR
```
In created YAML file under specified directory:
- change change *networkType* field to *Contrail* in the *networking* section (instead of *OpenshiftSDN*)
- ajust other cluster settings to your environment if eny

**NOTE**: Master nodes need larger instances.
For example, If you run cluster on AWS, use e.g. *m5.2xlarge*.

### 2. Create manifests with
```bash
./openshift-install create manifests --dir=$INSTALL_DIR
```

### 3. Set configuration parameters
```bash
export DEPLOYER="openshift"
export KUBERNETES_CLUSTER_NAME="test1"
export KUBERNETES_CLUSTER_DOMAIN="example.com"
export CONTAINER_REGISTRY="docker.io/tungstenfabric"
export CONTRAIL_CONTAINER_TAG="nightly"
# is oeprator in different repo adn/or tag, provide it like:
#export DEPLOYER_CONTAINER_REGISTRY="docker.io/tungstenfabric"
# export CONTRAIL_DEPLOYER_CONTAINER_TAG="nightly"
export CONTRAIL_REPLICAS=3

# Not required. NTP-servers for Chrony.
export NTP_SERVERS="0.us.pool.ntp.org 1.us.pool.ntp.org"
```
**NOTE**: *KUBERNETES_CLUSTER_NAME* and *KUBERNETES_CLUSTER_DOMAIN* must be exactly the same as it is in install-config.yaml

### 4. Install manifests
Download TF Openshift manifests add add them to the installation 
```bash
git clone -b R2011 https://github.com/tungstenfabric/tf-openshift.git
./tf-openshift/scripts/apply_install_manifests.sh $INSTALL_DIR
```
Download and render TF Operator manifests
```bash
git clone -b R2011 https://github.com/tungstenfabric/tf-operator.git
./tf-operator/contrib/render_manifests.sh
```
Add TF CRDs resources into installation folder
```bash
for i in $(ls ./tf-operator/deploy/crds/) ; do
  cp ./tf-operator/deploy/crds/$i $INSTALL_DIR/manifests/01_$i
done
```
Copy TF Operator and TF resources into installation folder
```bash
for i in namespace service-account role cluster-role role-binding cluster-role-binding ; do
  cp ./tf-operator/deploy/kustomize/base/operator/$i.yaml $INSTALL_DIR/manifests/02-tf-operator-$i.yaml
done
oc kustomize ./tf-operator/deploy/kustomize/operator/templates/ | sed -n 'H; /---/h; ${g;p;}' > $INSTALL_DIR/manifests/02-tf-operator.yaml
oc kustomize ./tf-operator/deploy/kustomize/contrail/templates/ > $INSTALL_DIR/manifests/03-tf.yaml
```

### 5. Install Openshift
```bash
./openshift-install create cluster --dir=$INSTALL_DIR
```

### 6. Open security groups:
Login to AWS Console and find *master* instance created by the *openshift-installer*. Select Security Group attached to it and edit it's inbound rules to accept all traffic. **Do the same for the security group attached to worker nodes, after they are created.**

### 7. Patch the externalTrafficPolicy

Verify that the **router-default** service has been created, by running:
```bash
oc -n openshift-ingress describe service router-default
```
If it is not present yet, wait until it is created. Then patch the externalTrafficPolicy by running this command:
```bash
oc -n openshift-ingress patch service router-default --patch '{"spec": {"externalTrafficPolicy": "Cluster"}}'
```
### 8. Access cluster after deployment
In order to access export **KUBECONFIG** environment variable.
**KUBECONFIG** file may be found under **$INSTALL_DIR/auth/kubeconfig** E.g.
```bash
export KUBECONFIG=$INSTALL_DIR/auth/kubeconfig
```
Afterwards cluster may be accessed with `oc` and/or `kubectl` command line tool.

It's also possible to access cluster with dedicated Openshift command line tool: `oc`.
However, `oc` requires to login before.
After successful deployment **openshift-install** binary prints out username (**kubeadmin**) and password to cluster.
Password may be also found also under **$INSTALL_DIR/auth/** directory.

Login into `oc` may be performed with this command:
```bash
oc login -u kubeadmin -p <cluster password>
```
Last method to access Openshift cluster is web console.
URL to web console will be displayed by **openshift-install** binary at the end of deployment.
Login into console with the same credentials as for `oc`.
