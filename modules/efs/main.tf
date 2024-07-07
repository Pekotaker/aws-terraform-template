  resource "aws_efs_file_system" "efs" {
    creation_token           = var.efs_name
    throughput_mode = "elastic"
    # availability_zone_name=  var.azs
    lifecycle_policy  {
      transition_to_ia = "AFTER_14_DAYS"
    }
    lifecycle_policy  {
      transition_to_archive =  "AFTER_30_DAYS"
    }

  tags = {
    Terraform   = "true"
   
  }
}
resource "aws_efs_backup_policy" "policy" {
  depends_on = [ aws_efs_file_system.efs ]
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}

