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
    "node_modules/netlify-cms/dist/cms.css"
  ]
  CMS_DEBUG_SOURCES = Jekyll.env == "development" ? FileList[
    "node_modules/netlify-cms/src",
    "node_modules"
  ] : FileList[]
  (CMS_SOURCES + CMS_DEBUG_SOURCES).each do |source|
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
      sh 'install', '-m', '644', t.prerequisites.last, t.name
    end
  end

  CMS_DEBUG_TARGETS = CMS_DEBUG_SOURCES.map do |source|
    "#{CMS_TARGET_DIR}/#{File.basename(source)}"
  end

  CMS_DEBUG_SOURCES.zip(CMS_DEBUG_TARGETS).each do |source, target|
    file target => [File.dirname(target), source] do |t|
      #XXX This was supposed to be a symlink, but Listen (used by
      # Jekyll) complains about duplicate directories being watched
      # and Jekyll cannot be configured in this regard. Using `cp -a`
      # should be just fine on modern hardware and file systems with
      # copy-on-write feature.
      sh 'cp', '-a', t.prerequisites.last, t.name
    end
  end

  desc "Copy Netlify CMS assets from node_modules to _site\n" +
       "\n" +
       "Netlify CMS assets are copied from local Node.js modules path\n" +
       "(i.e., node_modules directory) to assets directory under the\n" +
       "Jekyll destination path (_site directory by default). Custom\n" +
       "Jekyll config can be specified by JEKYLL_CONFIG environment\n" +
       "variable.\n" +
       "\n" +
       "If run in development environment (controlled by JEKYLL_ENV\n" +
       "environment variable), it also copies source files so that CMS\n" +
       "debugging can use source maps."
  task cms: CMS_TARGETS + [:debug]

  task debug: CMS_DEBUG_TARGETS do |t|
    # Source maps replace $. with _ in the beginning of file names,
    # but build-in server cannot handle this out of the box.
    CMS_DEBUG_TARGETS.
      map {|t| "#{t}/**/$*" }.
      map {|glob| Dir[glob] }.
      flatten.
      map {|f| [f, f.gsub('$.', '_')] }.
      each {|s, t| sh 'mv', s, t }
  end

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
