Manifests for prepare openshift cluster to Tungsten fabric networking.

Tested openshift version: 4.5.21

Insert these manifists together with tf-operator manifests (https://github.com/tungstenfabric/tf-operator) after 'openshift-install crete manifests' and before 'openshift-install create ignition-configs' stages in openshift 4.x installation process.