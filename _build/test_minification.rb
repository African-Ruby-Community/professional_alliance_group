require 'fileutils'
require 'pathname'

# Colors for terminal output
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red; colorize(31) end
  def green; colorize(32) end
  def yellow; colorize(33) end
  def blue; colorize(34) end
  def magenta; colorize(35) end
  def cyan; colorize(36) end
end

# Directories to check
PUBLIC_DIR = "public"
HTML_DIR = File.join(PUBLIC_DIR)
CSS_DIR = File.join(PUBLIC_DIR, "assets", "css")
JS_DIR = File.join(PUBLIC_DIR, "assets", "js")

# Check if the public directory exists
unless Dir.exist?(PUBLIC_DIR)
  puts "❌ #{"Error:".red} The 'public' directory does not exist. Please run 'make build' first."
  exit(1)
end

# Function to check file sizes
def check_file_sizes(directory, file_extension, description)
  puts "\n#{"Checking #{description} files...".cyan}"
  
  # Find all files with the given extension
  files = Dir.glob(File.join(directory, "**", "*.#{file_extension}"))
  
  if files.empty?
    puts "  #{"No #{file_extension} files found in #{directory}".yellow}"
    return
  end
  
  total_size = 0
  files.each do |file|
    size = File.size(file)
    total_size += size
    relative_path = Pathname.new(file).relative_path_from(Pathname.new(Dir.pwd)).to_s
    
    # Check for minification indicators
    content = File.read(file)
    is_minified = case file_extension
                  when "html"
                    !content.match(/^\s*$/)  # No empty lines
                  when "css"
                    !content.match(/\/\*/) && !content.match(/\s{2,}/)  # No comments or multiple spaces
                  when "js"
                    !content.match(/\/\//) && !content.match(/\s{2,}/)  # No comments or multiple spaces
                  else
                    false
                  end
    
    status = is_minified ? "#{"✓".green} Minified" : "#{"✗".red} Not minified"
    puts "  #{relative_path}: #{(size.to_f / 1024).round(2)} KB #{status}"
  end
  
  puts "  #{"Total #{description} size:".blue} #{(total_size.to_f / 1024).round(2)} KB"
end

# Check HTML, CSS, and JS files
check_file_sizes(HTML_DIR, "html", "HTML")
check_file_sizes(CSS_DIR, "css", "CSS")
check_file_sizes(JS_DIR, "js", "JavaScript")

puts "\n#{"Summary".magenta}"
puts "To optimize your site further:"
puts "1. Make sure all HTML, CSS, and JS files are minified"
puts "2. Consider using responsive images"
puts "3. Enable gzip compression on your server"
puts "4. Use a CDN for static assets"
puts "5. Implement lazy loading for images and videos"

puts "\n#{"Next steps".green}"
puts "Run 'make build' to rebuild the site with the latest optimizations"
puts "Deploy your site to GitHub Pages using the GitHub workflow"