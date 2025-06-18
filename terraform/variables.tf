variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "streamsource"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "db_size" {
  description = "Database droplet size"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "redis_size" {
  description = "Redis droplet size"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "app_instance_count" {
  description = "Number of app instances"
  type        = number
  default     = 1
}

variable "app_instance_size" {
  description = "App instance size"
  type        = string
  default     = "basic-xxs"
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

variable "secret_key_base" {
  description = "Rails secret key base"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for API authentication"
  type        = string
  sensitive   = true
}

variable "rails_master_key" {
  description = "Rails master key for credentials"
  type        = string
  sensitive   = true
}

variable "rails_max_threads" {
  description = "Maximum threads for Rails/Puma"
  type        = string
  default     = "5"
}

variable "web_concurrency" {
  description = "Number of Puma workers"
  type        = string
  default     = "2"
}

variable "app_domain" {
  description = "Custom domain for the application (optional)"
  type        = string
  default     = ""
}

variable "use_droplets" {
  description = "Use Droplets instead of App Platform"
  type        = bool
  default     = false
}

variable "droplet_size" {
  description = "Droplet size for app servers"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "droplet_image" {
  description = "Droplet image"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "ssh_key_fingerprints" {
  description = "SSH key fingerprints for droplet access"
  type        = list(string)
  default     = []
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for Ansible"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "run_ansible" {
  description = "Run Ansible playbook after creating infrastructure"
  type        = bool
  default     = true
}