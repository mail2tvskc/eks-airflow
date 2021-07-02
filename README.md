# EKS Deployment

This repo provides Terraform templates for deploying a Kubernetes cluster against AWS using EKS

## Requirements

* Terraform
* AWS CLI
* Kubectl

## Usage

* Make sure environment variables `AWS_PROFILE` and `AWS_DEFAULT_REGION` point to the corresponding AWS credentials/region
```
  export AWS_PROFILE=sandbox 
  export AWS_DEFAULT_REGION=us-west-2
```

### with Terraform CLI

* Review `terraform/variables.tf` and adjust as needed
* provision VPC and cluster
```
	cd terraform
	terraform init
	terraform apply
```

* Authenticate to Cluster
```
aws eks update-kubeconfig --name sandbox-eks-cluster --region $AWS_DEFAULT_REGION
```
* Register nodes to cluster
```
	terraform output config_map_aws_auth > config_map_aws_auth.yml
	kubectl apply -f config_map_aws_auth.yml
```
* Validate by checking the created cluster nodes (might take a minute to show Ready status)
```
	kubectl get nodes
```
* Provide access to other IAM users/roles that require it (see https://aws.amazon.com/premiumsupport/knowledge-center/amazon-eks-cluster-access/)
```
	kubectl edit configmap aws-auth -n kube-system
```
(IAM users should authenticate to the cluster after this step is completed)

```
	aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name sandbox-eks-cluster
```


* NOTE: This template does not currently include an Ingress controller. One can be deployed, eg for Nginx, using
```
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml
```
(note this while deployed outside of Terraform needs to be manually deleted before removing the cluster)

* cleanup: If you want to destroy the cluster execute:    
```
	terraform destroy
```

### Airflow
See [airflow/README.md](airflow/README.md) for information about how to install airflow in this cluster. 


## References: 

* https://www.terraform.io/intro/index.html
* https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html

