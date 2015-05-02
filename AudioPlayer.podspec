Pod::Spec.new do |s|
  s.name         = 'AudioPlayer'
  s.version      = '0.1.0'
  s.license      =  { :type => 'MIT' }
  s.homepage     = 'https://github.com/delannoyk/AudioPlayer'
  s.authors      = {
    'Kevin Delannoy' => 'delannoyk@gmail.com'
  }
  s.summary      = ''

# Source Info
  s.platform     =  :ios, '8.0'
  s.source       =  {
    :git => 'https://github.com/delannoyk/AudioPlayer.git',
    :tag => s.version.to_s
  }
  s.source_files = 'AudioPlayer/**/*.swift'
  s.framework    =  'UIKit', 'AVFoundation', 'MediaPlayer', 'SystemConfiguration'

  s.requires_arc = true
end
