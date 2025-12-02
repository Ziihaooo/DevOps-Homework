output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Public ALB DNS URL"
}

output "ecs_cluster_name" {
  value       = module.ecs.ecs_cluster_name
  description = "ECS Cluster Name"
}

output "ecs_service_name" {
  value       = module.ecs.ecs_service_name
  description = "ECS Service Name"
}

output "task_definition_arn" {
  value       = module.ecs.task_definition_arn
  description = "ECS Task Definition ARN"
}
