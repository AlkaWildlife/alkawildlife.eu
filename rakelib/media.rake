require 'rake/clean'
require_relative 'util'

# Media folder is normally in Jekyll source dir. However,
# repositories with with multiple localtization share media folder
# and it needs to be copied to Jekyll source destination. They must
# be in source destination to be accessible as Jekyll static files
# in templates. In such cases, media folder on top of repostiroy
# working copy (i.e., project root). The folder is expected to be
# top-level (i.e., has no forward slashes or path segments).

MEDIA_DIR_TARGET = cms_config ?
  "#{jekyll_config['source']}/#{cms_config['media_folder']}".freeze :
  nil

MEDIA_DIR_SOURCE = MEDIA_DIR_TARGET ?
  File.basename(MEDIA_DIR_TARGET).freeze :
  nil

MEDIA_SOURCES = (
  MEDIA_DIR_SOURCE && !File.identical?(MEDIA_DIR_SOURCE, MEDIA_DIR_TARGET) ?
    FileList["#{MEDIA_DIR_SOURCE}/**/*"] :
    FileList[]
).select {|f| File.file? f }

MEDIA_TARGETS = MEDIA_SOURCES.
  map {|source| source[(MEDIA_DIR_SOURCE.length + 1)..-1] }.
  map {|basename| "#{MEDIA_DIR_TARGET}/#{basename}" }

MEDIA_TARGETS.map {|target| File.dirname target }.uniq.each do |target_dir|
  directory target_dir
end

MEDIA_SOURCES.zip(MEDIA_TARGETS).each do |source, target|
  file target => [File.dirname(target), source] do |t|
    clone_file t.prerequisites.last, t.name
  end
end

desc "Ensure media files are in Jekyll site source directory\n" +
     "\n" +
     "If this source code has different site for different locales\n" +
     "which correspond to Jekyll source directories, specify the site\n" +
     "you want to build with JEKYLL_LANG environment variable.\n"
task media: MEDIA_TARGETS

if MEDIA_DIR_TARGET and not File.identical?(MEDIA_DIR_SOURCE, MEDIA_DIR_TARGET)
  CLOBBER << MEDIA_DIR_TARGET
end
