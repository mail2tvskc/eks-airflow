# EKS Deployment

This repo provides Terraform templates for deploying a Kubernetes cluster against AWS using EKS

# Requirements

* Terraform
* AWS CLI
* Kubectl

# Usage with Terraform CLI

Make sure environment variables `AWS_PROFILE` and `AWS_DEFAULT_REGION` point to the corresponding AWS credentials/region

```bash
  export AWS_PROFILE=sandbox 
  export AWS_DEFAULT_REGION=us-west-2
```

1. Review [terraform/variables.tf](terraform/variables.tf) and adjust as needed    
2. Provision VPC and cluster

	```bash
		cd terraform
		terraform init
		terraform apply
	```            
 
3. Authenticate to Cluster        
	```
	aws eks update-kubeconfig --name sandbox-eks-cluster --region $AWS_DEFAULT_REGION
	```
4. Register nodes to the cluster

	```bash
		terraform output config_map_aws_auth > config_map_aws_auth.yml
		kubectl apply -f config_map_aws_auth.yml
	```

5. Validate by checking the created cluster nodes (it might take a minute to show 'Ready' status)

	```
		kubectl get nodes
	```

6. Provide access to other IAM users/roles that require it (see https://aws.amazon.com/premiumsupport/knowledge-center/amazon-eks-cluster-access/)
	
	```
		kubectl edit configmap aws-auth -n kube-system
	```
	(IAM users should authenticate to the cluster after this step is completed)

	```
		aws eks --region $AWS_DEFAULT_REGION update-kubeconfig --name sandbox-eks-cluster
	```

## Note       
This template does not currently include an Ingress controller. One can be deployed, eg for Nginx, using

```bash
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml
```
```bash 
	kubectl get all -n ingress-nginx 
```
Notice that this is deployed outside of Terraform, so it needs to be manually deleted before removing the cluster.


## Cleanup   
> **⚠ WARNING: You will delete your cluster with this steps.**  

If you want to destroy the cluster execute:       

```bash
	terraform destroy
	
```

# Airflow
See [airflow/README.md](airflow/README.md) for information about how to install airflow in this cluster. 


# Turn off EKS cluster
> **⚠ WARNING: Your cluster will be turned off if you follow this steps.**  

If you want to turn off the instances go to Amazon's web console -> EC2 -> Autoscaling group and edit the configuration, setting up **0** instances for 'Desired capacity' and 'Minimum capacity' fields.     



# References: 

* [https://www.terraform.io/intro/index.html](https://www.terraform.io/intro/index.html)
* [https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
* [https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-subnets.html](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-subnets.html)
* [https://aws.amazon.com/premiumsupport/knowledge-center/eks-persistent-storage/](https://aws.amazon.com/premiumsupport/knowledge-center/eks-persistent-storage/)

