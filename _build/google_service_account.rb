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
SERVICE_ACCOUNT_JSON = ENV["SERVICE_ACCOUNT_JSON"]
APPLICATION_NAME = ENV['APPLICATION_NAME'] || 'GoogleSheetsSync'
SPREADSHEET_ID = ENV['SPREADSHEET_ID']
SHEETS = eval(ENV['SHEETS'])
SCOPE = ["https://www.googleapis.com/auth/spreadsheets.readonly"]

# Authorize with service account
# Define the scope for Google Sheets API

def authorize_google_sheets(path, json_string)
  cred_io = if json_string && !json_string.empty?
              puts "Using service account"
              StringIO.new(json_string)
            elsif path && File.exist?(path)
              puts "Developing locally"
              File.open(path)
            else
              abort "No valid credentials."
            end

  Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: cred_io,
    scope: SCOPE
  ).tap(&:fetch_access_token!)
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

  # Preload members index if this sheet requires collaborator resolution
  members_by_number = nil
  if sheet.to_s.downcase == 'collaborators' || sheet.to_s.downcase == 'collaborations'
    members_path = File.join(DATA_FOLDER, 'members.json')
    if File.exist?(members_path)
      begin
        members_data = JSON.parse(File.read(members_path))
        members_by_number = members_data.each_with_object({}) do |member, index|
          index[member['Member Number']] = member
        end
      rescue StandardError => e
        warn "Failed to load members.json for collaborator mapping: #{e.message}"
      end
    end
  end

  data.each do |item|
    # Process Google Drive image URL if present
    if item['Image URL'] && !item['Image URL'].to_s.strip.empty?
      gdrive_link = item['Image URL']
      extract = gdrive_link.scan(/https:\/\/drive.google.com\/file\/d\/(.*)\/view/)

      if extract.count > 0
        gdrive_file_id = extract&.first&.first
        if gdrive_file_id
          item['Image URL'] = "https://lh3.googleusercontent.com/d/#{gdrive_file_id}=w1000?authuser=1/view"
        end
      end
    end

    # Generate permalink for members if Full Name present (directory-style, no .html)
    if item['Full Name'] && !item['Full Name'].to_s.empty?
      slug = item['Full Name']&.downcase&.squeeze&.split&.join('-')
      item['permalink'] = "/members/#{slug}/"
    end

    # Map collaborators codes to member objects for collaborations sheet
    if members_by_number && item['Collaborators'] && !item['Collaborators'].to_s.strip.empty?
      codes = item['Collaborators'].split(',').map { |c| c.strip }
      item['collaborators'] = codes.map { |code| members_by_number[code] }.compact
    end
  end

  # Save data to a json data file
  File.write("#{DATA_FOLDER}/#{sheet}.json", JSON.pretty_generate(data))
end
