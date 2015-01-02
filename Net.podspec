Pod::Spec.new do |s|
  s.name = 'Net'
  s.version = '0.1'
  s.license = 'Apache'
  s.summary = 'Http Request wrapper written in Swift'
  s.homepage = 'https://github.com/nghialv/Net'
  s.authors = { 'Hermes Pique' => 'https://twitter.com/hpique' }
  s.source = { :git => 'https://github.com/mente/Net.git', :branch => 'podspec' }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Net/*.swift'
end
