# frozen_string_literal: true

require 'google/apis/sheets_v4'
require 'googleauth'
require 'json'
require 'fileutils'
require 'dotenv'

Dotenv.load if File.exist?('.env') # Load .env variables

# Folder to store remote sheet data
DATA_FOLDER = '_data/new_remote'
FileUtils.mkdir_p(DATA_FOLDER)

# Path to your service account JSON file
CREDENTIALS_PATH = ENV.fetch('CREDENTIALS_PATH', './service_acc.json')
SERVICE_ACCOUNT_JSON = ENV.fetch('SERVICE_ACCOUNT_JSON', nil)
APPLICATION_NAME = ENV.fetch('APPLICATION_NAME', 'GoogleSheetsSync')
SPREADSHEET_ID = ENV.fetch('SPREADSHEET_ID', nil)
SHEETS = ENV.fetch('SHEETS', nil)
SCOPE = ['https://www.googleapis.com/auth/spreadsheets.readonly'].freeze

# Authorize with service account
# Define the scope for Google Sheets API

def authorize_google_sheets(path, json_string)
  cred_io = if json_string && !json_string.empty?
              Jekyll.logger.info 'GoogleServiceAccount:', 'Using service account'
              StringIO.new(json_string)
            elsif path && File.exist?(path)
              Jekyll.logger.info 'GoogleServiceAccount:', 'Developing locally'
              File.open(path)
            else
              abort 'No valid credentials.'
            end

  Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: cred_io,
    scope: SCOPE
  ).tap(&:fetch_access_token!)
end

def load_members_index
  members_path = File.join(DATA_FOLDER, 'members.json')
  return nil unless File.exist?(members_path)

  begin
    members_data = JSON.parse(File.read(members_path))
    members_data.each_with_object({}) do |member, index|
      index[member['Member Number']] = member
    end
  rescue StandardError => e
    warn "Failed to load members.json for collaborator mapping: #{e.message}"
    nil
  end
end

def process_google_drive_image_url(item)
  return unless item['Image URL'] && !item['Image URL'].to_s.strip.empty?

  gdrive_link = item['Image URL']
  extract = gdrive_link.scan(%r{https://drive.google.com/file/d/(.*)/view/})

  return unless extract.count.positive?

  gdrive_file_id = extract&.first&.first
  return unless gdrive_file_id

  item['Image URL'] = "https://lh3.googleusercontent.com/d/#{gdrive_file_id}=w1000?authuser=1/view"
end

def generate_member_permalink(item)
  return unless item['Full Name'] && !item['Full Name'].to_s.empty?

  slug = item['Full Name']&.downcase&.squeeze&.split&.join('-')
  item['permalink'] = "/members/#{slug}/"
end

def map_collaborators(item, members_by_number)
  return unless members_by_number && item['Collaborators'] && !item['Collaborators'].to_s.strip.empty?

  codes = item['Collaborators'].split(',').map(&:strip)
  item['collaborators'] = codes.map { |code| members_by_number[code] }.compact
end

def process_sheet_data(data, members_by_number)
  data.each do |item|
    process_google_drive_image_url(item)
    generate_member_permalink(item)
    map_collaborators(item, members_by_number)
  end
end

def requires_collaborator_resolution?(sheet)
  sheet.to_s.downcase == 'collaborators' || sheet.to_s.downcase == 'collaborations'
end

# Initialize Sheets API
service = Google::Apis::SheetsV4::SheetsService.new
service.authorization = authorize_google_sheets(CREDENTIALS_PATH, SERVICE_ACCOUNT_JSON)

SHEETS.each do |sheet|
  response = service.get_spreadsheet_values(SPREADSHEET_ID, sheet)

  # Convert to JSON
  values = response.values
  headers = values.first
  data = values[1..].map { |row| headers.zip(row).to_h }

  # Preload members index if this sheet requires collaborator resolution
  members_by_number = requires_collaborator_resolution?(sheet) ? load_members_index : nil

  process_sheet_data(data, members_by_number)

  # Save data to a json data file
  File.write("#{DATA_FOLDER}/#{sheet}.json", JSON.pretty_generate(data))
end
