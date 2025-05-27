require "google/apis/sheets_v4"
require "googleauth"
require "json"
require 'fileutils'
require 'dotenv'

Dotenv.load if File.exist?('.env') # Load .env variables

# Folder to store remote sheet data
DATA_FOLDER = "_data/new_remote"
FileUtils.mkdir_p(DATA_FOLDER)

# Path to your service account JSON file
CREDENTIALS_PATH = ENV['CREDENTIALS_PATH'] || "./service_acc.json"
SERVICE_ACCOUNT_JSON = ENV['SERVICE_ACCOUNT_JSON']
APPLICATION_NAME = ENV['APPLICATION_NAME'] || 'GoogleSheetsSync'
SPREADSHEET_ID = ENV['SPREADSHEET_ID']
SHEETS = eval(ENV['SHEETS'])

# Authorization Function
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

# Initialize Sheets API
service = Google::Apis::SheetsV4::SheetsService.new
service.authorization = authorize_google_sheets(CREDENTIALS_PATH, SERVICE_ACCOUNT_JSON)

SHEETS.each do |sheet|
  response = service.get_spreadsheet_values(SPREADSHEET_ID, sheet)

  # Convert to JSON
  values = response.values
  headers = values.first
  data = values[1..-1].map { |row| headers.zip(row).to_h }

  data.each do |item|
    next if item['image'].nil? # Skip if there is no image url
    gdrive_link = item['image']
    extract = gdrive_link.scan(/https:\/\/drive.google.com\/file\/d\/(.*)\/view/)

    next unless extract.count > 0 # Skip if Grive link format is not correct
    gdrive_file_id = extract&.first&.first

    next if gdrive_file_id.nil? # Skip if id is nil
    item['image'] = "https://lh3.googleusercontent.com/d/#{gdrive_file_id}=w1000?authuser=1/view"
  end

  # Save data to a json data file
  File.write("#{DATA_FOLDER}/#{sheet}.json", JSON.pretty_generate(data))
end
