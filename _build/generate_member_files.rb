require 'yaml'
require 'fileutils'

# Load member data from _data/new_remote/members.yml
members_data_path = '_data/new_remote/members.yml'
project_contributors_data_path = '_data/new_remote/project_contributors.yml'
relationships_data_path = '_data/relationships.yml'

members_data = YAML.load_file(members_data_path)
project_contributors_data = YAML.load_file(project_contributors_data_path)
relationships_data = YAML.load_file(relationships_data_path) || {}

# Ensure _members directory exists
members_dir = '_members'
FileUtils.mkdir_p(members_dir)

# Process each member
members_data.each do |member|
  # Extract the slug from the permalink
  # Permalink format is "/members/alice" -> slug should be "alice"
  slug = member['permalink'].split('/').last

  # Create the member file path
  member_file_path = File.join(members_dir, "#{slug}.md")

  # Find groups this member belongs to
  groups = []
  relationships_data.each do |group_slug, group_data|
    if group_data && group_data['members'] && group_data['members'].include?(slug)
      groups << "/groups/#{group_slug}"
    end
  end

  # Find projects this member contributes to
  projects = []
  project_contributors_data.each do |contributor|
    if contributor['member_permalink'] == member['permalink']
      projects << contributor['project_permalink']
    end
  end

  # Create the front matter content
  front_matter = <<~FRONT_MATTER
  ---
  layout: member
  name: #{member['name']}
  bio: #{member['bio']}
  details: #{member['details']}
  image: #{member['image']}
  twitter: #{member['twitter']}
  website: #{member['website']}
  linkedin: #{member['linkedin']}
  permalink: #{member['permalink']}
  groups: #{groups}
  projects: #{projects}
  ---
  FRONT_MATTER

  # Write the front matter to the file
  File.write(member_file_path, front_matter)

  puts "Created member file: #{member_file_path}"
end

puts "All member files generated successfully!"
