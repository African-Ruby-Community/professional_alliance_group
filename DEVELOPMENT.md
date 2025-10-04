# Development Guide

This document provides information for developers working on the Professional Alliance Group website.

## Prerequisites

- Ruby 3.0+
- Bundler
- Jekyll 4.4+

## Setup

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Start the development server:
   ```bash
   bundle exec jekyll serve
   ```

## Development Tools

### Code Quality

- **RuboCop**: Ruby linter and formatter
  ```bash
  bundle exec rubocop
  bundle exec rubocop -A  # Auto-fix
  ```

- **Rake tasks**: Convenient development commands
  ```bash
  rake rubocop      # Run linter
  rake rubocop_fix  # Auto-fix issues
  rake build        # Build site
  rake serve        # Start server
  rake lint         # Run all linting
  rake dev          # Run linting and build
  ```

### IDE Setup

The project includes configuration for:
- **VS Code/Cursor**: Ruby LSP, RuboCop integration, Liquid template support
- **RuboCop**: Code style enforcement with Jekyll-specific rules

## Project Structure

- `_includes/`: Liquid template includes
- `_layouts/`: Jekyll layouts
- `_data/`: Site data (JSON/YAML)
- `assets/`: CSS, JS, and other assets
- `images/`: Static images
- `_build/`: Ruby build scripts

## Contributing

1. Follow RuboCop style guidelines
2. Test changes with `rake dev`
3. Ensure all linting passes before committing
