# ShimmerX

ShimmerX is a native macOS utility that recreates a Dynamic Island-like experience on notch MacBooks without covering the camera indicator area.

## Current scope

- Native macOS app built with Swift, AppKit, and SwiftUI
- Floating island panel positioned below the menu bar / notch area
- iOS-inspired motion and shape transitions
- Inline todo capture with local persistence
- Apple Music playback controls and track status sync

## Local testing

```bash
HOME=$PWD CLANG_MODULE_CACHE_PATH=$PWD/.cache/clang SWIFTPM_MODULECACHE_OVERRIDE=$PWD/.cache/swiftpm swift run
```

Notes:

- The first media control action may trigger a macOS Automation permission prompt for controlling `Music`.
- Current media support targets Apple Music first. Spotify and system-wide now playing integration are not implemented yet.
