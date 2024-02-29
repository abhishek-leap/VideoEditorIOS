#
# Be sure to run `pod lib lint LeapVideoEditor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'LeapVideoEditor'
    s.version          = '0.4.8'
    s.summary          = 'A short description of LeapVideoEditor.'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = <<-DESC
    TODO: Add long description of the pod here.
    DESC
    
    s.homepage         = 'https://github.com/jovan-bigstep/LeapVideoEditor'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'jovan-bigstep' => '102965218+jovan-bigstep@users.noreply.github.com' }
    s.source           = { :git => 'https://github.com/jovan-bigstep/LeapVideoEditor.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
    
    s.ios.deployment_target = '13.0'
    
    s.source_files = 'LeapVideoEditor/Classes/**/*'
    
    s.resource_bundles = {
        'LeapVideoEditor' => 'LeapVideoEditor/Assets/Media.xcassets'
    }
    
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    s.dependency 'SCSDKCameraKit', '1.18.1'
    s.dependency 'SCSDKCameraKitReferenceUI', '1.18.1'
    s.dependency 'DKImagePickerController/Core'
    s.dependency 'Giphy'
    s.dependency 'Kingfisher'
    s.dependency 'FontAwesome.swift'
    s.dependency 'Alamofire'
    s.dependency 'MBProgressHUD'
    s.dependency 'ffmpeg-kit-ios-full-gpl'
end
