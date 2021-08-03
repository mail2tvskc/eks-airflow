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

### EBS CSI        
The airflow chart provided is configured to use EBS CSI driver for worker's volume. You can install it following these [steps](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html). Here are provided for you: 

Notice that the name for the cluster in this case is "sandbox-eks-cluster". 

```bash
curl -o example-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v1.0.0/docs/example-iam-policy.json
aws iam create-policy \
    --policy-name AmazonEKS_EBS_CSI_Driver_Policy \
    --policy-document file://example-iam-policy.json

export CLUSTER_OIDC=$(aws eks describe-cluster \
    --name sandbox-eks-cluster \
    --query "cluster.identity.oidc.issuer" \
    --output text)
```

Create file 'trust-policy.json', changing the values:      
- {ACCOUNT\_ID} with the account id shown in the website (Account Settings -> Account Id)        
- {REGION} with the corresponding choosen region for your cluster (execute kubectl cluster-info if you don't know)       
- {CLUSTER\_OIDC} with the corresponding value for your cluster in the variable CLUSTER_OIDC exported in the line before     
         
```json
	{
	  "Version": "2012-10-17",
	  "Statement": [
	    {
	      "Effect": "Allow",
	      "Principal": {
	        "Federated": "arn:aws:iam::{ACCOUNT_ID}:oidc-provider/oidc.eks.{REGION}.amazonaws.com/id/{CLUSTER_OIDC}"
	      },
	      "Action": "sts:AssumeRoleWithWebIdentity",
	      "Condition": {
	        "StringEquals": {
	          "oidc.eks.{REGION}.amazonaws.com/id/{CLUSTER_OIDC}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
	        }
	      }
	    }
	  ]
	}
```

```bash 
aws iam create-role \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --assume-role-policy-document file://"trust-policy.json"

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonEKS_EBS_CSI_Driver_Policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole

aws iam attach-role-policy --policy-arn arn:aws-cn:iam::$ACCOUNT_ID:policy/AmazonEKS_EBS_CSI_Driver_Policy --role-name sandbox-eks-node-role


helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm upgrade -install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
--namespace kube-system \
--set image.repository=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-ebs-csi-driver \
--set enableVolumeResizing=true \
--set enableVolumeSnapshot=true \
--set serviceAccount.controller.create=true \
--set serviceAccount.controller.name=ebs-csi-controller-sa
```

> **Observation** maybe you already have named roles or policies with the provided names, in that case use other names, and make sure that you change then other steps, in order to attack correctly the role and policy. 


## Cleanup   
> **⚠ WARNING: You will delete your cluster with this steps.**  

If you want to destroy the cluster execute:

1. Delete role and policy
If you want to delete the role and policies execute the following:      

	```bash 
	   aws iam detach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole --policy-arn arn:aws-cn:iam::${ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy 
	   aws iam delete-role  --role-name AmazonEKS_EBS_CSI_DriverRole 
	```

3. Destroy EKS cluster        

	```
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

