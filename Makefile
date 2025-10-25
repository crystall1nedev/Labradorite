SHELL := /bin/bash
.SHELLFLAGS = -ec
# Use `make VERBOSE=1` to print commands.
$(VERBOSE).SILENT:

# Prerequisite variables
SOURCEDIR   ?= $(shell printf "%q\n" "$(shell pwd)")
VERSION     ?= 1.0

# Are we building a release or not
ifndef RELEASE
CONFIG      ?= "Debug"
else
CONFIG      ?= "Release"
endif

clean:
	rm -rf $(SOURCEDIR)/build

api:
	echo '[Labradorite v$(VERSION) - API]'
	mkdir -p $(SOURCEDIR)/build
	xcodebuild -workspace Labradorite.xcworkspace -scheme labradorite-server -configuration $(CONFIG) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO BUILD_DIR=$(SOURCEDIR)/build

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
