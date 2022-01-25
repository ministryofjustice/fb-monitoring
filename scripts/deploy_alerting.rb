require 'erb'
require 'fileutils'

alerts = {
  'services' => 'alerting/fb_services.yml.erb',
  'platform' => 'alerting/fb_platform.yml.erb',
  'publisher' => 'alerting/fb_publisher.yml.erb',
  'hmcts_complaints_adapter' => 'alerting/fb_hmcts_adapter.yml.erb'
}

alert = alerts[ARGV[0]]
platform_env = ARGV[1] # %w{ test live staging production }
deployment_env = ARGV[2] # %w{ dev production }
severity = 'form-builder-low-severity'
400s_severity = 'form-builder-low-severity'
out_path = './out.yml'

raise ArgumentError.new('Please provide namespace/alerts') if alert.nil?
raise ArgumentError.new('Please provide platform environment') if platform_env.nil?
if deployment_env.nil? && !(%w(publisher hmcts_complaints_adapter).include?(ARGV[0]))
  raise ArgumentError.new('Please provide deployment environment')
end
if %w(publisher hmcts_complaints_adapter).include?(ARGV[0]) && deployment_env
  raise ArgumentError.new("#{ARGV[0]} does not require a deployment environment")
end

FileUtils.rm(out_path, force: true)

File.open(out_path, 'w') do |f|
  if %w(publisher hmcts_complaints_adapter).include?(ARGV[0])
    env_string = platform_env
  else
    env_string = "#{platform_env}-#{deployment_env}"
  end
  puts "Environment string => #{env_string}"

  if ARGV[0] == 'services' && env_string == 'live-production'
    400s_severity = 'form-builder-400s' # 400s specific channel for live production only
  elsif %w(live-production live production).include?(env_string)
    severity = 'form-builder' # high severity alerts channel
  end
  puts "Severity => #{severity}"
  puts "400s Severity => #{400s_severity}"

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
