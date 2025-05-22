require 'yaml'
require 'fileutils'

# Load data from _data/new_remote/
groups_data_path = '_data/new_remote/groups.yml'
projects_data_path = '_data/new_remote/projects.yml'
project_contributors_data_path = '_data/new_remote/project_contributors.yml'
relationships_data_path = '_data/relationships.yml'

groups_data = YAML.load_file(groups_data_path)
projects_data = YAML.load_file(projects_data_path)
project_contributors_data = YAML.load_file(project_contributors_data_path)
relationships_data = YAML.load_file(relationships_data_path) || {}

# Ensure _groups directory exists
groups_dir = '_groups'
FileUtils.mkdir_p(groups_dir)

# Process each group
groups_data.each do |group|
  # Extract the slug from the permalink
  # Permalink format is "/groups/group1" -> slug should be "group1"
  slug = group['permalink'].split('/').last

  # Create the group file path
  group_file_path = File.join(groups_dir, "#{slug}.md")

  # Get members and projects for this group from relationships.yml
  members = []
  projects = []

  if relationships_data[slug]
    if relationships_data[slug]['members']
      members = relationships_data[slug]['members'].map { |member_slug| "/members/#{member_slug}" }
    end

    if relationships_data[slug]['projects']
      projects = relationships_data[slug]['projects'].map { |project_slug| "/projects/#{project_slug}" }
    end
  end

  # Create the front matter content
  front_matter = <<~FRONT_MATTER
  ---
  layout: groups
  name: #{group['name']}
  bio: #{group['bio']}
  details: #{group['details']}
  short_description: #{group['bio']}
  long_description: #{group['details']}
  image: #{group['image']}
  twitter: #{group['twitter']}
  website: #{group['website']}
  linkedin: #{group['linkedin']}
  permalink: #{group['permalink']}
  members: #{members}
  projects: #{projects}
  ---
  FRONT_MATTER

  # Write the front matter to the file
  File.write(group_file_path, front_matter)

  puts "Created group file: #{group_file_path}"
end

puts "All group files generated successfully!"
