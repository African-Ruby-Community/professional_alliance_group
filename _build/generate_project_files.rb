require 'yaml'
require 'fileutils'

# Load data from _data/new_remote/
projects_data_path = '_data/new_remote/projects.yml'
project_contributors_data_path = '_data/new_remote/project_contributors.yml'
relationships_data_path = '_data/relationships.yml'

projects_data = YAML.load_file(projects_data_path)
project_contributors_data = YAML.load_file(project_contributors_data_path)
relationships_data = YAML.load_file(relationships_data_path) || {}

# Ensure _projects directory exists
projects_dir = '_projects'
FileUtils.mkdir_p(projects_dir)

# Process each project
projects_data.each do |project|
  # Extract the slug from the permalink
  # Permalink format is "/projects/project1" -> slug should be "project1"
  slug = project['permalink'].split('/').last

  # Create the project file path
  project_file_path = File.join(projects_dir, "#{slug}.md")

  # Find contributors to this project
  contributors = []
  project_contributors_data.each do |contributor|
    if contributor['project_permalink'] == project['permalink']
      contributors << contributor['member_permalink']
    end
  end

  # Find groups associated with this project
  groups = []
  relationships_data.each do |group_slug, group_data|
    if group_data && group_data['projects'] && group_data['projects'].include?(slug)
      groups << "/groups/#{group_slug}"
    end
  end

  # Create the front matter content
  front_matter = <<~FRONT_MATTER
  ---
  layout: project
  name: #{project['name']}
  bio: #{project['bio']}
  details: #{project['details']}
  image: #{project['image']}
  twitter: #{project['twitter']}
  website: #{project['website']}
  linkedin: #{project['linkedin']}
  permalink: #{project['permalink']}
  contributors: #{contributors}
  groups: #{groups}
  ---
  FRONT_MATTER

  # Write the front matter to the file
  File.write(project_file_path, front_matter)

  puts "Created project file: #{project_file_path}"
end

puts "All project files generated successfully!"