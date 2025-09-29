# frozen_string_literal: true

def load_env_if_available
  require 'dotenv'
  load_and_validate_env if File.exist?('.env')
rescue LoadError
  Jekyll.logger.info '📦 Dotenv not available (likely running in CI)'
end

private

def load_and_validate_env
  Dotenv.load
  Jekyll.logger.info '🔍 Loaded env vars from .env'
  validate_credentials_path
end

def validate_credentials_path
  return log_missing_credentials_path unless credentials_path_present?

  normalize_credentials_path
  log_credentials_file_status
end

def credentials_path_present?
  ENV.fetch('CREDENTIALS_PATH', nil) && !ENV.fetch('CREDENTIALS_PATH').empty?
end

def normalize_credentials_path
  return if ENV.fetch('CREDENTIALS_PATH').start_with?('/')

  ENV['CREDENTIALS_PATH'] = File.expand_path(ENV.fetch('CREDENTIALS_PATH', nil), Dir.pwd)
end

def log_credentials_file_status
  if File.exist?(ENV['CREDENTIALS_PATH'])
    Jekyll.logger.info "✅ Found credentials file at #{ENV['CREDENTIALS_PATH']}"
  else
    Jekyll.logger.info "❌ Credentials file not found at #{ENV['CREDENTIALS_PATH']}"
  end
end

def log_missing_credentials_path
  Jekyll.logger.info '⚠️ CREDENTIALS_PATH not set in .env file'
end
