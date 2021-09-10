#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

resource "aws_iam_role" "k8s-cluster-node" {
  name = "${var.env}-eks-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8s-cluster-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.k8s-cluster-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.k8s-cluster-node.name
}

resource "aws_iam_instance_profile" "k8s-cluster-node" {
  name = "terraform-eks-k8s-cluster"
  role = aws_iam_role.k8s-cluster-node.name
}

resource "aws_security_group" "k8s-cluster-node" {
  name        = "terraform-eks-k8s-cluster-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = tomap({
     "Name": "${var.env}-eks-node-sg",
     "kubernetes.io/cluster/${var.env}-eks-cluster": "owned",
    })
}

resource "aws_security_group_rule" "k8s-cluster-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.k8s-cluster-node.id
  source_security_group_id = aws_security_group.k8s-cluster-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "k8s-cluster-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s-cluster-node.id
  source_security_group_id = aws_security_group.k8s-cluster-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.k8s-cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

locals {
  k8s-cluster-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.k8s-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.k8s-cluster.certificate_authority.0.data}' '${var.env}-eks-cluster'
USERDATA
}

resource "aws_launch_configuration" "k8s-cluster" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k8s-cluster-node.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "t2.xlarge"
  name_prefix                 = "terraform-eks-k8s-cluster"
  # key_name                    = "eksnodes"
  security_groups             = [aws_security_group.k8s-cluster-node.id]
  user_data_base64            = base64encode(local.k8s-cluster-node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "k8s-cluster" {
  desired_capacity     = "${var.cluster_desired_nodes}"
  launch_configuration = aws_launch_configuration.k8s-cluster.id
  max_size             = "${var.cluster_max_nodes}"
  min_size             = 1
  health_check_type    = "ELB"
  health_check_grace_period = 60
  force_delete              = true
  name                 = "${var.env}-eks-cluster-asg"
  vpc_zone_identifier  = [var.subnet_1 , var.subnet_2]
  tag {
    key                 = "Name"
    value               = "${var.env}-eks-cluster-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.env}-eks-cluster"
    value               = "owned"
    propagate_at_launch = true
  }
}
