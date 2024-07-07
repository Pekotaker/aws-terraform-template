module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  azs                   = var.availability_zones
  private_subnets       = var.private_subnets
  public_subnets        = var.public_subnets
  database_subnets      = var.database_subnets
  private_subnet_names  = var.private_subnet_names
  public_subnet_names   = var.public_subnet_names
  database_subnet_names = var.rds_subnet_names

  create_database_subnet_route_table = true
  create_database_subnet_group       = true
  single_nat_gateway                 = true
  enable_nat_gateway                 = false
  enable_vpn_gateway                 = false
  enable_dns_hostnames               = true
  enable_dns_support                 = true
  enable_dhcp_options                = false
  tags = {
    Terraform = "true"
  }
}


module "public_sg" {
  source = "terraform-in-action/sg/aws"
  name   = "${var.project}-public-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port        = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
        ,{
     
    port   = 22
    cidr_blocks = ["0.0.0.0/0"]
    },
  ]
  egress_rules= [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  description = "Allow traffic from the world"
}

module "private_sg" {
  source = "terraform-in-action/sg/aws"
  name   = "${var.project}-private-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
       rule = "NFS"
      port            = 2049
      security_groups = [module.public_sg.security_group.id]
    }
    
  ]
   egress_rules= [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
       security_groups = [module.public_sg.security_group.id]
    }
  ]
  description = "Allow traffic from public SG to private SG"
}

module "efs_sg" {
  source = "terraform-in-action/sg/aws"
  name   = "${var.project}-private-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
       rule = "NFS"
      port            = 2049
      security_groups = [module.public_sg.security_group.id]
    },
    {
       rule = "NFS"
      port            = 2049
      security_groups = [module.private_sg.security_group.id]
    }
    
  ]
   egress_rules= [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
       security_groups = [module.public_sg.security_group.id]
    },
     {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
       security_groups = [module.private_sg.security_group.id]
    }
  ]
  description = "Allow traffic from efs SG to private SG"
}

module "db_sg" {
  source = "terraform-in-action/sg/aws"
  name   = "${var.project}-db-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port            = 5432
       security_groups = [module.public_sg.security_group.id]
    }
  ]
   egress_rules= [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
       security_groups = [module.public_sg.security_group.id]
    }
  ]
  description = "Allow traffic from public SG to DB"
}

# module "bastion_sg" {
#   source = "terraform-in-action/sg/aws"
#   name   = "${var.project}-private-sg"
#   vpc_id = module.vpc.vpc_id
#   ingress_rules = [
#     {
#        rule = "NFS"
#       port            = 2049
#       security_groups = [module.public_sg.security_group.id]
#     }
#     ,{
#       description = "SSH from VPC"
# from_port   = 22
# to_port     = 22
# protocol    = "tcp"
# cidr_blocks = ["0.0.0.0/0"]
#     },
#       {
#       port        = 80
#       cidr_blocks = ["0.0.0.0/0"]
#     },
#     {
#       port        = 443
#       cidr_blocks = ["0.0.0.0/0"]
#     }
    
#   ]
#   description = "Allow traffic from public SG to bastion host"
# }