.PHONY: help deps analyze test devices run build install lab diag logs check generate

FLUTTER ?= flutter
ADB ?= $(firstword $(wildcard $(ANDROID_HOME)/platform-tools/adb $(ANDROID_SDK_ROOT)/platform-tools/adb) adb)
DEVICE ?= $(shell $(ADB) devices 2>/dev/null | awk '$$2 == "device" { print $$1; exit }')
TARGET_PLATFORM ?= android-arm64
# Extra build flags. New York (3-1 to 3-4) is open by default; to ship a build
# with it closed again: make build DEFINES=--dart-define=NEW_YORK_OPEN=false
DEFINES ?=
APK := build/app/outputs/flutter-apk/app-release.apk

help:
	@printf '%s\n' \
		'make run      Run on a connected Android device' \
		'make devices  List Flutter and adb devices' \
		'make build    Build a release APK (android-arm64)' \
		'make install  Build and sideload the release APK' \
		'make lab      Build and sideload the camera-lab APK' \
		'make diag     Build and sideload a profile APK that records tracking logs' \
		'make logs     Pull the last two tracking logs from the phone into /tmp' \
		'make test     Run Flutter analyzer and tests' \
		'make check    Verify packaged models and 16KB ELF alignment' \
		'make generate Regenerate Pigeon and Drift bindings'

deps:
	$(FLUTTER) pub get

analyze:
	$(FLUTTER) analyze

test: analyze
	$(FLUTTER) test

devices:
	$(ADB) devices -l
	$(FLUTTER) devices

run:
	@test -n "$(DEVICE)" || { echo "No authorized Android device found. Check the cable, enable USB debugging, and accept the RSA prompt."; $(ADB) devices -l; exit 1; }
	$(FLUTTER) run -d $(DEVICE) $(DEFINES)

build:
	$(FLUTTER) build apk --release --target-platform $(TARGET_PLATFORM) $(DEFINES)

install: build
	$(ADB) install -r $(APK)

lab:
	$(FLUTTER) build apk --release --target-platform $(TARGET_PLATFORM) --dart-define=CAMERA_LAB=true
	$(ADB) install -r $(APK)

# `make run` (debug) and release builds write no tracking trace. Use this
# build when a physical retry should leave replayable landmark logs.
diag:
	$(FLUTTER) build apk --profile --target-platform $(TARGET_PLATFORM) --dart-define=TRACKING_DIAGNOSTICS=true --dart-define=TRACKING_CAPTURE_IMAGES=true
	$(ADB) install -r build/app/outputs/flutter-apk/app-profile.apk

logs:
	$(ADB) exec-out run-as com.ravanix.push_up_bird cat files/tracking_diagnostics/latest.log > /tmp/push-up-bird-last.log
	-$(ADB) exec-out run-as com.ravanix.push_up_bird cat files/tracking_diagnostics/previous.log > /tmp/push-up-bird-previous.log 2>/dev/null
	@grep -h -E 'PushUpBird (session|calibration|end):' /tmp/push-up-bird-previous.log /tmp/push-up-bird-last.log 2>/dev/null | cut -c1-200
	@echo 'Replay: dart run tool/replay_tracking.dart /tmp/push-up-bird-last.log'

check: build
	python3 tool/check_android_apk.py $(APK)

generate:
	dart run pigeon --input pigeons/tracking_api.dart
	dart run build_runner build
