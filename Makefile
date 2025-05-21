# Makefile for Jekyll Setup and Commands

.PHONY: install serve build clean sync generate generate-members generate-groups generate-projects sync-and-generate setup-project

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
	ruby _build/sync_google_sheets.rb

# Generate member files
generate-members:
	ruby _build/generate_member_files.rb

# Generate group files
generate-groups:
	ruby _build/generate_group_files.rb

# Generate project files
generate-projects:
	ruby _build/generate_project_files.rb

# Generate all files (members, groups, and projects)
generate: generate-members generate-groups generate-projects

# Sync data and generate all files
sync-and-generate: sync generate

# Serve the Jekyll site locally for development
serve:
	bundle exec jekyll serve --config $(CONFIGS)

# Complete development workflow: sync data, generate files, and serve
dev: sync-and-generate serve

# Build the site for deployment
build:
	bundle exec jekyll build -d public

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
