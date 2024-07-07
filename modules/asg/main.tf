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

resource "aws_key_pair" "asg-key" {
  key_name   = "${var.project}-asg-key"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "local_sensitive_file" "asg-ec2-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "${path.root}/${aws_key_pair.asg-key.key_name}.pem"
}

####################################################
# Generate script for user_data include EFS mount #
####################################################
resource "null_resource" "generate_user_data_script" {
  provisioner "local-exec" {
    working_dir = path.module
    command = templatefile("${path.module}/user_data.tpl", {
      ecs_cluster_name = var.ecs_cluster_name
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
# Cleanup existing script
####################################################
resource "null_resource" "clean_up" {
  depends_on = [null_resource.generate_user_data_script]
  provisioner "local-exec" {
    when    = destroy
    command = "sudo rm -rf ${path.module}/user_data.sh"

    interpreter = [
      "/bin/bash",
      "-c"
    ]
  }
}

module "asg" {
  source     = "terraform-aws-modules/autoscaling/aws"
  depends_on = [module.alb, null_resource.generate_user_data_script]
  # Target group
  target_group_arns = [module.alb.target_groups["be-instance"].arn]

  # Autoscaling group
  name = "${var.project}-asg"

  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  default_instance_warmup   = 300
  health_check_type   = "ELB"
  vpc_zone_identifier = var.subnet_ids

  #   initial_lifecycle_hooks = [
  #     {
  #       name                  = "ExampleStartupLifeCycleHook"
  #       default_result        = "CONTINUE"
  #       heartbeat_timeout     = 60
  #       lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
  #       notification_metadata = jsonencode({ "hello" = "world" })
  #     },
  #     {
  #       name                  = "ExampleTerminationLifeCycleHook"
  #       default_result        = "CONTINUE"
  #       heartbeat_timeout     = 180
  #       lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
  #       notification_metadata = jsonencode({ "goodbye" = "world" })
  #     }
  #   ]

  # instance_refresh = {
  #   strategy = "Rolling"
  #   preferences = {
  #     checkpoint_delay       = 600
  #     checkpoint_percentages = [35, 70, 100]
  #     instance_warmup        = 300
  #     min_healthy_percentage = 50
  #     max_healthy_percentage = 100
  #   }
  #   triggers = ["tag"]
  # }

  # instance_maintenance_policy = {
  #   min_healthy_percentage = 100
  #   max_healthy_percentage = 110
  # }


  # Launch template
  launch_template_name        = "${var.project}-lt"
  launch_template_description = "Launch template for ${var.project} back-end"
  launch_template_version     = "$Latest"
  user_data                   = base64encode(file("${path.module}/user_data.sh"))
  update_default_version      = true

  image_id          = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  ebs_optimized     = false
  enable_monitoring = false
  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "${var.project}-ec2InstanceRole"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role allows EC2 instances to call AWS services on your behalf."
  key_name                    = aws_key_pair.asg-key.key_name
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonDynamoDBFullAccess            = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonEC2RoleforSSM                 = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    AmazonSSMPatchAssociation           = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
  }

  block_device_mappings = [
    {
      device_name = "/dev/sda1"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 12
        volume_type           = "gp2"
      }
    },
    # {
    #   # Root volume
    #   device_name = "/dev/xvda"
    #   no_device   = 0
    #   ebs = {
    #     delete_on_termination = true
    #     encrypted             = true
    #     volume_size           = 12
    #     volume_type           = "gp2"
    #   }
    # }
  ]

  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  #   metadata_options = {
  #     http_endpoint               = "enabled"
  #     http_tokens                 = "required"
  #     http_put_response_hop_limit = 1
  #   }

  network_interfaces = [
    {
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0
      security_groups             = var.security_groups
      associate_public_ip_address = true
    },
  ]

  tags = {
    Terraform = "true"
  }
}


module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name_prefix                = var.alb_name_prefix
  vpc_id                     = var.vpc_id
  subnets                    = var.subnet_ids # A list of subnet IDs to attach to the LB
  enable_deletion_protection = false
  # Security Group
  create_security_group = false
  security_groups       = var.security_groups # A list of security group IDs to assign to the LB

  listeners = {
    # http-https-redirect = {
    #   port     = 80
    #   protocol = "HTTP"
    #   redirect = {
    #     port        = "443"
    #     protocol    = "HTTPS"
    #     status_code = "HTTP_301"
    #   }
    # }
    # on-https = {
    #   port            = 443
    #   protocol        = "HTTPS"
    #   certificate_arn = ""

    #   forward = {
    #     target_group_key = "ex-instance"
    #   }
    # }

    on-http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "be-instance"
      }
    }
  }

  target_groups = {
    be-instance = {
      name_prefix = var.target_groups_name_prefix
      protocol    = "HTTP"

      target_type          = "instance"
      deregistration_delay = 10

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
      }

      protocol_version = "HTTP1"

      port   = var.backend_port
      vpc_id = var.vpc_id
      create_attachment = false

      tags = {
        InstanceTargetGroupTag = "baz"
      }
    }
  }

  tags = {
    Terraform = "true"
  }
}
