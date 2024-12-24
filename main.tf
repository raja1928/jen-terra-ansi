# Fetch the availability zones for the specified region
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "eks_subnets" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

data "aws_iam_role" "existing_role" {
  name = "eks-cluster-role"  # Name of the IAM role you want to check
}

resource "aws_iam_role" "eks_cluster_role" {
  count              = length(data.aws_iam_role.existing_role.id) == 0 ? 1 : 0  # Only create if the role doesn't exist
  name               = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_eks_cluster" "example" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[0].arn  # Reference the created role

  # Other configurations for EKS cluster...
}

resource "aws_security_group" "eks_sg" {
  name        = "eks_security_group"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role[0].name  # Attach policies to the role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_policy" {
  role       = aws_iam_role.eks_cluster_role[0].name  # Attach policies to the role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_VPC_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  role       = aws_iam_role.eks_cluster_role[0].name  # Attach policies to the role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

output "cluster_endpoint" {
  value = aws_eks_cluster.example.endpoint
}

output "cluster_id" {
  value = aws_eks_cluster.example.id
}
