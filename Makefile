
default: test

build:
	xcodebuild -sdk iphonesimulator -target Pinwheel build

test:
	#xcodebuild -sdk iphonesimulator -scheme PinwheelTests test
	xctool -sdk iphonesimulator -arch i386 -scheme PinwheelTests test

clean:
	xcodebuild -sdk iphonesimulator clean

.PHONY: build test clean default