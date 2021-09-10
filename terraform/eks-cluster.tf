# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "k8s-cluster-cluster" {
  name = "${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8s-cluster-cluster.name
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.k8s-cluster-cluster.name
}

resource "aws_security_group" "k8s-cluster-cluster" {
  name        = "${var.env}-eks-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-eks-cluster-sg"
  }
}

resource "aws_security_group_rule" "k8s-cluster-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s-cluster-cluster.id
  source_security_group_id = aws_security_group.k8s-cluster-node.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "k8s-cluster-cluster-ingress-workstation-https" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.k8s-cluster-cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "k8s-cluster" {
  name     = "${var.cluster_name}"
  role_arn = aws_iam_role.k8s-cluster-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.k8s-cluster-cluster.id]
    subnet_ids         = [var.subnet_1 , var.subnet_2 ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.k8s-cluster-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.k8s-cluster-cluster-AmazonEKSServicePolicy,
  ]
}
