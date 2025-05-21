def load_env_if_available
  begin
    require 'dotenv'
    if File.exist?('.env')
      Dotenv.load
      puts "🔍 Loaded env vars from .env"

      # Validate and adjust paths if needed
      if ENV['CREDENTIALS_PATH'] && !ENV['CREDENTIALS_PATH'].empty?
        # If CREDENTIALS_PATH is a relative path, make it absolute
        unless ENV['CREDENTIALS_PATH'].start_with?('/')
          ENV['CREDENTIALS_PATH'] = File.expand_path(ENV['CREDENTIALS_PATH'], Dir.pwd)
        end

        if File.exist?(ENV['CREDENTIALS_PATH'])
          puts "✅ Found credentials file at #{ENV['CREDENTIALS_PATH']}"
        else
          puts "❌ Credentials file not found at #{ENV['CREDENTIALS_PATH']}"
        end
      else
        puts "⚠️ CREDENTIALS_PATH not set in .env file"
      end
    else
      puts "⚠️ No .env file found"
    end
  rescue LoadError
    puts "📦 Dotenv not available (likely running in CI)"
  end
end
