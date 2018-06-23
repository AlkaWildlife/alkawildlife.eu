require 'rake/clean'
require 'jekyll'
require_relative 'util'

desc "Build this site\n" +
     "\n" +
     "If this source code has different site for different locales\n" +
     "which correspond to Jekyll source directories, specify the site\n" +
     "you want to build with JEKYLL_LANG environment variable.\n"
task build: %w[build:cms build:jekyll:build]

desc "Serve this site for local development\n" +
     "\n" +
     "If this source code has different site for different locales\n" +
     "which correspond to Jekyll source directories, specify the site\n" +
     "you want to build with JEKYLL_LANG environment variable.\n"
task serve: %w[build:cms build:jekyll:serve]

namespace "build" do
  CMS_SOURCES = FileList[
    "node_modules/netlify-cms/dist/cms.js",
    "node_modules/netlify-cms/dist/cms.css"
  ]
  if Jekyll.env == "development"
    CMS_SOURCES << "node_modules/netlify-cms/dist/cms.js.map"
  end
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
      install t.prerequisites.last, t.name, mode: 0644
    end
  end

  CMS_DEBUG_TARGETS = CMS_DEBUG_SOURCES.map do |source|
    "#{CMS_TARGET_DIR}/#{File.basename(source)}"
  end

  CMS_DEBUG_SOURCES.zip(CMS_DEBUG_TARGETS).each do |source, target|
    file target => [File.dirname(target), source] do |t|
      clone_file t.prerequisites.last, t.name, :recursive
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
      each {|s, t| mv s, t }
  end

  namespace "jekyll" do
    task build: %w[media] do
      opts = {'serving' => false}
      opts['config'] = jekyll_config_files unless jekyll_config_files.empty?

      $stderr.print "bundle exec jekyll build"
      if opts.key? 'config'
        $stderr.print " --config #{opts['config'].join(',')}"
      end
      $stderr.puts

      Jekyll::Commands::Build.process opts
    end

    task serve: %w[media] do
      opts = {
        'livereload_port' => 35_729,
        'serving' => true,
        'watch' => true,
        'incremental' => true,
        'livereload' => true,
      }
      opts['config'] = jekyll_config_files unless jekyll_config_files.empty?

      $stderr.print "bundle exec jekyll serve --incremental --livereload"
      if opts.key? 'config'
        $stderr.print " --config #{opts['config'].join(',')}"
      end
      $stderr.puts

      Jekyll::Commands::Build.process opts
      Jekyll::Commands::Serve.process opts
    end
  end

  CLOBBER << jekyll_config['destination']
end
