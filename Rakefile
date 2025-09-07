# Rakefile for development tasks
require 'bundler/setup'

desc 'Run RuboCop linter'
task :rubocop do
  sh 'bundle exec rubocop'
end

desc 'Run RuboCop with auto-fix'
task :rubocop_fix do
  sh 'bundle exec rubocop -A'
end

desc 'Run Jekyll build'
task :build do
  sh 'bundle exec jekyll build'
end

desc 'Run Jekyll serve'
task :serve do
  sh 'bundle exec jekyll serve'
end

desc 'Run all linting tasks'
task :lint => [:rubocop]

desc 'Run all development tasks'
task :dev => [:rubocop, :build]

task :default => :dev
