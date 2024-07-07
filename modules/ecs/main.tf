resource "aws_ecs_cluster" "default" {
  name = var.ecs_cluster_name

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform = "true"
  }
}

module "ecs" {
  source              = "./modules/ecs"
  depends_on          = [module.autoscaling]
  project             = local.project
  region              = local.region
  ecr_repository_name = var.ecr_repository_name
  cluster_name        = local.ecs_cluster_name
  service_name        = "${local.project}-svc"
  ecr_image_arn       = "stephenitus/fast-api-hello-world:latest"
  container_name      = "${local.project}-ecs-container"
  container_port      = local.backend_port
  # cpu_units                                   = 1024
  # memory                                      = 1024
  ecs_task_desired_count                      = 1
  ecs_task_deployment_minimum_healthy_percent = 50
  ecs_task_deployment_maximum_percent         = 100
  asg_arn                                     = module.autoscaling.output.asg.autoscaling_group_arn
  asg_name                                     = module.autoscaling.output.asg.autoscaling_group_name
}
