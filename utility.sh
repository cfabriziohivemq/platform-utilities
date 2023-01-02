_workspace_creation() {
    if [[ -d ./deployment_templates ]]; then
        echo "Workspace template available......"
        mv ./deployment_templates ./deployments
    else
        echo "Workspace template NOT available...creating workspace...."
        mkdir -p ./deployments
    fi

    echo "Creating $CLUSTER_NAME workspace"
    if [[ -d ./deployments/aws/account-setup-$CLUSTER_NAME-$ENV-$REGION && -d ./deployments/aws/$CLUSTER_NAME-$ENV-$REGION ]]; then
        echo "..."
    else
        mv ./deployments/aws/new-account-setup ./deployments/aws/account-setup-$CLUSTER_NAME-$ENV-$REGION 2>/dev/null
        mv ./deployments/aws/new-cluster ./deployments/aws/$CLUSTER_NAME-$ENV-$REGION 2>/dev/null
    fi
}

_terraform_account() {
    DIR="./deployments/aws/account-setup-$CLUSTER_NAME-$ENV-$REGION"

    if [[ $( aws s3 ls | grep $S3_NAME) ]]; then
        echo "S3 bucket already created..."
    else
        echo "Creating S3 bucket..."
        cd $DIR
        terraform init
        echo "Applying....."
        terraform apply -auto-approve
        echo "Making the lock file compatible with all platforms..."
        terraform providers lock -platform=linux_arm64 -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64 -platform=windows_amd64
        terraform init -force-copy
    fi
}

_terraform_core() {
    DIR="./deployments/aws/$CLUSTER_NAME-$ENV-$REGION/terraform/core"
    cd $DIR
    tfenv use 1.2.7
    terraform init \
    -backend-config="bucket=${TF_VAR_deployment_environment}-tfstate-pegasus" \
    -backend-config="dynamodb_table=${TF_VAR_deployment_environment}-tfstate-pegasus-lock" \
    -backend-config="region=${TF_VAR_aws_region}" \
    -backend-config="key=${TF_VAR_deployment_name}-${TF_VAR_deployment_environment}-${TF_VAR_aws_region}/core.tfstate"
    terraform apply -auto-approve
}

_terraform_cluster() {
    DIR="./deployments/aws/$CLUSTER_NAME-$ENV-$REGION/terraform/cluster"
    cd $DIR
    tfenv use 1.2.7
    terraform init \
    -backend-config="bucket=${TF_VAR_deployment_environment}-tfstate-pegasus" \
    -backend-config="dynamodb_table=${TF_VAR_deployment_environment}-tfstate-pegasus-lock" \
    -backend-config="region=${TF_VAR_aws_region}" \
    -backend-config="key=${TF_VAR_deployment_name}-${TF_VAR_deployment_environment}-${TF_VAR_aws_region}/cluster.tfstate"
    terraform apply -auto-approve
    sleep 3

    if [[ $(terraform state list | grep module.this.local_file.editable) ]]; then
        terraform state rm $(terraform state list | grep module.this.local_file.editable)
    fi
}

_get_kubeconfig() {
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME-$ENV-cluster --kubeconfig ~/.kube/configs/$CLUSTER_NAME-$ENV-cluster.yaml
    sleep 3

    if ! command -v kubie &> /dev/null
    then
        echo "kubie could not be found configuring KUBECONFIG"
        export KUBECONFIG="~/.kube/configs/$CLUSTER_NAME-$ENV-cluster.yaml"
    else
        echo "Set the cluster configuration file"
        kubie ctx --kubeconfig ~/.kube/configs/$CLUSTER_NAME-$ENV-cluster.yaml
    fi

    kubectl get nodes -o wide
}


_process() {
 set -e
 
 CLUSTER_NAME=$1
 ENV=$2
 REGION="eu-west-2"
 S3_NAME="$ENV-tfstate-pegasus"
 DIRECTORY=$PWD
 BASE_DIRECTORY=$(realpath "${DIRECTORY}")
 export AWS_PROFILE="hmq-cloud-dev-shared-pegasus-admin"
 export AWS_DEFAULT_REGION=$REGION
 export TF_VAR_aws_account_id=$(aws sts get-caller-identity --output json | jq -r ".Account")
 export TF_VAR_aws_region=$REGION
 export TF_VAR_deployment_name=$CLUSTER_NAME
 export TF_VAR_deployment_environment=$ENV
 export TF_VAR_deployment_git_repo=$(gh repo view --json name -q ".name")
 export TF_VAR_deployment_git_branch="main"

 echo "Set Workspace...."
 _workspace_creation
 echo "Set AWS account on $AWS_PROFILE $AWS_DEFAULT_REGION..."
 sleep 5
 _terraform_account
 echo "Set AWS core dependencies on $AWS_PROFILE $AWS_DEFAULT_REGION..."
 sleep 5
 cd $BASE_DIRECTORY
 _terraform_core
 echo "Creating AWS EKS on $AWS_PROFILE $AWS_DEFAULT_REGION..."
 sleep 10
 cd $BASE_DIRECTORY
 _terraform_cluster
 echo "Pulling the kubeconfig..."
 _get_kubeconfig
}

_process "$@"