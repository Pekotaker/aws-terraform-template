output "output" {
  value = module.vpc
}

output "sg" {
  value = {
    public  = module.public_sg.security_group.id
    private = module.private_sg.security_group.id
    efs = module.efs_sg.security_group.id
    db      = module.db_sg.security_group.id
    # bastion = module.bastion_sg.security_group.id
  }
}
