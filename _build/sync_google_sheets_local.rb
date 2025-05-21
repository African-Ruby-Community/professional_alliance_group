require 'google/apis/sheets_v4'
require 'googleauth'
require 'yaml'
require 'fileutils'
require 'open-uri'
require 'uri'
require_relative './env_helper'

puts "Starting Google Sheets sync with image download..."
load_env_if_available

puts "SHEET1_FILENAME: #{ENV['SHEET1_FILENAME']}"
puts "SHEET1_NAME: #{ENV['SHEET1_NAME']}"
puts "SHEET2_FILENAME: #{ENV['SHEET2_FILENAME']}"
puts "SHEET2_NAME: #{ENV['SHEET2_NAME']}"
puts "IMAGE_COLUMN_NAME: #{ENV['IMAGE_COLUMN_NAME']}" # Ensure this is loaded

# --- Configuration ---
DATA_FOLDER = "_data/new_remote"
IMAGE_OUTPUT_DIR = "assets/img/remote_images" # Directory to store downloaded images
FileUtils.mkdir_p(DATA_FOLDER)
FileUtils.mkdir_p(IMAGE_OUTPUT_DIR)

CREDENTIALS_PATH = ENV['CREDENTIALS_PATH'] || "../service_acc.json"
APPLICATION_NAME = ENV['APPLICATION_NAME'] || 'GoogleSheetsSync'
SPREADSHEET_ID = ENV['SPREADSHEET_ID']
IMAGE_COLUMN_NAME = ENV['IMAGE_COLUMN_NAME'] || 'photo' # Default to 'photo' if not set

# Sheet configurations
sheets_config = {}
1.upto(10) do |i| # Assuming you might have up to 10 sheets configured
  filename_env = ENV["SHEET#{i}_FILENAME"]
  name_env = ENV["SHEET#{i}_NAME"]
  if filename_env && name_env
    sheets_config[filename_env] = name_env
  end
end

if sheets_config.empty?
  puts "⚠️ No valid sheets configured. Please set SHEET1_FILENAME and corresponding SHEET1_NAME (and so on) in .env"
  exit(1)
end

SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

# --- Authorization Function ---
def authorize
  begin
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(CREDENTIALS_PATH),
      scope: SCOPE
    )
  rescue Errno::ENOENT
    puts "❌ Error: Credentials file not found at #{CREDENTIALS_PATH}."
    puts "  Please ensure the file exists or set the CREDENTIALS_PATH environment variable."
    exit(1)
  rescue Google::Auth::CredentialsError => e
    puts "❌ Error creating credentials: #{e.message}"
    exit(1)
  end
end

# --- Initialize Google Sheets API ---
sheets_service = Google::Apis::SheetsV4::SheetsService.new
sheets_service.client_options.application_name = APPLICATION_NAME
sheets_service.authorization = authorize

# --- Helper function to sanitize filenames ---
def sanitize_filename(filename)
  filename.downcase.gsub(/\s+/, '_').gsub(/[^a-z0-9_.-]/, '')
end

# --- Fetch and Process Each Sheet ---
sheets_config.each do |filename, sheet_name|
  puts "📥 Fetching '#{filename}' from sheet '#{sheet_name}'..."

  begin
    response = sheets_service.get_spreadsheet_values(SPREADSHEET_ID, sheet_name)
    values = response.values

    if values.nil? || values.empty?
      puts "⚠️ No data found for '#{filename}'. Skipping..."
      next
    end

    headers = values.shift.map(&:downcase) # Downcase headers for case-insensitive matching
    unless headers
      puts "⚠️ Missing headers in sheet '#{sheet_name}'. Skipping..."
      next
    end

    image_column_index = headers.index(IMAGE_COLUMN_NAME.downcase)

    data = values.map do |row|
      record = headers.zip(row + [nil] * (headers.size - row.size)).to_h
      if image_column_index && record[IMAGE_COLUMN_NAME.downcase]
        image_url = record[IMAGE_COLUMN_NAME.downcase]
        begin
          puts "⬇️ Downloading image from: #{image_url}"
          uri = URI.parse(image_url)
          file_extension = File.extname(uri.path).downcase
          base_name = record['user_name'] || sanitize_filename(File.basename(uri.path, '.*')) || "image_#{Time.now.to_i}"
          sanitized_name = sanitize_filename(base_name)
          local_image_name = "#{sanitized_name}#{file_extension}"
          local_image_path = File.join(IMAGE_OUTPUT_DIR, local_image_name)

          URI.open(image_url) do |image_file|
            File.open(local_image_path, 'wb') do |file|
              IO.copy_stream(image_file, file)
            end
          end
          record[IMAGE_COLUMN_NAME.downcase] = "/#{local_image_path}" # Store relative path
          puts "✅ Image saved to: #{local_image_path}"
        rescue OpenURI::HTTPError => e
          puts "❌ Error downloading image from #{image_url}: #{e.message}"
          record[IMAGE_COLUMN_NAME.downcase] = nil # Or handle error as needed
        rescue URI::InvalidURIError => e
          puts "❌ Invalid image URL: #{image_url} - #{e.message}"
          record[IMAGE_COLUMN_NAME.downcase] = nil
        rescue StandardError => e
          puts "❌ Unexpected error processing image from #{image_url}: #{e.message}"
          record[IMAGE_COLUMN_NAME.downcase] = nil
        end
      end
      record
    end

    safe_filename = filename.to_s.strip.empty? ? sheet_name.downcase.gsub(/\s+/, '_') : filename
    output_path = File.join(DATA_FOLDER, "#{safe_filename}.yml")
    File.write(output_path, data.to_yaml)
    puts "✅ Saved '#{filename}' data to #{output_path}"

  rescue Google::Apis::ClientError => e
    puts "❌ Google Sheets API error for '#{filename}': #{e.message}"
  rescue StandardError => e
    puts "❌ Unexpected error processing '#{filename}': #{e.class} - #{e.message}"
  end
end

puts "🎉 All sheets processed!"
