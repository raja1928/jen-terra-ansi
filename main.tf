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

# Fetch the existing IAM role (if it exists)
data "aws_iam_role" "existing_role" {
  name = "eks-cluster-role"  # Name of the IAM role you want to check
}

# Create the IAM role only if it doesn't exist
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

# Reference the IAM role safely
resource "aws_eks_cluster" "example" {
  name     = var.cluster_name

  # Safe reference to either the existing or newly created role
  role_arn = length(data.aws_iam_role.existing_role.id) > 0 ? data.aws_iam_role.existing_role.arn : aws_iam_role.eks_cluster_role[0].arn

  # Correct placement of the vpc_config block
  vpc_config {
    subnet_ids         = aws_subnet.eks_subnets[*].id  # Reference the subnets created earlier
    security_group_ids = [aws_security_group.eks_sg.id]  # Reference the security group created earlier
  }
}

resource "aws_security_group" "eks_sg" {
  name        = "eks_security_group"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  # Use safe lookup for the role
  role       = length(data.aws_iam_role.existing_role.id) > 0 ? data.aws_iam_role.existing_role.name : aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_policy" {
  # Use safe lookup for the role
  role       = length(data.aws_iam_role.existing_role.id) > 0 ? data.aws_iam_role.existing_role.name : aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  # Use safe lookup for the role
  role       = length(data.aws_iam_role.existing_role.id) > 0 ? data.aws_iam_role.existing_role.name : aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

output "cluster_endpoint" {
  value = aws_eks_cluster.example.endpoint
}

output "cluster_id" {
  value = aws_eks_cluster.example.id
}
