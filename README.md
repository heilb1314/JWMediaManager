# JWMediaManager

[![CI Status](http://img.shields.io/travis/heilb1314/JWMediaManager.svg?style=flat)](https://travis-ci.org/heilb1314/JWMediaManager)
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

Make sure to `import JWMediaManager` first.

Add `MediaPlayerManagerDelegate` to your class.

Create a manager instance

```
var mediaManager = MediaPlayerManager()
```

Make sure assign delegate `mediaManager.delegate = self`

Set playlist and play index

```
mediaManager.setPlayer(with: playlist, playAt: index)
```

Support 3 Different play modes
* `PlayMode.loop` Play continuously in order
* `PlayMode.one` Repeat single one
* `PlayMode.shuffle` Shuffle playlist.


## Author

heilb1314

## License

JWMediaManager is available under the MIT license. See the LICENSE file for more info.
