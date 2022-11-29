_create_cluster_eks() {
eksctl create cluster \
  --name $NAME \
  --region $REGION \
  --version 1.24 \
  --without-nodegroup
}

_create_nodegroup_eks() {
  eksctl create nodegroup \
    --cluster $NAME \
    --region $REGION \
    --name node-$NAME \
    --node-type m5a.large \
    --nodes 3 \
    --nodes-min 3 \
    --nodes-max 3 \
    --node-private-networking
}

_get_cluster_kubeconfig() {
    cluster_name=$(aws eks list-clusters --region $REGION | jq -r -M ".clusters[]" | grep $NAME)
    echo "Cluster name is $cluster_name and is running in $REGION"
    sleep 2
    aws eks update-kubeconfig --name $cluster_name --region $REGION
}

_delete_resource() {
    cluster_name=$(aws eks list-clusters --region $REGION | jq -r -M ".clusters[]" | grep $NAME)
    echo "Deleting cluster $cluster_name "
    eksctl delete cluster -n $cluster_name -r $REGION
}

_show_help() {
    echo "\nHelp menu: \n" \
    "Usage: sh eks-helper.sh [flag] [region] \n\n" \
    "-h, --help    Help info \n" \
    "-c, --create  Create a new cluster \n" \
    "-d, --delete  Delete Cluster \n" \
    "Example: sh eks-helper.sh -c my-first-cluster01 eu-west-1 \n"
}

_process() {
    NAME=$2
    REGION=$3

    if [ $# -eq 0 ]
    then
        echo "Missing parameter"
        _show_help
        exit
    fi

    case "$1" in
    -h | --help)
        _show_help
        ;;
    -c | --create) echo "Creating cluster...."
        _create_cluster_eks
        echo "Configuring nodes...."
        _create_nodegroup_eks
        echo "Updateing kubeconfig..."
        _get_cluster_kubeconfig
        ;;
    -d | --delete) echo "Delete Cluster"
        _delete_resource
        ;;
    *) echo "Invalid option"
        _show_help
        ;;
    esac
}

_process "$@"