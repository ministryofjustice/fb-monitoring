require 'erb'
require 'fileutils'
require 'yaml'

RESOURCE_CONFIG_PATH = 'config/resource_config.yml'.freeze

RESOURCE_CONFIG = YAML.load_file(
  RESOURCE_CONFIG_PATH,
  permitted_classes: [],
  permitted_symbols: [],
  aliases: false
).freeze

PROMETHEUS_RULES = {
  'saas' => 'alerting/fb_saas.yml.erb',
  'saas.rds' => 'alerting/fb_saas_rds.yml.erb',
  'services' => 'alerting/fb_services.yml.erb',
  'platform' => 'alerting/fb_platform.yml.erb',
  'platform.rds' => 'alerting/fb_platform_rds.yml.erb'
}.freeze

OUTPUT_PATH = './out.yml'.freeze
LOW_SEVERITY = 'form-builder-low-severity'.freeze
HIGH_SEVERITY = 'form-builder'.freeze
FOUR_HUNDREDS_SEVERITY = 'form-builder-400s'.freeze # 400s specific channel for live production only
NO_DEPLOYMENT_ENV_REQUIRED = %w[saas].freeze
HIGH_SEVERITY_ENVIRONMENTS = %w[
  live-production
  live
  production
].freeze

alert = ARGV[0] # %w{ saas saas.rds services platform platform.rds}
destination = alert.split('.')[0] # %w{ saas services platform }
platform_env = ARGV[1] # %w{ test live staging production }
deployment_env = ARGV[2] # %w{ dev production }
prometheus_rules_path = PROMETHEUS_RULES[alert]

raise ArgumentError, 'Please provide namespace/alert' if prometheus_rules_path.nil?
raise ArgumentError, 'Please provide platform environment' if platform_env.nil?
if deployment_env.nil? && !NO_DEPLOYMENT_ENV_REQUIRED.include?(destination)
  raise ArgumentError, 'Please provide deployment environment'
end
if NO_DEPLOYMENT_ENV_REQUIRED.include?(destination) && deployment_env
  raise ArgumentError, "#{destination} does not require a deployment environment"
end

FileUtils.rm(OUTPUT_PATH, force: true)

File.open(OUTPUT_PATH, 'w') do |f|
  env_string = NO_DEPLOYMENT_ENV_REQUIRED.include?(destination) ? platform_env : "#{platform_env}-#{deployment_env}"

  puts "Destination => #{destination}"
  puts "Environment string => #{env_string}"
  puts "Resource Config => #{RESOURCE_CONFIG["#{destination}-#{env_string}"]}"

  four_hundreds_severity = (destination == 'services' && env_string == 'live-production') || (destination == 'saas' && env_string == 'live') ? FOUR_HUNDREDS_SEVERITY : LOW_SEVERITY
  severity = HIGH_SEVERITY_ENVIRONMENTS.include?(env_string) ? HIGH_SEVERITY : LOW_SEVERITY

  puts "Severity => #{severity}"
  puts "400s Severity => #{four_hundreds_severity}"

  string = File.read(prometheus_rules_path)
  template = ERB.new(string)
  f.write template.result(binding)
  f.write "---\n"
end

puts "Applying monitoring config for #{destination}"
`kubectl apply -f #{OUTPUT_PATH}`

if $?.success?
  puts "Successfully applied changes for #{destination}(#{prometheus_rules_path}) to #{platform_env} #{deployment_env}"
else
  raise StandardError, "Unable to apply changes for #{destination}(#{prometheus_rules_path}) to #{platform_env} #{deployment_env}"
end

FileUtils.rm(OUTPUT_PATH, force: true)
