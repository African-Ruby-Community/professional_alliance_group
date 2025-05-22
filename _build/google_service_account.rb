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
APPLICATION_NAME = ENV['APPLICATION_NAME'] || 'GoogleSheetsSync'
SPREADSHEET_ID = ENV['SPREADSHEET_ID']
SHEETS = eval(ENV['SHEETS'])

# Authorize with service account
scope = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(CREDENTIALS_PATH),
  scope: scope
)
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

  File.write("#{DATA_FOLDER}/#{sheet}.json", JSON.pretty_generate(data))
end
