Pod::Spec.new do |s|
  s.name         = "Net"
  s.version      = "0.2.2"
  s.summary      = "Http Request wrapper written in Swift"
  s.homepage     = "https://github.com/nghialv"
  s.screenshots  = "https://camo.githubusercontent.com/18ae3452d66a0b8ad14ee6c897814044c79cec98/68747470733a2f2f646c2e64726f70626f7875736572636f6e74656e742e636f6d2f752f383535363634362f73637265656e73686f74322e706e67"

  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Le Van Nghia" => "nghialv2607@gmail.com" }
  s.social_media_url   = "https://twitter.com/nghialv2607"

  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/nghialv/Net.git", :tag => "0.2.2" }

  s.source_files  = "Net/*"
  s.requires_arc = true
end
