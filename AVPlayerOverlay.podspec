Pod::Spec.new do |s|
  s.name                    = 'AVPlayerOverlay'
  s.version                 = '1.2.4'
  s.summary                 = 'AVPlayer with custom controls and full screen features.'
  s.license                 = 'MIT'
  s.ios.platform            = '7.1'
  s.ios.deployment_target   = '7.1'
  s.authors                 = { 'Danilo Priore' => 'support@prioregroup.com' }
  s.homepage                = 'https://github.com/priore/AVPlayerOverlay'
  s.social_media_url        = 'https://twitter.com/danilopriore'
  s.source                  = { git: 'https://github.com/priore/AVPlayerOverlay.git', :tag => "v#{s.version}" }
  s.frameworks              = 'AVFoundation', 'CoreMedia', 'AVKit'
  s.source_files 			= 'AVPlayerOverlay/AVPlayer/*.{h,m}'
end
