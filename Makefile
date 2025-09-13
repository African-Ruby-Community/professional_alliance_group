## Makefile for Jekyll Setup and Commands

.PHONY: help confirm install setup sync serve build clean

CONFIGS = _config.yml,_config.local.yml

## help: Print this help message
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## confirm: Ask for confirmation before running a command
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

## install: Install bundler and jekyll, the install dependecies
install:
	gem install bundler jekyll
	bundle config set --local path 'vendor/bundle'
	bundle install
	bundle update

## setup: First time setup: install bundler and jekyll, then serve the site
setup:
	gem install bundler jekyll
	bundle config set --local path 'vendor/bundle'
	bundle install
	bundle update
	bundle exec jekyll serve --config $(CONFIGS)

## sync: Sync data from Google Sheets to _data/new_remote
sync:
	bundle exec ruby _build/google_service_account.rb

## serve: Serve the Jekyll site locally for development
serve:
	bundle exec jekyll serve --config $(CONFIGS) -d public --verbose

## Build the site for deployment with optimizations
build:
	JEKYLL_ENV=production bundle exec jekyll build -d public --trace
	@echo "Running PurgeCSS to remove unused CSS..."
	@if command -v purgecss >/dev/null 2>&1; then \
		purgecss -c purgecss.config.js; \
	else \
		echo "PurgeCSS not found. Installing..."; \
		npm install -g purgecss; \
		purgecss -c purgecss.config.js; \
	fi
	@echo "✅ Site built and optimized in the 'public' directory"

## clean: Clean the vendor directory and generated files
clean: confirm
	rm -rf vendor _site
	rm -rf _data/new_remote/*.yml

## lint: Run RuboCop linter
lint:
	bundle exec rubocop

## lint-fix: Run RuboCop with auto-fix
lint-fix:
	bundle exec rubocop -A

## dev: Run development tasks (lint + build)
dev: lint
	@echo "Running Jekyll build..."
	@$(MAKE) build

# Setup the project: install dependencies, clean generated files, sync data, and generate files
setup-project:
	@echo "Setting up the project..."
	@echo "1. Installing dependencies..."
	@$(MAKE) install
	@echo "2. Cleaning old generated files..."
	@$(MAKE) clean
	@echo "3. Syncing data from Google Sheets..."
	@$(MAKE) sync
	@echo "4. Generating member and group files..."
	@$(MAKE) generate
	@echo "✅ Project setup complete! Run 'make serve' to start the development server."

# Test minification of the built site
test-minification:
	@if [ ! -d "public" ]; then \
		echo "❌ The 'public' directory does not exist. Running build first..."; \
		$(MAKE) build; \
	fi
	@echo "Testing minification of HTML, CSS, and JavaScript files..."
	@bundle exec ruby _build/test_minification.rb
