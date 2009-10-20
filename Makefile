APP="Unofficial Google Wave Notifier.app"

all:
	xcodebuild -configuration Release build

run: all
	open build/Release/$(APP)

zip: all
	(cd build/Release; zip -r unofficial-google-wave-notifier-mac-$(VERSION).zip $(APP))
