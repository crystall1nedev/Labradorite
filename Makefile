SHELL := /bin/bash
.SHELLFLAGS = -ec
# Use `make VERBOSE=1` to print commands.
$(VERBOSE).SILENT:

# Prerequisite variables
SOURCEDIR   := $(shell printf "%q\n" "$(shell pwd)")
VERSION     := 1.0

api:
	echo '[Labradorite v$(VERSION) - API]'
	cd $(SOURCEDIR)/api; mkdir -p dst; \
    go build -ldflags="-X main.debug=1 -extldflags '-static'" -o dst/labradorite src/*.go 

api-release:
	echo '[Labradorite v$(VERSION) - API]'
	cd $(SOURCEDIR)/api; mkdir -p dst; \
    go build -ldflags="-s -w -X main.debug=0 -extldflags '-static'" -o dst/labradorite src/*.go 


# TODO: Swift framework revival
# swift-framework:
#    echo '[Labradorite v$(VERSION) - Framework]'

# TODO: Swift app revival
# swift-app:
#    echo '[Labradorite v$(VERSION) - App]'

# TODO: Brand new Swift cli
# swift-cli:
#    echo '[Labradorite v$(VERSION) - CLI]'

.PHONY: all api