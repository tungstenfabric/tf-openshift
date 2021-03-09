 # This project is an add-on to RedHat Openshift Container Platform enabling the deployment with Tungsten Fabric (TF) as SDN
## The supported Openshift version is 4.5.x

# The overall Openshift deploy process is the same as described in [the official Openshift documentation](https://docs.openshift.com/container-platform/4.5/installing)

## Deploy with TF SDN enabled needs just a few additional steps to the main instruction
### In general the steps are in depended on where you are going to install Openshift to - AWS, GCP, KVM ,etc. But for now the project is tested on KVM hypervisor according to [baremetal installation procedure](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html).

## The below there are addition steps based on [baremetal installation procedure](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html)

1. Set networkType param to Contrail in install-config.yaml at the [step creating the installation configuration file](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html#installation-initializing-manual_installing-bare-metal)

2. Add TF Openshift manifests right after step of [creation Openshift install manifests](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html#installation-user-infra-generate-k8s-manifest-ignition_installing-bare-metal)
```bash
# 1. Generate the Kubernetes manifests for the cluster (step from the main instruction)
./openshift-install create manifests --dir=<installation_directory>

# 2. Download TF Openshift manifests add add them to the installation (additional step)
git clone https://github.com/progmaticlab/tf-openshift.git
./tf-openshift/scripts/apply_install_manifests.sh <installation_directory>
./openshift-install create ignition-configs --dir=<installation_directory>
```

3. Apply TF Operator manifests after machines are prepared and [**before** creating the cluster](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-installing-bare-metal_installing-bare-metal-network-customizations)
```bash
# Download TF Operator project
git clone https://github.com/tungstenfabric/tf-operator.git

# Prepare TF Kubernetes manifests (use your cluster and domain names)
export KUBECONFIG=<installation_directory>/auth/kubeconfig
export CONTRAIL_CONTAINER_TAG=<Tungsten Fabric UBI images tag>
export CONTAINER_REGISTR=<Tungsten Fabric UBI images registry>
export DEPLOYER="openshift"
export KUBERNETES_CLUSTER_NAME="test1"
export KUBERNETES_CLUSTER_DOMAIN="example.com"
./tf-operator/contrib/render_manifests.sh

# Apply TF manifests
./oc apply -f ./tf-operator/deploy/crds/
./oc wait crds --for=condition=Established --timeout=2m managers.contrail.juniper.net
./oc apply -k ./tf-operator/deploy/kustomize/operator/templates/
./oc apply -k ./tf-operator/deploy/kustomize/contrail/templates/

4. Proceed with main instruction to [create the cluster](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-installing-bare-metal_installing-bare-metal-network-customizations)
E.g. 
```bash
openshift-install --dir=<installation_directory> wait-for bootstrap-complete
```
