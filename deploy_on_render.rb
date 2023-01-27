#!/usr/bin/env ruby


# Functions
def replace(path, o, r)
  text = File.read(path)
  new_text = text.gsub(o, r)
  File.open(path, "w") {|file| file.puts new_text }
end

def create(path, r)
  if File.file?(path)
    puts "#{path} exists, deleting and creating new one..."
    system("rm #{path}")
    system("touch #{path}")
    replace(path, "", r)
    return true
  else
    puts "creating #{path}"
    system("touch #{path}")
    replace(path, "", r)
    return true
  end
end

# Commit/Push
def git_commit_push
  puts 'Would you like to commit and push? [y/n]'.yellow
  answer = gets.chomp
  case answer
    when "n"
    else system("git add . && git commit -m 'commit for render' && git push")
  end
end

# Remote Create
def git_remote_create
  puts 'Would you like to create a remote repository? [y/n]'.yellow
  answer = gets.chomp
  case answer
    when "n"
    else system("gh repo create")
  end
end

# Open Render/blueprints
def open_render
  puts 'Would you like to open Render? [y/n]'.yellow
  answer = gets.chomp
  case answer
    when "n"
    else system("open 'https://dashboard.render.com/blueprints'")
  end
end

# colorize
class String
  # colorization
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

end


puts 'Starting...'.yellow
# gets App name from directory
app_name = %x(basename $(pwd)).chop

# Change database.yml
filepath = "config/database.yml"
og = "production:
  <<: *default
  database: #{app_name}_production
  username: #{app_name}
  password: <%= ENV[\"#{app_name.upcase}_DATABASE_PASSWORD\"] %>"

replacement = "production:
  <<: *default
  url: <%= ENV[\"DATABASE_URL\"] %>
  database: #{app_name}_production
  username: #{app_name}
  password: <%= ENV[\"RENDER_DEPLOY_DATABASE_PASSWORD\"] %>"

replace(filepath, og, replacement)
puts "changed database.yml"

# Change puma.rb
filepath = "config/puma.rb"
og = "# workers ENV.fetch(\"WEB_CONCURRENCY\") { 2 }"
replacement = "workers ENV.fetch(\"WEB_CONCURRENCY\") { 4 }"
replace(filepath, og, replacement)
og = "# preload_app!"
replacement = "preload_app!"
replace(filepath, og, replacement)
puts "changed puma.rb"

# change config/environments/production.rb
filepath = "config/environments/production.rb"
og = "config.public_file_server.enabled = ENV[\"RAILS_SERVE_STATIC_FILES\"].present?"
replacement = "config.public_file_server.enabled = ENV[\"RAILS_SERVE_STATIC_FILES\"].present? || ENV['RENDER'].present?"
replace(filepath, og, replacement)
puts "changed production.rb"


# create render-build.sh
str = '
#!/usr/bin/env bash
# exit on error
set -o errexit
bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
'
filepath = "bin/render-build.sh"
system("chmod a+x bin/render-build.sh") if create(filepath, str)


# Create render.yaml
str = "
databases:
  - name: postgres_#{app_name}
    plan: free
    ipAllowList: []

services:
  - type: web
    name: #{app_name}
    plan: free
    env: ruby
    buildCommand: './bin/render-build.sh'
    startCommand: bundle exec rails s
    envVars:
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: postgres_#{app_name}
          property: connectionString
  - type: redis
    name: redis_#{app_name}
    ipAllowList: []
    plan: free
    maxmemoryPolicy: noeviction
"
filepath="render.yaml"
create(filepath, str)
puts ".........".green
puts "
Tasks done for your app: #{app_name}
".green
puts ".........".green


# Test if remote exists
if system("git ls-remote origin -q")
  git_commit_push
  open_render
else
  puts ".........".red
  puts 'Remote repository does not exist!'.red
  puts ".........".red
  git_remote_create
end
