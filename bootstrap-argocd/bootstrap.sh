#!/bin/sh

DIR_BOOTSTRAP=$(echo $PWD | grep "bootstrap-argocd$")
DIR_DEPLOYMENTS="../deployments"
TEMPLATE_PATH=$1

_helm_function() {
	echo "$TEMPLATE_PATH"
	helm upgrade --install argocd argo-cd --repo https://argoproj.github.io/argo-helm --namespace argocd --create-namespace --version 4.2.2
	helm upgrade --install -f "$TEMPLATE_PATH" argocd-bootstrap-application ./bootstrap --namespace argocd
}


if [ $DIR_BOOTSTRAP ] && [ -d $DIR_DEPLOYMENTS ]; then
	echo "Running the bootstrap into $PWD..."
	echo "Directory deployments is set correctly..."
else
	echo "Make sure to execute the bootstrap.sh into the correct directory and that the folder deployments is set correctly"
	exit 1
fi

if [ $# -eq 0 ]; then
  echo "Path to values file is missing. Try:"
  echo "./bootstrap.sh ../deployments/infra/cluster/temporary_argo_bootstrap_values.yaml"
else
    _helm_function
fi