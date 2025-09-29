# frozen_string_literal: true

require 'fileutils'
require 'pathname'

# Colors for terminal output
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def magenta
    colorize(35)
  end

  def cyan
    colorize(36)
  end
end

# Directories to check
PUBLIC_DIR = 'public'
HTML_DIR = File.join(PUBLIC_DIR)
CSS_DIR = File.join(PUBLIC_DIR, 'assets', 'css')
JS_DIR = File.join(PUBLIC_DIR, 'assets', 'js')

# Check if the public directory exists
unless Dir.exist?(PUBLIC_DIR)
  Jekyll.logger.info "❌ #{'Error:'.red} The 'public' directory does not exist. Please run 'make build' first."
  exit(1)
end

# Helper method to check if content is minified
def minified?(content, file_extension)
  case file_extension
  when 'html'
    !content.match(/^\s*$/) # No empty lines
  when 'css'
    !content.match(%r{/\*}) && !content.match(/\s{2,}/) # No comments or multiple spaces
  when 'js'
    !content.match(%r{//}) && !content.match(/\s{2,}/) # No comments or multiple spaces
  else
    false
  end
end

# Helper method to format file size in KB
def format_size_kb(size_bytes)
  (size_bytes.to_f / 1024).round(2)
end

# Helper method to get relative path from current directory
def relative_path_from_pwd(file_path)
  Pathname.new(file_path).relative_path_from(Pathname.new(Dir.pwd)).to_s
end

# Helper method to process and log individual file information
def process_file(file, file_extension)
  size = File.size(file)
  relative_path = relative_path_from_pwd(file)
  content = File.read(file)
  is_minified = minified?(content, file_extension)
  
  status = is_minified ? "#{'✓'.green} Minified" : "#{'✗'.red} Not minified"
  Jekyll.logger.info "  #{relative_path}: #{format_size_kb(size)} KB #{status}"
  
  size
end

# Function to check file sizes
def check_file_sizes(directory, file_extension, description)
  Jekyll.logger.info "\n#{"Checking #{description} files...".cyan}"

  files = Dir.glob(File.join(directory, '**', "*.#{file_extension}"))

  if files.empty?
    Jekyll.logger.info "  #{"No #{file_extension} files found in #{directory}".yellow}"
    return
  end

  total_size = files.sum { |file| process_file(file, file_extension) }
  Jekyll.logger.info "  #{"Total #{description} size:".blue} #{format_size_kb(total_size)} KB"
end

# Check HTML, CSS, and JS files
check_file_sizes(HTML_DIR, 'html', 'HTML')
check_file_sizes(CSS_DIR, 'css', 'CSS')
check_file_sizes(JS_DIR, 'js', 'JavaScript')

Jekyll.logger.info "\n#{'Summary'.magenta}"
Jekyll.logger.info 'To optimize your site further:'
Jekyll.logger.info '1. Make sure all HTML, CSS, and JS files are minified'
Jekyll.logger.info '2. Consider using responsive images'
Jekyll.logger.info '3. Enable gzip compression on your server'
Jekyll.logger.info '4. Use a CDN for static assets'
Jekyll.logger.info '5. Implement lazy loading for images and videos'

Jekyll.logger.info "\n#{'Next steps'.green}"
Jekyll.logger.info "Run 'make build' to rebuild the site with the latest optimizations"
Jekyll.logger.info 'Deploy your site to GitHub Pages using the GitHub workflow'
