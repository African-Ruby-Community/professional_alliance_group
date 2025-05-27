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

# Authorize with service account
# Define the scope for Google Sheets API
scope = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
authorizer = if SERVICE_ACCOUNT_JSON && !SERVICE_ACCOUNT_JSON.empty?
               Google::Auth::ServiceAccountCredentials.make_creds(
                 json_key_io: File.open(CREDENTIALS_PATH),
                 scope: scope
               )
             else
               Google::Auth::ServiceAccountCredentials.make_creds(
                 json_key_io: File.open(CREDENTIALS_PATH),
                 scope: scope
               )
             end
authorizer.fetch_access_token!

# Initialize Sheets API
service = Google::Apis::SheetsV4::SheetsService.new
service.authorization = authorizer

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
