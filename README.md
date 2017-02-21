# JWMediaManager

[![Build Status](https://travis-ci.org/heilb1314/JWMediaManager.svg?branch=master)](https://travis-ci.org/heilb1314/JWMediaManager)
[![Version](https://img.shields.io/cocoapods/v/JWMediaManager.svg?style=flat)](http://cocoapods.org/pods/JWMediaManager)
[![License](https://img.shields.io/cocoapods/l/JWMediaManager.svg?style=flat)](http://cocoapods.org/pods/JWMediaManager)
[![Platform](https://img.shields.io/cocoapods/p/JWMediaManager.svg?style=flat)](http://cocoapods.org/pods/JWMediaManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS 8.0+
* XCode 8.1+
* Swift 3.0+

## Installation

JWMediaManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "JWMediaManager"
```

## Usage

```swift
import JWMediaManager
```

Add `MediaPlayerManagerDelegate` to your class.

###Create a manager instance

```swift
var mediaManager = MediaPlayerManager()
```

Make sure assign delegate `mediaManager.delegate = self`

###Set playlist and/or play index

```swift
mediaManager.setPlayer(with: playlist, playAt: index)
```

###Support 3 Different play modes
* `PlayMode.loop` Play continuously in order
* `PlayMode.one` Repeat single one
* `PlayMode.shuffle` Shuffle playlist.

###MediaPlayerManagerDelegate
* Continuously play time update

    ```swift
    func mediaPlayerPlayTimeDidChange(sender: MediaPlayerManager, time: Double) {
    // update current time
    }
    ```
* PlayerItem duration change

    ```swift
    func mediaPlayerDurationDidChange(sender: MediaPlayerManager, duration: Double) {
    // update duration
    }
    ```
* PlayerItem already downloaded duration change

    ```swift
    func mediaPlayerAvailableDurationDidChange(sender: MediaPlayerManager, duration: Double) {
    // update available duration
    }
    ```
* Player Status change

    ```swift
    func mediaPlayerStatusDidChange(sender: MediaPlayerManager, status: PlayerStatus) {
    // update player UI
    }
    ```
* Player item change

    ```swift
    func mediaPlayerPlayURLDidChange(sender: MediaPlayerManager, playURL: URL?) {
    // Playeritem has changed
    }
    ```

## Author

heilb1314

## License

JWMediaManager is available under the MIT license. See the LICENSE file for more info.
