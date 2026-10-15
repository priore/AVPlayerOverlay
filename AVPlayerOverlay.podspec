Pod::Spec.new do |s|
  s.name                    = 'AVPlayerOverlay'
  s.version                 = '1.10.5'
  s.summary                 = 'AVPlayer with custom controls and full screen features.'
  s.license                 = 'MIT'
  s.authors 				= { 'Priore' => 'priore@users.noreply.github.com' }
  s.homepage 				= 'https://github.com/priore/AVPlayerOverlay'
  s.ios.deployment_target   = '7.1'
  s.requires_arc            = true
  s.authors                 = { 'Priore' => 'priore@users.noreply.github.com' }
  s.homepage                = 'https://github.com/priore/AVPlayerOverlay'
  s.source                  = { git: 'https://github.com/priore/AVPlayerOverlay.git', :tag => "v#{s.version}" }
  s.frameworks              = 'AVFoundation', 'CoreMedia', 'AVKit'
  s.source_files 			= 'AVPlayerOverlay/AVPlayer/*.{h,m}'
  s.public_header_files     = 'AVPlayerOverlay/AVPlayer/*.h'
  s.dependency              'UIView+draggable'
end
