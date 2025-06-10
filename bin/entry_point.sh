#!/bin/bash

# Entry point script for Jekyll Docker container

set -e

# Change to the Jekyll site directory
cd /srv/jekyll

# Copy the site files to the working directory (if they exist)
if [ "$(ls -A /srv/jekyll-site 2>/dev/null)" ]; then
    echo "Copying site files..."
    cp -r /srv/jekyll-site/. /srv/jekyll/
fi

# Install/update dependencies
echo "Installing dependencies..."
bundle install

# Start Jekyll with the specified options
echo "Starting Jekyll server..."
exec bundle exec jekyll serve --host 0.0.0.0 --port 8001 --livereload

