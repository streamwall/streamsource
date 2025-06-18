---
all:
  vars:
    app_name: streamsource
    app_user: rails
    app_path: /home/rails/streamsource
    ruby_version: 3.3.6
    nodejs_version: 20
    
    # Database and Redis URLs from Terraform
    database_url: "${database_url}"
    redis_url: "${redis_url}"
    
    # Secrets from Terraform
    secret_key_base: "${secret_key_base}"
    rails_master_key: "${rails_master_key}"
    jwt_secret: "${jwt_secret}"
    
    # Application configuration
    app_domain: "${app_domain}"
    github_repo: "${github_repo}"
    github_branch: "${github_branch}"
    
    # Performance tuning
    rails_max_threads: 5
    web_concurrency: 2
    
  children:
    app_servers:
      hosts:
%{ for index, ip in app_servers ~}
        app-${index + 1}:
          ansible_host: ${ip}
%{ endfor ~}