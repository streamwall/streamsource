# Contributing to StreamSource

Thank you for your interest in contributing to StreamSource! This guide will help you get started with contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

> **IMPORTANT**: This project runs exclusively in Docker containers. Do not use system Ruby, Bundler, or any local development tools. All commands must be executed within the Docker environment.

### Prerequisites

- Docker and Docker Compose (required)
- Git
- A text editor (VS Code recommended)
- GitHub account

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub first, then:
git clone https://github.com/YOUR_USERNAME/streamsource.git
cd streamsource

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/streamsource.git
```

### 2. Environment Setup

```bash
# Copy environment file
cp .env.example .env

# Start Docker services
docker compose up -d

# Verify everything is running
docker compose ps
docker compose logs -f web
```

### 3. Initial Testing

```bash
# Run tests to ensure setup is correct
docker compose exec web bin/test

# Access the application
# API: http://localhost:3000
# Admin: http://localhost:3000/admin (admin@example.com / Password123!)
# API Docs: http://localhost:3000/api-docs
```

## Making Changes

### 1. Sync with Upstream

```bash
# Fetch latest changes
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

### 2. Create a Feature Branch

```bash
# For features
git checkout -b feature/your-feature-name

# For bug fixes
git checkout -b fix/issue-description

# For documentation
git checkout -b docs/what-you-are-documenting
```

### 3. Development Workflow

#### Write Tests First (TDD)

```ruby
# spec/models/widget_spec.rb
require 'rails_helper'

RSpec.describe Widget, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end
  
  describe '#calculate_value' do
    it 'returns the correct value' do
      widget = create(:widget, base: 10, multiplier: 2)
      expect(widget.calculate_value).to eq(20)
    end
  end
end
```

#### Implement Your Feature

```ruby
# app/models/widget.rb
class Widget < ApplicationRecord
  validates :name, presence: true
  
  def calculate_value
    base * multiplier
  end
end
```

#### Run Tests Continuously

```bash
# Run all tests
docker compose exec web bin/test

# Run specific test file
docker compose exec web bin/test spec/models/widget_spec.rb

# Run tests matching a pattern
docker compose exec web bin/test spec/models
```

### 4. Code Quality Checks

```bash
# Run RuboCop
docker compose exec web bundle exec rubocop

# Auto-fix style issues
docker compose exec web bundle exec rubocop -A

# Run security checks
docker compose exec web bundle exec brakeman -q -w2

# Check for vulnerable dependencies
docker compose exec web bundle exec bundler-audit --update
```

## Coding Standards

### Ruby Style Guide

We use RuboCop with Rails Omakase configuration. Key principles:

```ruby
# Good: Clear, simple, follows conventions
class StreamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stream, only: %i[show update destroy]

  def index
    @pagy, @streams = pagy(
      policy_scope(Stream)
        .includes(:streamer, :user)
        .filter_by(filter_params)
    )
  end

  private

  def set_stream
    @stream = Stream.find(params[:id])
    authorize @stream
  end

  def stream_params
    params.require(:stream).permit(:url, :streamer_id, :notes)
  end

  def filter_params
    params.permit(:status, :platform, :pinned, :archived, :search)
  end
end
```

### JavaScript/Stimulus Controllers

```javascript
// app/javascript/controllers/stream_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "viewers"]
  static values = { 
    url: String,
    refreshInterval: { type: Number, default: 30000 }
  }

  connect() {
    this.refresh()
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  refresh() {
    fetch(this.urlValue)
      .then(response => response.json())
      .then(data => this.updateDisplay(data))
      .catch(error => console.error("Refresh failed:", error))
  }

  updateDisplay(data) {
    this.statusTarget.textContent = data.status
    this.viewersTarget.textContent = data.viewer_count
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.refreshIntervalValue)
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
}
```

### Database Migrations

```ruby
# Good: Reversible, includes indexes, considers performance
class AddStatusIndexToStreams < ActiveRecord::Migration[8.0]
  def change
    add_index :streams, :status
    add_index :streams, [:user_id, :status]
    add_index :streams, [:streamer_id, :status], where: "archived = false"
  end
end
```

## Testing Guidelines

### Test Structure

Follow the AAA pattern (Arrange, Act, Assert):

```ruby
require 'rails_helper'

RSpec.describe StreamCheckService, type: :service do
  describe '.call' do
    let(:stream) { create(:stream, url: 'https://twitch.tv/example') }
    
    context 'when stream is live' do
      before do
        # Arrange
        stub_request(:get, stream.url)
          .to_return(status: 200, body: live_response_body)
      end

      it 'updates stream status to live' do
        # Act
        result = described_class.call(stream)
        
        # Assert
        expect(result).to be_success
        expect(stream.reload.status).to eq('live')
        expect(stream.viewer_count).to be > 0
      end
    end

    context 'when stream is offline' do
      # ...
    end
  end
end
```

### Testing Best Practices

1. **Use Factories**: Never use fixtures
   ```ruby
   # spec/factories/streams.rb
   FactoryBot.define do
     factory :stream do
       user
       url { "https://twitch.tv/#{Faker::Internet.username}" }
       status { 'checking' }
       
       trait :live do
         status { 'live' }
         viewer_count { rand(100..5000) }
       end
     end
   end
   ```

2. **Test Edge Cases**
   ```ruby
   it 'handles nil values gracefully'
   it 'validates maximum length'
   it 'prevents SQL injection'
   it 'handles concurrent updates'
   ```

3. **Mock External Services**
   ```ruby
   before do
     allow(ExternalAPI).to receive(:fetch).and_return(mock_response)
   end
   ```

## Common Development Tasks

### Adding a New Model

```bash
# 1. Generate model
docker compose exec web bin/rails generate model Widget name:string value:integer user:references

# 2. Write tests first (TDD)
# Edit spec/models/widget_spec.rb

# 3. Run migration
docker compose exec web bin/rails db:migrate

# 4. Add factory
# Edit spec/factories/widgets.rb

# 5. Implement model logic
# Edit app/models/widget.rb
```

### Adding an API Endpoint

```bash
# 1. Add route
# Edit config/routes.rb

# 2. Write request specs
# Create spec/requests/api/v1/widgets_spec.rb

# 3. Implement controller
# Create app/controllers/api/v1/widgets_controller.rb

# 4. Add serializer if needed
# Create app/serializers/widget_serializer.rb

# 5. Update API documentation
# Edit docs/API.md and Swagger specs
```

### Adding a Feature Flag

```ruby
# 1. Add to constants
# config/application_constants.rb
FEATURE_FLAGS = {
  widgets: 'Enable widget management',
  # ...
}.freeze

# 2. Use in code
if Flipper.enabled?(:widgets, current_user)
  # Feature code
end

# 3. Test both states
context 'when widgets feature is enabled' do
  before { Flipper.enable(:widgets) }
  # ...
end

context 'when widgets feature is disabled' do
  before { Flipper.disable(:widgets) }
  # ...
end
```

### Debugging

```bash
# Rails console
docker compose exec web bin/rails console

# View logs
docker compose logs -f web

# Attach debugger
# Add `binding.pry` or `debugger` in your code
docker attach streamsource-web-1

# Database console
docker compose exec db psql -U streamsource
```

## Submitting Changes

### 1. Commit Guidelines

Write clear, descriptive commit messages following conventional commits:

```bash
# Format: <type>(<scope>): <subject>

# Examples
git commit -m "feat(api): add filtering by platform to streams endpoint"
git commit -m "fix(streams): resolve N+1 query in index action"
git commit -m "docs(api): update authentication examples"
git commit -m "test(streams): add edge cases for status transitions"
git commit -m "refactor(models): extract stream status logic to concern"

# Types:
# feat: new feature
# fix: bug fix
# docs: documentation changes
# style: formatting, missing semicolons, etc.
# refactor: code change that neither fixes a bug nor adds a feature
# test: adding missing tests
# chore: changes to build process or auxiliary tools
```

### 2. Pre-Submit Checklist

```bash
# Ensure all tests pass
docker compose exec web bin/test

# Check code coverage (should be >90%)
# Open coverage/index.html after tests run

# Run linting
docker compose exec web bundle exec rubocop

# Check for security issues
docker compose exec web bundle exec brakeman -q

# Update documentation if needed
# - README.md for new features
# - API.md for endpoint changes
# - ENVIRONMENT_VARIABLES.md for new env vars
```

### 3. Pull Request Template

```markdown
## Description
Brief description of what this PR does and why.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## How Has This Been Tested?
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing
- [ ] All existing tests pass

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Additional Notes
Any additional information that reviewers should know.
```

## Getting Help

### Resources

1. **Documentation**
   - `/README.md` - Project overview
   - `/CLAUDE.md` - Architecture details
   - `/docs/` - Additional documentation
   - `/api-docs` - Interactive API docs

2. **Code Examples**
   - Check existing tests for patterns
   - Review similar features in codebase
   - Look at recent PRs for examples

3. **Community**
   - Open an issue for bugs
   - Start a discussion for questions
   - Comment on your PR if stuck

### Docker Troubleshooting

```bash
# Container won't start
docker compose logs web
docker compose down -v
docker compose up -d --build

# Permission issues
docker compose exec web chown -R $(id -u):$(id -g) .

# Out of disk space
docker system prune -a

# Rebuild from scratch
docker compose down -v
rm -rf tmp/ log/
docker compose build --no-cache
docker compose up -d
```

## Recognition

Contributors are recognized in:
- Git history and GitHub contributors page
- Release notes for significant contributions
- Special thanks in project documentation

Thank you for contributing to StreamSource! Your efforts help make this project better for everyone. 🎉