## 0.3.1

- fix: replace deprecated `window` with `PlatformDispatcher.instance.implicitView`
- fix: remove unnecessary null assertions in provider
- fix: suppress unused element warnings for reserved future APIs
- chore: add analysis_options.yaml

## 0.3.0

- fix: resolve screen size 0x0 bug causing incorrect window positioning
- fix: wait for valid physicalSize before sending system config to Android
- fix: update cached config when existing config has invalid 0x0 screen size
- feat: improve assistive touch menu animation with scale from touch ball position
- chore: upgrade Android Gradle Plugin to 8.5.0
- chore: upgrade Kotlin to 1.9.22
- chore: upgrade Gradle to 8.10.2
- chore: migrate to new Flutter Gradle plugin declarative syntax
- chore: update compileSdk/targetSdk to 34, minSdk to 21
- test: add comprehensive unit tests (73 tests)
- test: add integration tests (13 tests)

## 0.1.1

- fix: fix build error for version of kotlin

## 0.1.0

- feature: basic support for overlay window
- chore: add exmaples
