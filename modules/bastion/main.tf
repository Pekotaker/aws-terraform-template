data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical Ubuntu AWS account id
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion-key" {
  key_name   = "${var.project}-bastion-key"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "local_sensitive_file" "ec2-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "${path.root}/${aws_key_pair.bastion-key.key_name}.pem"
}

resource "aws_iam_instance_profile" "bastion_ec2_profile" {
  name = "bastion_ec2_profile"
  role = aws_iam_role.role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.project}-bastion-ec2InstanceRole"
  path               = "/ec2/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_instance" "bastion" {
  depends_on = [aws_key_pair.bastion-key]
  #   name = "${var.project}-bastion-do-not-delete"

  instance_type = var.instance_type
  ami           = data.aws_ami.ubuntu.id
  key_name      = aws_key_pair.bastion-key.key_name
  # IAM role & instance profile
  iam_instance_profile        = aws_iam_instance_profile.bastion_ec2_profile.name
  monitoring                  = true
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = var.subnet_id
  user_data                   = base64encode(file("${path.module}/user_data.sh"))
  associate_public_ip_address = true
  tags = {
    Terraform = "true"
  }
}


####################################################
# Generate script for mounting EFS
####################################################
resource "null_resource" "generate_efs_mount_script" {
  depends_on = [aws_instance.bastion]
  provisioner "local-exec" {
    working_dir = path.module
    command = templatefile("${path.module}/efs_mount.tpl", {
      efs_mount_point = var.efs_mount_point
      file_system_id  = var.efs_id
      efs_dns_name    = var.efs_dns_name
    })
    interpreter = [
      "/bin/bash",
      "-c"
    ]
  }
}

####################################################
# Execute scripts on existing running EC2 instances
####################################################

resource "null_resource" "execute_script" {
  depends_on = [aws_instance.bastion, null_resource.generate_efs_mount_script]
  #   count = 2

  #   # Changes to any instance of the cluster requires re-provisioning
  #   triggers = {
  #     instance_id = module.web.instance_ids[count.index]
  #   }

  provisioner "file" {
    source      = "${path.module}/efs_mount.sh"
    destination = "efs_mount.sh"
  }

  connection {
    type        = "ssh"
    user        = var.instance_user
    private_key = tls_private_key.rsa.private_key_pem
    host        = aws_instance.bastion.public_ip
  }

  provisioner "remote-exec" {
    # Bootstrap script called for each node in the cluster
    inline = [

      "sudo bash efs_mount.sh",
    ]
  }
}

####################################################
# Cleanup existing script
####################################################
resource "null_resource" "clean_up" {
  depends_on = [null_resource.execute_script]
  provisioner "local-exec" {
    when    = destroy
    command = "sudo rm -rf ${path.module}/efs_mount.sh"

    interpreter = [
      "/bin/bash",
      "-c"
    ]
  }
}

