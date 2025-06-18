output "app_url" {
  description = "The default URL for the application"
  value       = var.use_droplets ? "http://${try(digitalocean_droplet.app[0].ipv4_address, "")}" : try(digitalocean_app.streamsource[0].default_ingress, "")
}

output "database_uri" {
  description = "PostgreSQL connection string"
  value       = digitalocean_database_cluster.postgres.uri
  sensitive   = true
}

output "redis_uri" {
  description = "Redis connection string"
  value       = digitalocean_database_cluster.redis.uri
  sensitive   = true
}

output "database_host" {
  description = "Database host for direct connections"
  value       = digitalocean_database_cluster.postgres.host
}

output "database_port" {
  description = "Database port"
  value       = digitalocean_database_cluster.postgres.port
}

output "redis_host" {
  description = "Redis host for direct connections"
  value       = digitalocean_database_cluster.redis.host
}

output "redis_port" {
  description = "Redis port"
  value       = digitalocean_database_cluster.redis.port
}

output "app_id" {
  description = "DigitalOcean App ID for deployments"
  value       = var.use_droplets ? "" : try(digitalocean_app.streamsource[0].id, "")
}

output "droplet_ips" {
  description = "IP addresses of droplets"
  value       = var.use_droplets ? digitalocean_droplet.app[*].ipv4_address : []
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = var.use_droplets ? "${path.module}/../ansible/inventory/hosts.yml" : ""
}