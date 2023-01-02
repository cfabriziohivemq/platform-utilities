# Platform-utilities #

*_eks-helper.sh_*

This helper will facilitate the creation of an EKS cluster, be aware that the kubeconfig will be updated automatically at completion.

* Help menu

```shell
 Usage: sh eks-helper.sh [flag] [region] 

 -h, --help    Help info 
 -c, --create  Create a new cluster 
 -d, --delete  Delete Cluster 
```

* Creating

when creating a new cluster only two parameters are needed name of the cluster and region, example 

`sh eks-helper.sh -c my-first-cluster01 eu-west-1`

In this example a cluster with name `my-first-cluster01` will be created in Ireland `eu-west-1`.

* Deleting 

same sintax different flag 

`sh eks-helper.sh -d my-first-cluster01 eu-west-1`



*_bootstrap.sh_*

Use this script to bootstrap an argocd deployment to a new pegasus deployment. See [the cluster setup guide](../../docs/cluster-setup.md) for more info
