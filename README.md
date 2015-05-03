# AudioPlayer

AudioPlayer is a wrapper around AVPlayer. It also offers cool features such as:
* Quality control based on number of interruption (buffering) and time delay
* Retry if player fails
* Connection handling
* Audio item enqueuing
* Player mode (Repeat, Repeat all, Suffle)
* MPNowPlayingInfoCenter
* A high level of customization

## Installation

* Adding it in your Podfile `pod 'KDEAudioPlayer'`

## Usage
```swift
let player = AudioPlayer()
let item = AudioItem(mediumQualitySoundURL: track.streamURL)
player.playItem(item)
```

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Todo

* See issues

## License

The MIT License (MIT)

Copyright (c) 2015 Kevin Delannoy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
