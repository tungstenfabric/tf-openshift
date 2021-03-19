# This project is an add-on to RedHat Openshift Container Platform enabling the deployment with Tungsten Fabric (TF) as SDN
The supported Openshift versions are 4.5 and 4.6

# The overall Openshift deploy process is the same as described in [the official Openshift documentation](https://docs.openshift.com/container-platform/4.5/welcome/index.html)

## Deploy with TF SDN enabled needs just a few additional steps to the main instruction
### In general the steps are in depended on where you are going to install Openshift to - AWS, GCP, KVM ,etc. But for now the project is tested on KVM hypervisor according to [baremetal installation procedure](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html).

## The below there are addition steps based on [baremetal installation procedure](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html)

1. Set networkType param to Contrail in install-config.yaml at the [step creating the installation configuration file](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html#installation-initializing-manual_installing-bare-metal)

2. Add TF Openshift manifests right after step of [creation Openshift install manifests](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html#installation-user-infra-generate-k8s-manifest-ignition_installing-bare-metal)
```bash
export INSTALL_DIR=<your installation_directory>

# 1. Generate the Kubernetes manifests for the cluster (step from the main instruction)
./openshift-install create manifests --dir=$INSTALL_DIR

# 2. Download TF Openshift manifests add add them to the installation (additional step)
git clone https://github.com/tungstenfabric/tf-openshift.git
./tf-openshift/scripts/apply_install_manifests.sh $INSTALL_DIR

# 3. Download TF Operator manifests add add them to the installation (additional step)
git clone https://github.com/tungstenfabric/tf-operator.git
export CONTRAIL_CONTAINER_TAG=<Containers UBI based images tag (tungstenfabric on dockerhub by default)>
export CONTAINER_REGISTRY=<Containers UBI based images registry (latest by default)>
export KUBECONFIG=$INSTALL_DIR/auth/kubeconfig
export DEPLOYER="openshift"
export KUBERNETES_CLUSTER_NAME="test1"
export KUBERNETES_CLUSTER_DOMAIN="example.com"
export CONTRAIL_REPLICAS=3
# process manifests (put cluster name, domain etc)
#   install python3 if missed before:
#     yum install -y python3
#     python3 -m pip install jinja2
./tf-operator/contrib/render_manifests.sh
# copy TF CRDs resources
for i in $(ls ./tf-operator/deploy/crds/) ; do
  cp ./tf-operator/deploy/crds/$i $INSTALL_DIR/manifests/01_$i
done
# copy TF operator resources
for i in namespace service-account role cluster-role role-binding cluster-role-binding ; do
  cp ./tf-operator/deploy/kustomize/base/operator/$i.yaml $INSTALL_DIR/manifests/02-tf-operator-$i.yaml
done
oc kustomize ./tf-operator/deploy/kustomize/operator/templates/ | sed -n 'H; /---/h; ${g;p;}' > $INSTALL_DIR/manifests/02-tf-operator.yaml
# copy TF reources
oc kustomize ./tf-operator/deploy/kustomize/contrail/templates/ > $INSTALL_DIR/manifests/03-tf.yaml
```

3. Proceed with main intruction from the step
```bash
# Create ignition configs
./openshift-install create ignition-configs --dir=<installation_directory>
```


## [Example of installation on AWS](Readme_aws.md)
