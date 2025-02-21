module "vpc" {
  # source = "../vpc"
  source = "./modules/vpc"
  project_name = var.project_name
  environment = var.environment
  common_tags = var.common_tags
  vpc_tags = var.vpc_tags
  cidr_public = var.cidr_public
  cidr_private = var.cidr_private
  is_peering_required = var.is_peering_required
  acceptor_vpc_id = var.accepters_vpc_id
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups     = var.node_groups
}