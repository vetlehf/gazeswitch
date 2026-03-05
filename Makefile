.PHONY: build run clean test

APP_NAME = GazeSwitch
BINARY = .build/debug/$(APP_NAME)
ENTITLEMENTS = GazeSwitch.entitlements

build:
	swift build
	codesign --force --sign - --entitlements $(ENTITLEMENTS) $(BINARY)

run: build
	$(BINARY)

test:
	swift test

clean:
	swift package clean
