terraform {
  required_version = ">= 0.12.0"
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token = data.aws_eks_cluster_auth.cluster.token
  load_config_file = false
  version = "~> 1.10"
}


//locals {
//  cluster_name = "${var.prefix}-${random_string.suffix.result}"
//}

resource "random_string" "suffix" {
  length = 8
  special = false
}

//resource "aws_security_group" "worker_group_mgmt_one" {
//  name_prefix = "worker_group_mgmt_one"
//  vpc_id = module.vpc.vpc_id
//
//  ingress {
//    from_port = 22
//    to_port = 22
//    protocol = "tcp"
//
//    cidr_blocks = [
//      "10.0.0.0/8",
//    ]
//  }
//}
//
//resource "aws_security_group" "worker_group_mgmt_two" {
//  name_prefix = "worker_group_mgmt_two"
//  vpc_id = module.vpc.vpc_id
//
//  ingress {
//    from_port = 22
//    to_port = 22
//    protocol = "tcp"
//
//    cidr_blocks = [
//      "192.168.0.0/16",
//    ]
//  }
//}
//
resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_nfs" {
  name_prefix = "all_worker_nfs"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"]
  public_subnets = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.prefix}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.prefix}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.prefix}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "8.1.0"
  cluster_name = var.prefix
  subnets = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id

  tags = {
    Environment = var.environment
    //    GithubRepo = "terraform-aws-eks"
    //    GithubOrg = "terraform-aws-modules"
  }


  worker_groups = [
    {
      name = "standard-workers"
      instance_type = "m5.large"
      asg_desired_capacity = "1"
      asg_max_size = "3"
      asg_min_size = "1"
    },
  ]

  worker_additional_security_group_ids = [
    aws_security_group.all_worker_mgmt.id,
    aws_security_group.all_worker_nfs.id
  ]
  // I don't think I need any of this
  //  map_roles = var.map_roles
  //  map_users = var.map_users
  //  map_accounts = var.map_accounts
}

resource "kubernetes_secret" "main" {
  metadata {
    name = "${var.prefix}-cert"
    //    namespace = var.namespace
    //    labels    = merge({}, var.labels)
  }

  data = {
    nasqar-cert = data.aws_eks_cluster.cluster.certificate_authority.0.data
  }

  type = "Opaque"
}

resource "aws_efs_file_system" "nasqar" {
  creation_token = "nasqar"

  tags = {
    Name = "Nasqar"
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "main" {
  count = length(module.vpc.public_subnets)
  file_system_id = aws_efs_file_system.nasqar.id
  subnet_id = module.vpc.public_subnets[count.index]
  security_groups = [
    aws_security_group.all_worker_nfs.id
  ]
}

resource "null_resource" "kubectl_update" {
  depends_on = [
    module.eks,
    kubernetes_secret.main,
    aws_efs_file_system.nasqar,
    aws_efs_mount_target.main
  ]
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws eks --region $AWS_REGION update-kubeconfig --name $NAME"
    environment = {
      AWS_REGION = data.aws_region.current.id
      NAME = var.prefix
    }
  }
}

resource "null_resource" "nasqar_dependency_update" {
  depends_on = [
    module.eks,
    null_resource.kubectl_update,
    kubernetes_secret.main,
    aws_efs_file_system.nasqar,
    aws_efs_mount_target.main
  ]

  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "helm dep up nasqar"
  }
}

// TODO This is the proper way to do this
// We should use the helm resource
// But it doesn't work with a local chart
//resource "helm_release" "efs_provisioner" {
//  depends_on = [
//    null_resource.nasqar_dependency_update
//  ]
//
//  name = "efs-provisioner"
//  chart = " stable/efs-provisioner"
//  force_update = true
//
//  set {
//    name = "efsProvisioner.efsFileSystemId"
//    value = aws_efs_file_system.nasqar.id
//  }
//
//  set {
//    name = "efsProvisioner.path"
//    value = "/"
//  }
//
//  set {
//    name = "efsProvisioner.awsRegion"
//    value = data.aws_region.current.id
//  }
//
//  set {
//    name = "efsProvisioner.dnsName"
//    value = aws_efs_file_system.nasqar.dns_name
//  }
//}
//

resource "null_resource" "nasqar_upgrade" {
  depends_on = [
    null_resource.kubectl_update,
    null_resource.nasqar_dependency_update,
  ]

  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "helm upgrade --install nasqar nasqar  --set image.tag=$CIRCLE_SHA1 --set efsProvisioner.efsFileSystemId=$ID --set efsProvisioner.path=/ --set efsProvisioner.awsRegion=$REGION --set efsProvisioner.dnsName=$DNSNAME"
    environment = {
      ID = aws_efs_file_system.nasqar.id
      REGION = data.aws_region.current.id
      DNSNAME = aws_efs_file_system.nasqar.dns_name
    }
    //      name = "efsProvisioner.efsFileSystemId"
    //      value = aws_efs_file_system.nasqar.id
    //      name = "efsProvisioner.path"
    //      value = "/"
    //      name = "efsProvisioner.awsRegion"
    //      value = data.aws_region.current.id
    //      name = "efsProvisioner.dnsName"
    //      value = aws_efs_file_system.nasqar.dns_name
  }
}

