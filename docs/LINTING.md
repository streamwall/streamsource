# Code Quality & Linting Guide

This document outlines the comprehensive linting and code quality setup for StreamSource.

## Overview

StreamSource uses a multi-layered approach to code quality:

- **Ruby**: RuboCop with Rails, Performance, and RSpec extensions
- **JavaScript**: ESLint with Standard config
- **Security**: Brakeman static analysis
- **Editor**: EditorConfig for consistent formatting
- **Auto-fixing**: Automated code style correction

## Quick Commands

```bash
# Run all linting checks
make lint

# Auto-fix all issues
make lint-fix

# Individual linters
make lint-ruby     # Ruby only
make lint-js       # JavaScript only  
make security      # Security analysis only

# Code quality metrics
make quality       # View project statistics

# Pre-commit validation
make pre-commit    # Full validation before commits
```

## Ruby Linting (RuboCop)

### Configuration

- **File**: `.rubocop.yml`
- **Extensions**: Rails, Performance, RSpec
- **Style**: Rails-focused with practical defaults

### Key Rules

- Line length: 120 characters
- Method length: 20 lines (excluding tests)
- Class length: 150 lines (excluding tests)
- String literals: Double quotes preferred
- Trailing commas: Required for multi-line structures

### Excluded Files

- `bin/**/*` - Executable scripts
- `db/migrate/**/*` - Database migrations  
- `vendor/**/*` - Third-party code
- `node_modules/**/*` - JavaScript dependencies
- `coverage/**/*` - Coverage reports

### Auto-Fixing

RuboCop can automatically fix many issues:

```bash
make lint-fix        # Fix all auto-correctable issues
make lint-ruby       # Check Ruby issues only
```

## JavaScript Linting (ESLint)

### Configuration

- **File**: `.eslintrc.json`
- **Standard**: JavaScript Standard Style
- **Environment**: Browser + ES2022

### Key Rules

- Quotes: Single quotes preferred
- Semicolons: Not required
- Indentation: 2 spaces
- No unused variables (except prefixed with `_`)
- Function spacing: Space before parentheses

### Global Variables

Pre-configured for Rails/Hotwire:
- `Stimulus`
- `Turbo` 
- `ActionCable`
- `Rails`

### Auto-Fixing

```bash
yarn lint:js:fix     # Fix JavaScript issues
make lint-fix        # Includes JS auto-fix
```

## Security Analysis (Brakeman)

### Overview

Brakeman performs static security analysis on Rails applications.

### Current Status

- **Total Warnings**: 1 (down from 4)
- **Fixed Issues**: Password regex vulnerability, Format validation issues
- **Remaining**: Mass assignment warning in Users controller

### Commands

```bash
make security              # Quick security scan
make security-detailed     # Generate HTML report
```

### Addressing Issues

1. **Mass Assignment**: Review parameter filtering in controllers
2. **SQL Injection**: Use parameterized queries
3. **XSS**: Ensure proper output escaping
4. **Authentication**: Validate JWT tokens properly

## Editor Configuration

### EditorConfig (`.editorconfig`)

Ensures consistent formatting across editors:

- Charset: UTF-8
- Line endings: LF
- Final newline: Required
- Trailing whitespace: Trimmed
- Indentation: 2 spaces for most files

### Supported File Types

- Ruby (`.rb`, `.rake`, `.ru`)
- JavaScript (`.js`, `.jsx`, `.ts`, `.tsx`)
- YAML (`.yml`, `.yaml`)
- JSON (`.json`)
- HTML/ERB (`.html`, `.erb`)
- CSS/SCSS (`.css`, `.scss`)

## Integration & Workflow

### Pre-Commit Checks

The `make pre-commit` command runs:

1. Full test suite
2. Ruby code style checks
3. Security analysis  
4. JavaScript linting

### Continuous Integration

Recommended CI pipeline:

```yaml
- name: Code Quality
  run: |
    make lint
    make security
    make test
```

### IDE Setup

#### VS Code

Recommended extensions:
- Ruby LSP
- ESLint
- EditorConfig for VS Code
- Better Comments

#### RubyMine

Built-in support for:
- RuboCop integration
- EditorConfig
- ESLint (with plugin)

## Metrics & Statistics

### Code Quality Metrics

```bash
make quality
```

Shows:
- Lines of code (Ruby/JavaScript)
- Test coverage percentage
- File counts by type

### Coverage Goals

- **Target**: >90% test coverage
- **Current**: 78% (good progress!)
- **Focus Areas**: Controllers, edge cases

## Customization

### Adding New Rules

1. **Ruby**: Edit `.rubocop.yml`
2. **JavaScript**: Edit `.eslintrc.json`
3. **Security**: Configure via Brakeman options

### Project-Specific Overrides

The configuration includes Rails-specific adjustments:

- Longer line lengths for API docs
- Flexible method lengths for controllers
- RSpec-friendly block lengths
- Rails naming conventions

## Best Practices

### Before Committing

1. Run `make pre-commit` to validate all changes
2. Address any linting issues
3. Ensure security warnings are resolved
4. Verify test coverage remains high

### During Development

1. Use `make lint-fix` for quick style fixes
2. Run individual linters for faster feedback
3. Monitor security warnings with `make security`
4. Check metrics periodically with `make quality`

### Code Review

Focus on:
- Security implications of changes
- Test coverage for new features
- Adherence to Rails conventions
- Performance impact of changes

## Troubleshooting

### Common Issues

1. **RuboCop Plugin Errors**: Ensure gems are installed with `bundle install`
2. **ESLint Not Found**: Run `yarn install` to install JavaScript dependencies
3. **Permission Errors**: Ensure Docker container has proper permissions
4. **Slow Linting**: Use individual commands for faster feedback

### Performance Tips

- Use `make lint-ruby` for Ruby-only checks
- Use `make lint-js` for JavaScript-only checks
- Run `make lint-fix` to batch auto-corrections
- Use parallel execution in CI environments

## Maintenance

### Updating Dependencies

```bash
bundle update rubocop rubocop-rails rubocop-performance rubocop-rspec
yarn upgrade eslint eslint-config-standard
```

### Configuration Updates

Review and update configurations quarterly:
- New RuboCop cops
- Updated ESLint rules
- Security check improvements
- Performance optimizations

---

This linting setup ensures consistent, secure, and maintainable code across the StreamSource project.