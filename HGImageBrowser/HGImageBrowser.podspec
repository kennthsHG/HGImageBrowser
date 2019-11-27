#
# Be sure to run `pod lib lint HGImageBrowser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HGImageBrowser'
  s.version          = '1.0.0'
  s.summary          = '自定义图片视频展示库'


  s.description      = '自定义图片视频展示库，可展示图片，视频，支持URL，Image，Asset，Path'

  s.homepage         = 'https://github.com/kennthsHG/HGImageBrowser'

  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '黄 纲' => '362168751@qq.com' }
  s.source           = { :git => 'https://github.com/kennthsHG/HGImageBrowser.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'HGImageBrowser/Classes/**/*.{h,m}'
  
  s.resource_bundles = {
    'HGImageBrowserResource' => ['HGImageBrowser/Assets/*.png']
  }
  
  s.prefix_header_contents =
  '#import "HGImageBrowserMacro.h"'
  
  s.frameworks = 'UIKit','Photos'
  
  s.dependency 'SDWebImage'
  
  s.static_framework  =  true
end
