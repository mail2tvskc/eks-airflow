## EBS CSI Driver

The airflow chart provided is configured to use EBS CSI driver for worker's volume. You can install it following these [steps](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html). Here are provided for you: 

Notice that the name for the cluster in this case is **sandbox-eks-cluster**. 

```bash
curl -o example-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v1.0.0/docs/example-iam-policy.json
aws iam create-policy \
    --policy-name AmazonEKS_EBS_CSI_Driver_Policy \
    --policy-document file://example-iam-policy.json

export CLUSTER_OIDC=$(aws eks describe-cluster \
    --name sandbox-eks-cluster \
    --query "cluster.identity.oidc.issuer" \
    --output text)
    echo $CLUSTER_OIDC
```

Create file **'trust-policy.json'**, with the following content, changing the values:      
 **{ACCOUNT\_ID}** with the account id shown in the website (Account Settings -> Account Id)        
 **{REGION}** with the corresponding choosen region for your cluster (execute kubectl cluster-info if you don't know)       
 **{CLUSTER\_OIDC}** with the corresponding value for your cluster in the variable CLUSTER_OIDC exported in the line before     
         
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

Create Role and Policy and attach it to the cluster's node role:  

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

> **⚠ WARNING: maybe you already have named roles or policies with the provided names, in that case use other names, and make sure that you change then other steps, in order to attack correctly the role and policy.** 

**Delete role and policy**
If you want to delete the role and policies execute the following:      

  ```bash 
     aws iam detach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole --policy-arn arn:aws-cn:iam::${ACCOUNT_ID}:policy/AmazonEKS_EFS_CSI_Driver_Policy 
     aws iam delete-role  --role-name AmazonEKS_EBS_CSI_DriverRole 
  ```
