require 'rake/clean'
require 'jekyll'
require_relative 'util'

desc "Build this site\n" +
     "\n" +
     "Custom Jekyll config can be specified by JEKYLL_CONFIG environment\n" +
     "variable."
task build: %w[build:cms build:jekyll]

namespace "build" do
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
    "#{CMS_TARGET_DIR}/#{asset_subdir source}/#{File.basename(source)}"
  end

  CMS_TARGETS.map {|target| File.dirname target }.uniq.each do |target_dir|
    directory target_dir
  end

  CMS_SOURCES.zip(CMS_TARGETS).each do |source, target|
    file target => [File.dirname(target), source] do |t|
      sh "install -m 644 #{t.prerequisites.last} #{t.name}"
    end
  end

  desc "Copy Netlify CMS assets from node_modules to _site\n" +
       "\n" +
       "Netlify CMS and Netlify Identity Widget assets are copied from \n" +
       "local Node.js modules path (i.e., node_modules directory) to \n" +
       "assets directory under the Jekyll destination path (_site \n" +
       "directory by default). Custom Jekyll config can be specified by \n" +
       "JEKYLL_CONFIG environment variable."
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
