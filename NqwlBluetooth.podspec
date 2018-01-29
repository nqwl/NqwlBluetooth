#
# Be sure to run `pod lib lint NqwlBluetooth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NqwlBluetooth'
  s.version          = '0.1.0'
  s.summary          = 'NqwlBluetooth.'
  s.description      = <<-DESC
TODO: NqwlBluetooth.是基于BabyBluetooth的二次封装。
                       DESC

  s.homepage         = 'https://github.com/nqwl/NqwlBluetooth'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nqwl' => '1273087648@qq.com' }
  s.source           = { :git => 'https://github.com/nqwl/NqwlBluetooth.git', :tag => s.version.to_s }
  s.social_media_url = 'https://www.jianshu.com/u/9498c1b8ac2e'

  s.ios.deployment_target = '8.0'

  s.source_files = 'NqwlBluetooth/Classes/**/*'
  
  # s.resource_bundles = {
  #   'NqwlBluetooth' => ['NqwlBluetooth/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'BabyBluetooth'
end
