Pod::Spec.new do |s|
  s.name          = 'KDEAudioPlayer'
  s.version       = '0.4.3'
  s.license       =  { :type => 'MIT' }
  s.homepage      = 'https://github.com/delannoyk/AudioPlayer'
  s.authors       = { 'Kevin Delannoy' => 'delannoyk@gmail.com' }
  s.summary       = 'AudioPlayer is a wrapper around AVPlayer and also offers cool features.'

  s.source        =  { :git => 'https://github.com/delannoyk/AudioPlayer.git', :tag => s.version.to_s }
  s.source_files  = 'AudioPlayer/**/*.swift'
  s.requires_arc  = true
  s.framework     = 'UIKit', 'AVFoundation', 'MediaPlayer', 'SystemConfiguration'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
end
