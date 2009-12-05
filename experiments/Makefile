EXPERIMENTS=launch_service_test proxy_test

all:


launch_service_test: launch_service_test.m
	gcc -fobjc-gc -framework ApplicationServices -framework Cocoa -o $@ $@.m
	./$@

proxy_test: proxy_test.m
	gcc -fobjc-gc -framework Cocoa -framework SystemConfiguration -o $@ $@.m
	./$@
