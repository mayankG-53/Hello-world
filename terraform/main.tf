# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnets
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
    kubernetes.io/role/elb = 1
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
    kubernetes.io/role/elb = 1
  }
}

# Create private subnets
resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1"
    kubernetes.io/role/internal-elb = 1
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
    kubernetes.io/role/internal-elb = 1
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Allocate Elastic IP for NAT Gateway
resource "aws_eip" "nat_ip" {
  vpc = true
}

# Create the NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.subnet1.id  # Use a public subnet for the NAT Gateway
}

# Route Tables for Private Subnets (to route traffic to NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate the route table with private subnets
resource "aws_route_table_association" "private_subnet_rt_association_1" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_rt_association_2" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "eks_cluster_role_policy_attachment" {
  name       = "eks-cluster-role-policy-attachment"
  roles      = [aws_iam_role.eks_cluster_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "eks_node_group_policy_attachment" {
  name       = "eks-node-group-policy-attachment"
  roles      = [aws_iam_role.eks_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy_attachment" "eks_node_group_registry_policy" {
  name       = "eks-node-group-registry-policy-attachment"
  roles      = [aws_iam_role.eks_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy_attachment" "eks_node_group_cloudwatch_logs" {
  name       = "eks-node-group-cloudwatch-logs-policy-attachment"
  roles      = [aws_iam_role.eks_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_policy_attachment" "eks_node_group_cni_policy" {
  name       = "eks-node-group-cni-policy-attachment"
  roles      = [aws_iam_role.eks_node_group_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_eks_cluster" "main" {
  name     = "my-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.subnet1.id,
      aws_subnet.subnet2.id,
      aws_subnet.subnet3.id,
      aws_subnet.subnet4.id
    ]
    security_group_ids = [aws_security_group.eks_security_group.id]
  }
}
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [aws_subnet.subnet3.id, aws_subnet.subnet4.id]  # Private subnets
  instance_types  = ["t3.medium"]

  scaling_config {
    min_size     = 1
    max_size     = 3
    desired_size = 2
  }

  remote_access {
    ec2_ssh_key = "test123"  # Replace with your actual SSH key name
  }
}

resource "aws_security_group" "eks_security_group" {
  name        = "eks-security-group"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id 

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR block or specific ranges for internal communication
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow egress traffic to anywhere
  }
}

