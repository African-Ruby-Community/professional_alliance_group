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
  if ENV['CREDENTIALS_PATH'] && !ENV['CREDENTIALS_PATH'].empty?
    ENV['CREDENTIALS_PATH'] = File.expand_path(ENV['CREDENTIALS_PATH'], Dir.pwd) unless ENV['CREDENTIALS_PATH'].start_with?('/')

    if File.exist?(ENV['CREDENTIALS_PATH'])
      Jekyll.logger.info "✅ Found credentials file at #{ENV['CREDENTIALS_PATH']}"
    else
      Jekyll.logger.info "❌ Credentials file not found at #{ENV['CREDENTIALS_PATH']}"
    end
  else
    Jekyll.logger.info '⚠️ CREDENTIALS_PATH not set in .env file'
  end
end
