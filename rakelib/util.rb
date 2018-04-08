$jekyll_config_semaphore = Mutex.new
def jekyll_config
  $jekyll_config_semaphore.synchronize do
    break @config if @config

    opts = {}
    opts['config'] = ENV['JEKYLL_CONFIG'] if ENV.key? 'JEKYLL_CONFIG'

    Jekyll.logger.log_level = :warn
    @config = Jekyll.configuration opts
    Jekyll.logger.log_level = :info

    @config
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
