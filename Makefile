# AeroSwitch Makefile

BINARY_NAME := aeroswitch
VERSION := 1.0.0
BUILD_DIR := .build
INSTALL_PATH := /usr/local/bin

.PHONY: all build release clean install uninstall test help

all: build

## Build debug version
build:
	swift build

## Build release version
release:
	swift build -c release

## Clean build artifacts
clean:
	swift package clean
	rm -rf $(BUILD_DIR)
	rm -rf releases

## Install to system
install: release
	install -d $(INSTALL_PATH)
	install $(BUILD_DIR)/release/$(BINARY_NAME) $(INSTALL_PATH)/

## Uninstall from system
uninstall:
	rm -f $(INSTALL_PATH)/$(BINARY_NAME)

## Run tests
test:
	swift test

## Create release archive
archive: release
	@mkdir -p releases
	@tar -czf releases/$(BINARY_NAME)-$(VERSION)-macos.tar.gz -C $(BUILD_DIR)/release $(BINARY_NAME)
	@cd releases && shasum -a 256 $(BINARY_NAME)-$(VERSION)-macos.tar.gz > $(BINARY_NAME)-$(VERSION)-macos.tar.gz.sha256
	@echo "Release archive created: releases/$(BINARY_NAME)-$(VERSION)-macos.tar.gz"

## Show help
help:
	@echo "Available commands:"
	@echo "  build     - Build debug version"
	@echo "  release   - Build release version"
	@echo "  install   - Install to $(INSTALL_PATH) (requires sudo)"
	@echo "  uninstall - Remove from $(INSTALL_PATH) (requires sudo)"
	@echo "  archive   - Create release archive"
	@echo "  clean     - Clean build artifacts"
	@echo "  test      - Run tests"
	@echo "  help      - Show this help"