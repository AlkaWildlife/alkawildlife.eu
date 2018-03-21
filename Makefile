# Manage Netlify CMS and Netlify Identity Widget assets.
#
# Jekyll doesn’t have flexible or extensible build system.
# Self-hosting Netlify CMS and Netlify Identity Widget on Jekyll site
# requires some of theirs assets to be inside Jekyll’s destination
# directory. This Makefile defines how to put them there from Node
# Modules directory probably managed by npm (distributed for example
# with Node.js).
#
# This Makefile also provides clean target to remove Netlify assets
# from Jekyll destination directory. If this directory is empty, then
# it removes the directory itself.
#
# Files are by default copied using the install utility. This can be
# changed by overriding INSTALL or INSTALL_DATA variables. Some
# important paths can also be changed:
# - Jekyll destination directory by overriding jekyll_destination
#   variable (defaults to _site)
# - Node Modules directory by overriding node_modules variable
#   (defaults to node_modules)

jekyll_destination = _site
node_modules = node_modules

target_dir = $(jekyll_destination)/assets/

cms_source_dir = $(node_modules)/netlify-cms/dist/
cms_objects = \
    cms.js \
    cms.js.map \
    cms.css

identity_source_dir = node_modules/netlify-identity-widget/build/
identity_objects = \
    netlify-identity-widget.js \
    netlify-identity-widget.js.map

cms_sources = $(addprefix $(cms_source_dir), $(cms_objects))
cms_targets = $(addprefix $(target_dir), $(cms_objects))
identity_sources = $(addprefix $(identity_source_dir), $(identity_objects))
identity_targets = $(addprefix $(target_dir), $(identity_objects))
all_sources = $(cms_sources) $(identity_sources)
all_targets = $(cms_targets) $(identity_targets)

SHELL = /bin/sh
INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: $(all_targets)

$(all_sources):
	@echo 'Error: Node dependencies are not installed. Please make sure you have Node.js with NPM installed, run "npm install", and then try again.' >/dev/stderr
	@exit 1

$(target_dir):
	$(INSTALL) -d $@

$(cms_targets): $(cms_sources) $(target_dir)
	$(INSTALL_DATA) $(cms_source_dir)$(@F) $@

$(identity_targets): $(identity_sources) $(target_dir)
	$(INSTALL_DATA) $(identity_source_dir)$(@F) $@

.PHONY: clean
clean:
	-rm -f $(all_targets)
	-rmdir -p $(target_dir)
