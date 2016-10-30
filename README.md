AudioPlayer
===========
[![Build Status](https://travis-ci.org/delannoyk/AudioPlayer.svg?branch=master)](https://travis-ci.org/delannoyk/AudioPlayer)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![CocoaPods Compatible](https://img.shields.io/cocoapods/v/KDEAudioPlayer.svg)
![Platform iOS | tvOS](https://img.shields.io/badge/platform-iOS%20%7C%20tvOS%20%7C%20OSX-lightgrey.svg)
[![Contact](https://img.shields.io/badge/contact-%40kdelannoy-blue.svg)](https://twitter.com/kdelannoy)

AudioPlayer is a wrapper around AVPlayer. It also offers cool features such as:
* Quality control based on number of interruption (buffering) and time delay
* Retry if player fails
* Connection handling
* Audio item enqueuing
* Player mode (Repeat, Repeat all, Suffle)
* MPNowPlayingInfoCenter
* A high level of customization

## Installation

* CocoaPods: `pod 'KDEAudioPlayer'`
* Carthage: `github "delannoyk/AudioPlayer"`

## Usage
### Basics
```swift
let delegate: AudioPlayerDelegate = ...

let player = AudioPlayer()
player.delegate = delegate
let item = AudioItem(mediumQualitySoundURL: track.streamURL)
player.playItem(item)
```

### Delegate
In order to alert about status change or other events, AudioPlayer uses delegation.

#### State
When AudioPlayer’s state changes, the method
```swift
func audioPlayer(audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, toState to: AudioPlayerState)
```
is called.

#### Duration & progression
When AudioPlayer’s current item found duration of its content
```swift
func audioPlayer(audioPlayer: AudioPlayer, didFindDuration duration: NSTimeInterval, forItem item: AudioItem)
```
is called.

This method is called regularly to notify progression update.
```swift
func audioPlayer(audioPlayer: AudioPlayer, didUpdateProgressionToTime time: NSTimeInterval, percentageRead: Float)
```
`percentageRead` is a Float value between 0 & 100 so that you can easily update an UISlider for example.

#### Queue
```swift
func audioPlayer(audioPlayer: AudioPlayer, willStartPlayingItem item: AudioItem)
```

### Control Center / Lockscreen
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    application.beginReceivingRemoteControlEvents()
}

//Then in your UIResponder (or your AppDelegate if you will)
override func remoteControlReceivedWithEvent(event: UIEvent?) {
    if let event = event {
        yourPlayer.remoteControlReceivedWithEvent(event)
    }
}
```

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Todo list

* Add a fully working example project
* Integrate with SPM
* Add more unit tests
* Add Objective-C support if possible ([#67](https://github.com/delannoyk/AudioPlayer/issues/67))
* Refactor current state handling

## License

The MIT License (MIT)

Copyright (c) 2015 Kevin Delannoy

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
