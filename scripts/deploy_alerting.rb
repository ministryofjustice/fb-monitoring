require 'erb'
require 'fileutils'

alerts = { 'services' => 'alerting/fb_services.yml.erb',
           'platform' => 'alerting/fb_platform.yml.erb',
           'publisher' => 'alerting/fb_publisher.yml.erb' }

alert = alerts[ARGV[0]]
platform_env = ARGV[1] # %w{ test live }
deployment_env = ARGV[2] # %w{ dev production }
severity = 'form-builder-low-severity'
out_path = './out.yml'

raise ArgumentError.new('Please provide namespace/alerts') if alert.nil?
raise ArgumentError.new('Please provide platform environment') if platform_env.nil?
raise ArgumentError.new('Please provide deployment environment') if deployment_env.nil? && (ARGV[0] != 'publisher')
raise ArgumentError.new('Publisher does not require a deployment environment') if ARGV[0] == 'publisher' && deployment_env

FileUtils.rm(out_path, force: true)

File.open(out_path, 'w') do |f|
  env_string = ARGV[0] == 'publisher' ? platform_env : "#{platform_env}-#{deployment_env}"
  puts "Environment string => #{env_string}"

  severity = 'form-builder' if %w(live-production live).include?(env_string)
  puts "Severity => #{severity}"

  string = File.read(alert)
  template = ERB.new(string)
  f.write template.result(binding)
  f.write "---\n"
end

puts "Applying monitoring config for #{ARGV[0]}"
`kubectl apply -f #{out_path}`

if $?.success?
  puts "Successfully applied changes for #{alert} to #{platform_env} #{deployment_env}"
else
  raise StandardError.new("Unable to apply changes for #{alert} to #{platform_env} #{deployment_env}")
end

FileUtils.rm(out_path, force: true)
