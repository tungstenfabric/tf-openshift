#!/bin/bash
set -eo pipefail

function realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

my_file=$(realpath "$0")
my_dir="$(dirname $my_file)"
DEPLOY_DIR=${DEPLOY_DIR:=$my_dir/../deploy}

if [[ $# != "1" ]]; then
  echo "Pass path to openshift install directory as the param"
  exit 1
fi

install_dir=$1

if [[ -n "$NTP_SERVERS" ]]; then
  jinja2="$my_dir/jinja2_render.py"
  export CHRONY_CONF_BASE64="$($jinja2 < $my_dir/../templates/chrony.conf.j2 | base64 -w 0)"
  for i in worker master; do
    export ROLE=$i
    $jinja2 < $my_dir/../templates/chrony-configuration.yaml.j2 > $DEPLOY_DIR/openshift/99_${i}s-chrony-configuration.yaml
  done
fi

cp $DEPLOY_DIR/manifests/* $install_dir/manifests
cp $DEPLOY_DIR/openshift/* $install_dir/openshift

#cp $DEPLOY_DIR/openshift/99_master-iptables-machine-config.yaml $install_dir/openshift
#cp $DEPLOY_DIR/openshift/99_master-pv-mounts.yaml $install_dir/openshift
#cp $DEPLOY_DIR/openshift/99_master-kernel-modules-overlay.yaml $install_dir/openshift
