# Configuration, override port with usage: make PORT=4200
PORT ?= 4100
REPO_NAME ?= portfolio_2025
LOG_FILE = /tmp/jekyll$(PORT).log

SHELL = /bin/bash -c
.SHELLFLAGS = -e # Exceptions will stop make, works on MacOS

# Phony Targets, makefile housekeeping for below definitions
.PHONY: default server issues convert clean stop

# List all .ipynb files in the _notebooks directory
NOTEBOOK_FILES := $(shell find _notebooks -name '*.ipynb')

# Specify the target directory for the converted Markdown files
DESTINATION_DIRECTORY = _posts
MARKDOWN_FILES := $(patsubst _notebooks/%.ipynb,$(DESTINATION_DIRECTORY)/%_IPYNB_2_.md,$(NOTEBOOK_FILES))

# Call server, then verify and start logging
default: server
    @echo "Terminal logging starting, watching server..."
    @# tail and awk work together to extract Jekyll regeneration messages
    @# When a _notebook is detected in the log, call make convert in the background

# Convert .ipynb files to Markdown with front matter
convert: $(MARKDOWN_FILES)

# Convert .ipynb files to Markdown with front matter, preserving directory structure
$(DESTINATION_DIRECTORY)/%_IPYNB_2_.md: _notebooks/%.ipynb
    @echo "Converting source $< to destination $@"
    @mkdir -p $(@D)
    @python3 -c 'import sys; from scripts.convert_notebooks import convert_single_notebook; convert_single_notebook(sys.argv[1])' "$<"

# Clean up project derived files, to avoid run issues stop is dependency
clean: stop
    @echo "Cleaning converted IPYNB files..."
    @find _posts -type f -name '*_IPYNB_2_.md' -exec rm {} +
    @echo "Cleaning Github Issue files..."
    @find _posts -type f -name '*_GithubIssue_.md' -exec rm {} +
    @echo "Removing empty directories in _posts..."
    @while [ $$(find _posts -type d -empty | wc -l) -gt 0 ]; do \
        find _posts -type d -empty -exec rmdir {} +; \
    done
    @echo "Removing _site directory..."
    @rm -rf _site

# Stop the server and kill processes
stop:
    @echo "Stopping server..."
    @# kills process running on port $(PORT)
    @pkill -f "jekyll serve -H 127.0.0.1 -P $(PORT)"