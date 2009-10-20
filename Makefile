
all:
	xcodebuild -configuration Release build

zip: all
	(cd build/Release; zip -r unofficial-google-wave-notifier-mac-$(VERSION).zip "Unofficial Google Wave Notifier.app")
