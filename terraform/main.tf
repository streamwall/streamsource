terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "digitalocean" {
  token = var.do_token
}

# Database
resource "digitalocean_database_cluster" "postgres" {
  name       = "${var.app_name}-db"
  engine     = "pg"
  version    = "15"
  size       = var.db_size
  region     = var.region
  node_count = 1

  maintenance_window {
    day  = "sunday"
    hour = "02:00"
  }

  backup_restore {
    enabled = true
    days    = ["sunday", "wednesday"]
    hour    = "04:00"
  }
}

resource "digitalocean_database_db" "streamsource" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "${var.app_name}_production"
}

# Use default database user instead of creating custom one
# DigitalOcean provides a default 'doadmin' user that works well with Rails

# Redis for caching and sessions
resource "digitalocean_database_cluster" "redis" {
  name       = "${var.app_name}-redis"
  engine     = "redis"
  version    = "7"
  size       = var.redis_size
  region     = var.region
  node_count = 1

  maintenance_window {
    day  = "sunday"
    hour = "03:00"
  }

  redis_config = {
    maxmemory_policy = "allkeys-lru"
    timeout          = "300"
  }
}

# App Platform (when not using droplets)
resource "digitalocean_app" "streamsource" {
  count = var.use_droplets ? 0 : 1
  spec {
    name   = var.app_name
    region = var.region

    service {
      name               = "web"
      environment_slug   = "ruby"
      instance_count     = var.app_instance_count
      instance_size_slug = var.app_instance_size
      
      git {
        repo_clone_url = var.github_repo
        branch         = var.github_branch
      }

      build_command = "bundle install && yarn install && yarn build && yarn build:css && bundle exec rails assets:precompile"
      run_command   = "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0"

      http_port = 3000

      health_check {
        http_path       = "/health"
        initial_delay_seconds = 30
        period_seconds        = 10
        timeout_seconds       = 5
        success_threshold     = 1
        failure_threshold     = 3
      }

      env {
        key   = "RAILS_ENV"
        value = "production"
      }

      env {
        key   = "RAILS_SERVE_STATIC_FILES"
        value = "true"
      }

      env {
        key   = "RAILS_LOG_TO_STDOUT"
        value = "true"
      }

      env {
        key   = "DATABASE_URL"
        value = digitalocean_database_cluster.postgres.uri
        type  = "SECRET"
      }

      env {
        key   = "REDIS_URL"
        value = digitalocean_database_cluster.redis.uri
        type  = "SECRET"
      }

      env {
        key   = "SECRET_KEY_BASE"
        value = var.secret_key_base
        type  = "SECRET"
      }

      env {
        key   = "JWT_SECRET"
        value = var.jwt_secret
        type  = "SECRET"
      }

      env {
        key   = "RAILS_MASTER_KEY"
        value = var.rails_master_key
        type  = "SECRET"
      }

      env {
        key   = "RAILS_MAX_THREADS"
        value = var.rails_max_threads
      }

      env {
        key   = "WEB_CONCURRENCY"
        value = var.web_concurrency
      }
    }
  }
}

# Create a droplet for the application (when not using App Platform)
resource "digitalocean_droplet" "app" {
  count    = var.use_droplets ? 1 : 0
  name     = "${var.app_name}-app-${count.index + 1}"
  size     = var.droplet_size
  image    = var.droplet_image
  region   = var.region
  ssh_keys = var.ssh_key_fingerprints
  
  tags = ["${var.app_name}", "web", "production"]
  
  # Basic setup on creation
  user_data = file("${path.module}/cloud-init.yml")
}

# Create Ansible inventory from Terraform outputs
resource "local_file" "ansible_inventory" {
  count = var.use_droplets ? 1 : 0
  
  content = templatefile("${path.module}/templates/inventory.yml.tpl", {
    app_servers       = digitalocean_droplet.app[*].ipv4_address
    database_url      = digitalocean_database_cluster.postgres.uri
    redis_url         = digitalocean_database_cluster.redis.uri
    secret_key_base   = var.secret_key_base
    rails_master_key  = var.rails_master_key
    jwt_secret        = var.jwt_secret
    app_domain        = var.app_domain
    github_repo       = var.github_repo
    github_branch     = var.github_branch
  })
  
  filename = "${path.module}/../ansible/inventory/hosts.yml"
  
  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/../ansible/inventory/hosts.yml"
  }
}

# Run Ansible playbook after infrastructure is ready
resource "null_resource" "run_ansible" {
  count = var.use_droplets && var.run_ansible ? 1 : 0
  
  depends_on = [
    digitalocean_droplet.app,
    digitalocean_database_cluster.postgres,
    digitalocean_database_cluster.redis,
    digitalocean_database_firewall.postgres,
    digitalocean_database_firewall.redis,
    local_file.ansible_inventory
  ]
  
  triggers = {
    droplet_ids = join(",", digitalocean_droplet.app[*].id)
    playbook    = filemd5("${path.module}/../ansible/site.yml")
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../ansible
      export ANSIBLE_HOST_KEY_CHECKING=False
      ansible-playbook site.yml \
        --inventory inventory/hosts.yml \
        --private-key ${var.ssh_private_key_path} \
        --extra-vars "@${path.module}/ansible_vars.json"
    EOT
    
    environment = {
      ANSIBLE_FORCE_COLOR = "true"
    }
  }
}

# Generate ansible vars file
resource "local_file" "ansible_vars" {
  count = var.use_droplets ? 1 : 0
  
  content = jsonencode({
    database_url     = digitalocean_database_cluster.postgres.uri
    redis_url        = digitalocean_database_cluster.redis.uri
    secret_key_base  = var.secret_key_base
    rails_master_key = var.rails_master_key
    jwt_secret       = var.jwt_secret
    github_repo      = var.github_repo
    github_branch    = var.github_branch
    app_domain       = var.app_domain
  })
  
  filename = "${path.module}/ansible_vars.json"
  
  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/ansible_vars.json"
  }
}

# Domain configuration (optional)
resource "digitalocean_domain" "main" {
  count = var.app_domain != "" ? 1 : 0
  name  = var.app_domain
}

resource "digitalocean_record" "app" {
  count  = var.app_domain != "" ? 1 : 0
  domain = digitalocean_domain.main[0].id
  type   = "CNAME"
  name   = "@"
  value  = digitalocean_app.streamsource.live_url
}

# Firewall for database security
resource "digitalocean_database_firewall" "postgres" {
  cluster_id = digitalocean_database_cluster.postgres.id

  rule {
    type  = "app"
    value = var.use_droplets ? "" : digitalocean_app.streamsource[0].id
  }
  
  dynamic "rule" {
    for_each = var.use_droplets ? digitalocean_droplet.app[*].ipv4_address : []
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}

resource "digitalocean_database_firewall" "redis" {
  cluster_id = digitalocean_database_cluster.redis.id

  rule {
    type  = "app"
    value = var.use_droplets ? "" : digitalocean_app.streamsource[0].id
  }
  
  dynamic "rule" {
    for_each = var.use_droplets ? digitalocean_droplet.app[*].ipv4_address : []
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}