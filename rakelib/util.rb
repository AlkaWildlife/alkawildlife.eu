require 'pathname'
require 'yaml'

def jekyll_config_files
  return [] unless ENV.key? 'JEKYLL_LANG'

  ['_config.yml', Pathname.new(ENV['JEKYLL_LANG']).join('_config.yml').to_s]
end

$jekyll_config_semaphore = Mutex.new
def jekyll_config
  $jekyll_config_semaphore.synchronize do
    break @jekyll_config if @jekyll_config

    opts = {}
    opts['config'] = jekyll_config_files unless jekyll_config_files.empty?

    Jekyll.logger.log_level = :warn
    @jekyll_config = Jekyll.configuration opts
    Jekyll.logger.log_level = :info

    @jekyll_config
  end
end

def asset_subdir asset
  case asset
  when /\.js(?:\.map)?$/
    'javascripts'
  when /\.css(?:\.map)?$/
    'stylesheets'
  else
    fail "Unexpected type of asset #{asset}. Only JS and CSS both with optional Source Maps are supported."
  end
end

$cms_config_semaphore = Mutex.new
def cms_config
  $cms_config_semaphore.synchronize do
    break @cms_config if @cms_config

    begin
      cms_config_file = Pathname.new(jekyll_config['source']).
                          join('admin', 'config.yml').
                          to_s
      @cms_config = YAML.load File.read cms_config_file
    rescue Errno::ENOENT
      @cms_config = nil
    end
  end
end
