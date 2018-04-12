Pod::Spec.new do |s|
  s.name          = 'KDEAudioPlayer'
  s.version       = '1.2.0'
  s.license       =  { :type => 'MIT' }
  s.homepage      = 'https://github.com/delannoyk/AudioPlayer'
  s.authors       = { 'Kevin Delannoy' => 'delannoyk@gmail.com' }
  s.summary       = 'AudioPlayer is a wrapper around AVPlayer and also offers cool features.'

  s.source        =  { :git => 'https://github.com/delannoyk/AudioPlayer.git', :tag => s.version.to_s }
  s.source_files  = 'AudioPlayer/AudioPlayer/**/*.swift'
  s.requires_arc  = true

  s.ios.deployment_target = '8.0'
  s.ios.framework = 'UIKit', 'AVFoundation', 'MediaPlayer', 'SystemConfiguration'

  s.tvos.deployment_target = '9.0'
  s.tvos.framework = 'UIKit', 'AVFoundation', 'MediaPlayer', 'SystemConfiguration'

  s.osx.deployment_target = '10.10'
  s.osx.framework = 'Foundation', 'AVFoundation', 'SystemConfiguration'
  s.osx.exclude_files = 'AudioPlayer/AudioPlayer/utils/MPNowPlayingInfoCenter+AudioItem.swift'
end
