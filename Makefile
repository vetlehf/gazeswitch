.PHONY: build run clean test bundle install dmg sign notarize

APP_NAME = GazeSwitch
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
BINARY = .build/debug/$(APP_NAME)
RELEASE_BINARY = .build/release/$(APP_NAME)
ENTITLEMENTS = GazeSwitch.entitlements
APP_BUNDLE = build/$(APP_NAME).app
DMG_NAME = $(APP_NAME)-$(VERSION).dmg
SIGN_IDENTITY ?= -

build:
	swift build
	codesign --force --sign - --entitlements $(ENTITLEMENTS) $(BINARY)

run: build
	$(BINARY)

test:
	swift test

clean:
	swift package clean
	rm -rf build

bundle:
	swift build -c release
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(RELEASE_BINARY) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Sources/GazeSwitch/Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	cp Sources/GazeSwitch/Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	codesign --force --sign - --entitlements $(ENTITLEMENTS) --deep $(APP_BUNDLE)
	@echo "Created $(APP_BUNDLE)"

sign: bundle
	codesign --force --sign "$(SIGN_IDENTITY)" --entitlements $(ENTITLEMENTS) --deep --options runtime $(APP_BUNDLE)
	@echo "Signed $(APP_BUNDLE) with $(SIGN_IDENTITY)"

dmg: bundle
	rm -f build/$(DMG_NAME)
	hdiutil create -volname "$(APP_NAME)" -srcfolder $(APP_BUNDLE) -ov -format UDZO build/$(DMG_NAME)
	@echo "Created build/$(DMG_NAME)"

notarize: dmg
	xcrun notarytool submit build/$(DMG_NAME) --keychain-profile "AC_PASSWORD" --wait
	xcrun stapler staple build/$(DMG_NAME)
	@echo "Notarized build/$(DMG_NAME)"

install: bundle
	cp -r $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"
