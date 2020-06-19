require 'erb'
require 'fileutils'

alerts = { 'services' => 'alerting/fb_services.yml.erb',
           'platform' => 'alerting/fb_platform.yml.erb',
           'publisher' => 'alerting/fb_publisher.yml.erb' }

alert = alerts[ARGV[0]]
platform_env = ARGV[1] # %w{ pentest test live }
deployment_env = ARGV[2] # %w{ dev production }
severity = 'form-builder-low-severity'
out_path = './out.yml'

raise ArgumentError.new('Please provide namespace/alerts') if alert.nil?
raise ArgumentError.new('Please provide platform environment') if platform_env.nil?
raise ArgumentError.new('Please provide deployment environment') if deployment_env.nil? && (ARGV[0] != 'publisher')

FileUtils.rm(out_path, force: true)

File.open(out_path, 'w') do |f|
  env_string = "#{platform_env}-#{deployment_env}"
  severity = 'form-builder' if env_string == 'live-production'
  string = File.read(alert)
  template = ERB.new(string)
  f.write template.result(binding)
  f.write "---\n"
end

`kubectl apply -f #{out_path}`

if $?.success?
  puts "Successfully applied changes for #{alert} to #{platform_env} #{deployment_env}"
else
  puts "🔥🔥🔥🔥🔥🔥\n\n"
  puts "Unable to apply changes for #{alert} to #{platform_env} #{deployment_env}"
  puts "\n\n🔥🔥🔥🔥🔥🔥"
end

FileUtils.rm(out_path, force: true)
