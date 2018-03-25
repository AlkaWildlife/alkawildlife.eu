require 'rake/clean'
require 'jekyll'

desc "Build this site\n" +
     "\n" +
     "Custom Jekyll config can be specified by JEKYLL_CONFIG environment\n" +
     "variable."
task build: %w[build:cms build:jekyll]

namespace "build" do
  def jekyll_config
    return @config if @config

    opts = {}
    opts['config'] = ENV['JEKYLL_CONFIG'] if ENV.key? 'JEKYLL_CONFIG'

    Jekyll.logger.log_level = :warn
    @config = Jekyll.configuration opts
    Jekyll.logger.log_level = :info

    @config
  end

  CMS_SOURCES = FileList[
    "node_modules/netlify-cms/dist/cms.js",
    "node_modules/netlify-cms/dist/cms.js.map",
    "node_modules/netlify-cms/dist/cms.css",
    "node_modules/netlify-identity-widget/build/netlify-identity-widget.js",
    "node_modules/netlify-identity-widget/build/netlify-identity-widget.js.map"
  ]
  CMS_SOURCES.each do |source|
    file source do
      fail 'Node dependencies are not installed. Please make sure you have Node.js with npm installed, run "npm install", and then try again.'
    end
  end

  CMS_TARGET_DIR = "#{jekyll_config['destination']}/assets"
  CMS_TARGETS = CMS_SOURCES.map do |source|
    "#{CMS_TARGET_DIR}/#{File.basename(source)}"
  end

  directory CMS_TARGET_DIR

  CMS_SOURCES.zip(CMS_TARGETS).each do |source, target|
    file target => [CMS_TARGET_DIR, source] do |t|
      sh "install -m 644 #{t.prerequisites.last} #{t.name}"
    end
  end

  task cms: CMS_TARGETS

  task :jekyll do
    opts = {'serving' => false}
    opts['config'] = ENV['JEKYLL_CONFIG'] if ENV.key? 'JEKYLL_CONFIG'

    $stderr.print "bundle exec jekyll build"
    $stderr.print "--config #{opts['config']}" if opts.key? 'config'
    $stderr.puts

    Jekyll::Commands::Build.process opts
  end

  CLOBBER << jekyll_config['destination']
end
