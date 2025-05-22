require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'
require 'googleauth'
require 'yaml'
require 'fileutils'
require 'open-uri' # For downloading images
require 'uri' # For parsing URLs
require 'stringio'
require 'mini_magick'
require_relative './env_helper'

# --- Image Optimization Configuration ---
# Maximum width for images (adjust as needed)
MAX_IMAGE_WIDTH = 1200
# JPEG quality (1-100, lower means more compression)
JPEG_QUALITY = 80
# PNG compression level (0-9, higher means more compression)
PNG_COMPRESSION = 8
# Create a directory for optimized images
OPTIMIZED_IMAGE_DIR = "images/compressed"
FileUtils.mkdir_p(OPTIMIZED_IMAGE_DIR)


load_env_if_available

# --- Configuration ---
DATA_FOLDER = "_data/new_remote"
# Base Jekyll URL path for images
JEKYLL_ROOT_IMAGE_BASE = "assets/images"
# Local file system path for saving images (e.g., assets/remote_members)
LOCAL_FILE_IMAGE_BASE = "assets/images"

# Check the existence of data and image directories
FileUtils.mkdir_p(DATA_FOLDER)
FileUtils.mkdir_p(LOCAL_FILE_IMAGE_BASE)

# Env variables to handle both the local file and string for GH Actions
CREDENTIALS_PATH = ENV['CREDENTIALS_PATH'] # Local testing
SERVICE_ACCOUNT_JSON = ENV['SERVICE_ACCOUNT_JSON']
APPLICATION_NAME = ENV['APPLICATION_NAME']  
SPREADSHEET_ID = ENV['SPREADSHEET_ID']

# Define which column contains the image URL (case-insensitive)
DEFAULT_IMAGE_COLUMN_NAME = "image"

# Sheet configurations
sheets_config = {}
1.upto(10) do |i|
  # Assuming you might have up to 10 sheets configured
  filename_key = ENV["SHEET#{i}_FILENAME"] # Key for the output YML file e.g., members
  sheet_name = ENV["SHEET#{i}_NAME"] # Actual tab in Google Sheet
  image_col = ENV["SHEET#{i}_IMAGE_COLUMN"] # Optional: specific image column name for this sheet
  image_subdir = ENV["SHEET#{i}_IMAGE_SUBDIR"] # Optional: specific image subdirectory under /images/


  if filename_key && sheet_name
    sheets_config[filename_key] = {
      sheet_name: sheet_name,
      image_column_name: image_col || DEFAULT_IMAGE_COLUMN_NAME, # Use specific or default
      image_subdirectory: image_subdir # Set this only if provided, otherwise it's nil
    }
  end
end

if sheets_config.empty?
  puts "⚠️ No valid sheets configured. Please set SHEET1_FILENAME and corresponding SHEET1_NAME (and so on) in .env"
  exit(1)
end

# Define scopes for both Sheets and Drive
SHEETS_SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
DRIVE_SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_READONLY
SCOPE = [SHEETS_SCOPE, DRIVE_SCOPE]

# --- Authorization Function ---
def authorize_google_sheets(credentials_path, service_account_json)
  if service_account_json && !service_account_json.empty?
    begin
      puts "Authenticating using SERVICE_ACCOUNT_JSON environment variable."
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(service_account_json),
        scope: SCOPE
      )
      # Ensure credentials are properly authorized
      credentials.fetch_access_token!
      puts "✅ Successfully authenticated using SERVICE_ACCOUNT_JSON"
      return credentials
    rescue JSON::ParserError => e
      puts "❌ Error parsing SERVICE_ACCOUNT_JSON env variable: #{e.message}"
      exit(1)
    rescue Google::Auth::CredentialsError => e
      puts "❌ Error creating credentials from JSON string: #{e.message}"
      exit(1)
    end
  elsif credentials_path && File.exist?(credentials_path)
    begin
      puts "Authenticating using credentials file at #{credentials_path}."
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(credentials_path),
        scope: SCOPE
      )
      # Ensure credentials are properly authorized
      credentials.fetch_access_token!
      puts "✅ Successfully authenticated using credentials file"
      return credentials
    rescue Errno::ENOENT
      puts "❌ Error: Credentials file not found at #{credentials_path}."
      puts "  Please ensure the file exists or set the CREDENTIALS_PATH environment variable."
      exit(1)
    rescue Google::Auth::CredentialsError => e
      puts "❌ Error creating credentials from file: #{e.message}"
      exit(1)
    rescue JSON::ParserError => e
      puts "❌ Error parsing credentials JSON file: #{e.message}"
      exit(1)
    end
  else
    puts "❌ No valid Google Sheets credentials found. Please set CREDENTIALS_PATH (for local) or SERVICE_ACCOUNT_JSON (for GH Actions) environment variable."
    exit(1)
  end
end

# --- Initialize Google Sheets API ---
sheets_service = Google::Apis::SheetsV4::SheetsService.new
sheets_service.client_options.application_name = APPLICATION_NAME
sheets_service.authorization = authorize_google_sheets(CREDENTIALS_PATH, SERVICE_ACCOUNT_JSON)

# --- Initialize Google Drive API ---
drive_service = Google::Apis::DriveV3::DriveService.new
drive_service.client_options.application_name = APPLICATION_NAME
drive_service.authorization = sheets_service.authorization

# --- Helper function to sanitize filenames ---
def sanitize_filename(filename)
  filename.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9_.-]/, '')
end

# --- Helper function to optimize images ---
def optimize_image(input_path, output_dir, output_filename = nil)
  begin
    # Ensure output directory exists
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

    # If no output path is provided, use the input path
    output_filename ||= File.basename(input_path)
    output_path ||= File.join(output_dir, output_filename)

    # Load the image
    image = MiniMagick::Image.open(input_path)

    # Get original dimensions
    original_width = image.width
    original_height = image.height
    original_size = File.size(input_path)

    # Only resize if the image is larger than MAX_IMAGE_WIDTH
    if original_width > MAX_IMAGE_WIDTH
      # Resize the image while maintaining aspect ratio
      image.resize "#{MAX_IMAGE_WIDTH}x"
    end

    # Apply format-specific optimizations
    case File.extname(input_path).downcase
    when '.jpg', '.jpeg'
      # Apply JPEG quality settings
      image.quality(JPEG_QUALITY)
    when '.png'
      # Apply PNG compression
      image.write(output_path) do |img|
        img.quality(100) # Use maximum quality for PNG
        img.define("png:compression-level=#{PNG_COMPRESSION}")
      end
      return output_path
    end

    # Save the optimized image
    image.write(output_path)

    # Log optimization results
    optimized_size = File.size(output_path)
    size_reduction = original_size - optimized_size
    percent_reduction = (size_reduction.to_f / original_size * 100).round(2)

    if size_reduction > 0
      puts "🔄 Image optimized: #{File.basename(input_path)} - Reduced by #{percent_reduction}% (#{(size_reduction.to_f / 1024).round(2)} KB)"
    else
      puts "ℹ️ Image already optimized or couldn't be reduced further: #{File.basename(input_path)}"
    end

    return output_path
  rescue => e
    puts "⚠️ Error optimizing image #{input_path}: #{e.message}"
    # If optimization fails, return the original path
    return input_path
  end
end

# --- Helper function to mask sensitive URLs for logging ---
def mask_url_for_logging(url)
  return "[URL REDACTED]" unless url

  begin
    uri = URI.parse(url)

    # For Google Drive URLs, mask the file ID
    if url.include?('drive.google.com')
      if url.include?('/file/d/')
        # Format: https://drive.google.com/file/d/{fileId}/view?usp=drive_link
        return url.gsub(/\/file\/d\/([^\/]+)/, '/file/d/[FILE_ID_REDACTED]')
      elsif url.include?('id=')
        # Format: https://drive.google.com/open?id={fileId}
        return url.gsub(/id=([^&]+)/, 'id=[FILE_ID_REDACTED]')
      end
    end

    # For other URLs, just show the domain
    "#{uri.scheme}://#{uri.host}/[PATH_REDACTED]"
  rescue URI::InvalidURIError
    "[INVALID_URL_REDACTED]"
  end
end

# --- Helper function to extract Google Drive file ID ---
def extract_google_drive_file_id(url)
  return nil unless url.include?('drive.google.com')

  # Extract file ID from various Google Drive URL formats
  if url.include?('/file/d/')
    # Format: https://drive.google.com/file/d/{fileId}/view?usp=drive_link
    match = url.match(/\/file\/d\/([^\/]+)/)
    return match[1] if match
  elsif url.include?('id=')
    # Format: https://drive.google.com/open?id={fileId}
    match = url.match(/id=([^&]+)/)
    return match[1] if match
  end

  nil
end

# --- Helper function to download file from Google Drive ---
def download_from_google_drive(drive_service, file_id, output_path)
  begin
    # Get the file metadata to determine the MIME type
    file = drive_service.get_file(file_id, fields: 'name, mimeType')

    # Download the file content
    content = drive_service.get_file(file_id, download_dest: StringIO.new)

    # Save the content to the output path
    File.open(output_path, 'wb') do |f|
      f.write(content.string)
    end

    return true
  rescue Google::Apis::ClientError => e
    puts "❌ Error downloading file from Google Drive (ID: #{file_id}): #{e.message}"
    return false
  end
end

# --- Fetch and Process Each Sheet ---
sheets_config.each do |filename_key, config_data|
  sheet_name = config_data[:sheet_name]
  current_image_column_name = config_data[:image_column_name]
  # User 'remote_filename_key' if image_subdirectory is not explicitly set in .env
  image_subdirectory = config_data[:image_subdirectory] || "remote_#{filename_key}"

  # Define a specific local file system directory for images of this sheet
  current_local_image_output_dir = File.join(LOCAL_FILE_IMAGE_BASE, image_subdirectory)
  FileUtils.mkdir_p(current_local_image_output_dir) # Ensure the directory exists

  puts "📥 Fetching '#{filename_key}' data from Google Sheet tab '#{sheet_name}'..."

  begin
    # Add additional error handling for API calls
    begin
      response = sheets_service.get_spreadsheet_values(SPREADSHEET_ID, sheet_name)
      values = response.values
    rescue Google::Apis::AuthorizationError => e
      puts "❌ Authorization error for '#{filename_key}': #{e.message}"
      puts "Please check that your service account has access to the spreadsheet and has been shared with the spreadsheet."
      exit(1)
    rescue Google::Apis::ClientError => e
      puts "❌ Google Sheets API client error for '#{filename_key}': #{e.message}"
      exit(1)
    rescue Google::Apis::ServerError => e
      puts "❌ Google Sheets API server error for '#{filename_key}': #{e.message}"
      exit(1)
    end

    if values.nil? || values.empty?
      puts "⚠️ No data found for '#{filename_key}'. Skipping..."
      next
    end

    headers = values.shift.map(&:downcase) # Downcase headers for case-insensitive matching
    if headers.empty?
      puts "⚠️ Missing headers in sheet '#{sheet_name}'. Skipping..."
      next
    end

    image_column_index = headers.index(current_image_column_name.downcase)

    preprocessed_data = values.map do |row|
      record = headers.zip(row + [nil] * (headers.size - row.size)).to_h

      # Process image if the image column is defined, and the URL is present and not empty
      if image_column_index && record[current_image_column_name.downcase] && !record[current_image_column_name.downcase].to_s.strip.empty?
        image_url = record[current_image_column_name.downcase].strip
        begin
          puts "⬇️ Attempting to download image from: #{mask_url_for_logging(image_url)}"
          uri = URI.parse(image_url)
          file_extension = File.extname(uri.path).downcase

          # --- Determine base name for image file ---
          # Priority: permalink > name > title > project_id > original URL filename > generic timestamp
          base_name_candidate = record['permalink']  # Unique permalink for filename
          unless base_name_candidate
            case filename_key
            when 'members', 'groups'
              base_name_candidate = record['name']
            when 'projects'
              base_name_candidate = record['name'] || record['project_id'] || record['title']
            end
          end

          # Sanitize base name
          sanitized_name = base_name_candidate ? sanitize_filename(base_name_candidate) : nil

          # Fallback if preferred name is empty or results in empty sanitized string
          if sanitized_name.nil? || sanitized_name.empty?
            sanitized_base_name = sanitize_filename(File.basename(uri.path, '.*'))
            if sanitized_base_name.empty?
              sanitized_base_name = "image_#{Time.now.to_i}_#{rand(1000)}" # final unique fallback
            end
          end

          # If file extension is empty (which can happen with Google Drive links), default to .jpg
          file_extension = '.jpg' if file_extension.empty?

          local_image_name = "#{sanitized_name || sanitized_base_name}#{file_extension}"
          local_file_system_path = File.join(current_local_image_output_dir, local_image_name)

          # Check if this is a Google Drive link
          file_id = extract_google_drive_file_id(image_url)

          if file_id
            puts "🔍 Detected Google Drive link, extracting file ID: #{file_id}"
            download_success = download_from_google_drive(drive_service, file_id, local_file_system_path)

            unless download_success
              puts "⚠️ Failed to download from Google Drive, falling back to direct download..."
              # Fall back to direct download if Google Drive API fails
              begin
                URI.open(image_url) do |image_file|
                  File.open(local_file_system_path, 'wb') do |file|
                    IO.copy_stream(image_file, file)
                  end
                end
              rescue OpenURI::HTTPError => e
                raise e # Re-raise to be caught by the outer rescue
              end
            end
          else
            # Regular download for non-Google Drive links
            URI.open(image_url) do |image_file|
              File.open(local_file_system_path, 'wb') do |file|
                IO.copy_stream(image_file, file)
              end
            end
          end

          # Optimize the image
          optimized_filename = "#{File.basename(local_image_name, '.*')}_optimized#{File.extname(local_image_name)}"
          # Create a subdirectory for optimized images for the sheet
          optimized_image_dir = File.join(OPTIMIZED_IMAGE_DIR, image_subdirectory)
          optimized_path = optimize_image(local_file_system_path, optimized_image_dir, optimized_filename)

          # Construct the root-relative path Jekyll will use in the final site
          # Use the optimized image path if it exists, otherwise use the original
          if File.exist?(optimized_path)
            jekyll_relative_image_path = "/#{File.join(OPTIMIZED_IMAGE_DIR, image_subdirectory, optimized_filename)}"
          else
            jekyll_relative_image_path = "/#{File.join(JEKYLL_ROOT_IMAGE_BASE, image_subdirectory, local_image_name)}"
          end

          record[current_image_column_name.downcase] = jekyll_relative_image_path # Overwrite with local path
          puts "✅ Image saved to: #{local_file_system_path} and optimized to: #{optimized_path}"
          puts "✅ Data set to: #{jekyll_relative_image_path}"
        rescue OpenURI::HTTPError => e
          puts "❌ Error downloading image from #{mask_url_for_logging(image_url)}: #{e.message}"
          record[current_image_column_name.downcase] = nil # Or handle error as needed
        rescue URI::InvalidURIError => e
          puts "❌ Invalid image URL: #{mask_url_for_logging(image_url)} - #{e.message}"
          record[current_image_column_name.downcase] = nil
        rescue StandardError => e
          puts "❌ Unexpected error processing image from #{mask_url_for_logging(image_url)}: #{e.message}"
          record[current_image_column_name.downcase] = nil
        end
      end
      record # Return modified record
    end

    # Determin output YAML filename (using the key from sheets_config)
    # safe_filename = filename.to_s.strip.empty? ? sheet_name.downcase.gsub(/\s+/, '_') : filename
    output_path = File.join(DATA_FOLDER, "#{filename_key}.yml")
    File.write(output_path, preprocessed_data.to_yaml)
    puts "✅ Saved '#{filename_key}' data to #{output_path}"

  rescue Google::Apis::ClientError => e
    puts "❌ Google Sheets API error for '#{filename_key}': #{e.message}"
  rescue StandardError => e
    puts "❌ Unexpected error processing '#{filename_key}': #{e.class} - #{e.message}"
  end
end

puts "🎉 All sheets processed and data synchronized!"
