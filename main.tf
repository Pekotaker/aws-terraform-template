
data "aws_availability_zones" "available" {}
locals {
  project          = "hello-world-project"
  region           = "ap-southeast-1"
  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  primary_az       = local.azs[0]
  aws_profile      = "my-profile"
  backend_port     = 8000
  ecs_cluster_name = "${local.project}-ecs-cluster"
  efs_mount_point           = "/mnt/efs/shared-logs"
}

provider "aws" {
  region  = local.region
  profile = local.aws_profile
}

module "vpc" {
  source               = "./modules/vpc"
  project              = local.project
  availability_zones   = local.azs
  private_subnet_names = ["${local.project}-private-az1", "${local.project}-private-az2","${local.project}-efs-az1", "${local.project}-efs-az2"]
  public_subnet_names  = ["${local.project}-public-az1", "${local.project}-public-az2"]
  rds_subnet_names     = ["${local.project}-rds-az1", "${local.project}-rds-az2"]
}

module "efs" {
  source     = "./modules/efs"
  depends_on = [module.vpc]
  efs_name   = "${local.project}-shared-efs"
}

# Creating Mount target of EFS
resource "aws_efs_mount_target" "mount-private" {
  depends_on      = [ aws_efs_file_system.efs]
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = module.vpc.output.private_subnets[0]
  security_groups = [module.vpc.sg.efs]
}


module "bastion" {
  source                    = "./modules/bastion"
  depends_on                = [module.efs]
  project                   = local.project
  instance_type             = "t2.micro"
  instance_user             = "ubuntu"
  vpc_security_group_ids    = ["${module.vpc.sg.public}"]
  subnet_id                 = module.vpc.output.public_subnets[0]
  private_security_group_id = module.vpc.sg.private
  efs_id                    = module.efs.output.id
  efs_dns_name              = module.efs.output.dns_name
  efs_mount_point           = local.efs_mount_point
}

module "autoscaling" {
  source                    = "./modules/asg"
  project                   = local.project
  subnet_ids                = module.vpc.output.private_subnets
  security_groups           = ["${module.vpc.sg.private}"]
  backend_port              = local.backend_port
  vpc_id                    = module.vpc.output.vpc_id
  alb_name_prefix           = "alb-" # Cannot be longer than 6 characters
  target_groups_name_prefix = "ec2-" # Cannot be longer than 6 characters
  ecs_cluster_name=local.ecs_cluster_name
  efs_id                    = module.efs.output.id
  efs_dns_name              = module.efs.output.dns_name
  efs_mount_point           = local.efs_mount_point
}

module "s3" {
  source = "./modules/s3"

  private_bucket_prefix_name = "${local.project}-private"
  public_bucket_prefix_name  = "${local.project}-public"
}
module "rds_postgres" {
  source                 = "./modules/database"
  depends_on             = [module.vpc]
  identifier             = "${local.project}-rds"
  instance_class         = "db.t3.micro"
  db_name                = "mypostgres"
  username               = "mydbadmin" # Sensitive value need to be hidden
  password               = "mydbpassword123" # Sensitive value need to be hidden
  allocated_storage      = 20
  availability_zone      = local.primary_az
  db_subnet_group_name   = module.vpc.output.database_subnet_group_name
  vpc_security_group_ids = ["${module.vpc.sg.db}"]
  subnet_ids             = module.vpc.output.database_subnets
}

module "ecr" {
  source              = "./modules/ecr"
  ecr_repository_name = local.project
}

module "ecs" {
  source              = "./modules/ecs"
  depends_on = [ module.ecr ]
  ecr_repository_name = local.project
  ecs_cluster_name=local.ecs_cluster_name 
}