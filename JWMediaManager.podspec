#
# Be sure to run `pod lib lint JWMediaManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JWMediaManager'
  s.version          = '0.1.2'
  s.summary          = 'A custom AVPlayer Manager'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
JWMediaManager give the functionalities for AVPlayer more easy to use.
                       DESC

  s.homepage         = 'https://github.com/heilb1314/JWMediaManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jianxiong Wang' => 'heilb1314@hotmail.com' }
  s.source           = { :git => 'https://github.com/heilb1314/JWMediaManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'JWMediaManager/Classes/**/*'

  # s.resource_bundles = {
  #   'JWMediaManager' => ['JWMediaManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'AVFoundation'
  # s.dependency 'AFNetworking', '~> 2.3'
end
