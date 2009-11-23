APP = "Unofficial Google Wave Notifier.app"
ZIP = unofficial-google-wave-notifier-mac-$(VERSION).zip
LENGTH = $(shell ls -l build/Release/$(ZIP) | awk '{print $$5}')
DSA_SIGN = $(shell ruby "Sparkle/Signing Tools/sign_update.rb" build/Release/$(ZIP) ~/Dropbox/private/Sparkle/dsa_priv.pem)
DATE = $(shell date "+%a, %d %b %Y %H:%M:%S +0900")

all:
	xcodebuild -configuration Release build

run:
	open build/Release/$(APP)

zip: all
	(cd build/Release; zip -r $(ZIP) $(APP))

appcast:
	@echo "\
         <item>\n\
            <title>Release $(VERSION)</title>\n\
            <sparkle:releaseNotesLink>\n\
      	      http://github.com/hiroshi/Unofficial-Google-Wave-Notifier/raw/master/CHANGELOG\n\
 	    </sparkle:releaseNotesLink>\n\
            <pubDate>$(DATE)</pubDate>\n\
            <enclosure url=\"http://cloud.github.com/downloads/hiroshi/Unofficial-Google-Wave-Notifier/$(ZIP)\" sparkle:version=\"$(VERSION)\" length=\"$(LENGTH)\" type=\"application/octet-stream\" sparkle:dsaSignature=\"$(DSA_SIGN)\" />\n\
         </item>"

launch_service_test: launch_service_test.m
	gcc -fobjc-gc -framework ApplicationServices -framework Cocoa -o $@ $@.m
	./$@
