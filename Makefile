# Makefile for Jekyll Setup and Commands

.PHONY: install serve build clean sync generate generate-members generate-groups generate-projects sync-and-generate setup-project test-minification

CONFIGS = _config.yml,_config.local.yml

# Install bundler and jekyll
install:
	gem install bundler jekyll
	bundle config set --local path 'vendor/bundle'
	bundle install
	bundle update

# First time setup: install bundler and jekyll, then serve the site
setup:
	gem install bundler jekyll
	bundle config set --local path 'vendor/bundle'
	bundle install
	bundle update
	bundle exec jekyll serve --config $(CONFIGS)

# Sync data from Google Sheets
sync:
	bundle exec ruby _build/sync_google_sheets.rb

# Generate member files
generate-members:
	bundle exec ruby _build/generate_member_files.rb

# Generate group files
generate-groups:
	bundle exec ruby _build/generate_group_files.rb

# Generate project files
generate-projects:
	bundle exec ruby _build/generate_project_files.rb

# Generate all files (members, groups, and projects)
generate: generate-members generate-groups generate-projects

# Sync data and generate all files
sync-and-generate: sync generate

# Serve the Jekyll site locally for development
serve:
	bundle exec jekyll serve --config $(CONFIGS) -d public

# Complete development workflow: sync data, generate files, and serve
dev: sync-and-generate serve

# Build the site for deployment with optimizations
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

# Clean the vendor directory and generated files
clean:
	rm -rf vendor _site
	rm -rf _data/new_remote/*.yml
	rm -rf _members/alice.md _members/james.md _members/banta.md
	rm -rf _groups/group1.md _groups/group2.md
	rm -rf _projects/project1.md _projects/project2.md _projects/project3.md _projects/project4.md
	rm -rf images/compressed/remote_groups/* images/compressed/remote_members/*
	rm -rf assets/images/remote_groups/* assets/images/remote_members/* assets/images/remote_project_contributors/*

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
