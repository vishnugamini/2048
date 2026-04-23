# Premium 2048

A premium-native `SwiftUI` iPhone take on 2048, built inside this workspace.

## What's here

- `Premium2048.xcodeproj`: iPhone app project scaffold
- `Sources/GameCore`: pure Swift game engine shared as the app's core logic
- `Tests/GameCoreTests`: `XCTest` coverage for move resolution and edge cases
- `Premium2048/App`: SwiftUI app shell, view model, and premium presentation

## Current machine constraint

The workspace currently has Swift Command Line Tools available, but not an active full `Xcode` developer directory. That means:

- `swift test` works for the engine
- iPhone simulator builds will require installing/selecting full `Xcode`

## Next local steps

1. Install Xcode from the App Store if it is not already present.
2. Switch to it with `sudo xcode-select -s /Applications/Xcode.app`.
3. Open `Premium2048.xcodeproj` in Xcode and run the app on an iPhone simulator.
