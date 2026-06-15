platform :ios, '16.0'
inhibit_all_warnings!
source 'https://github.com/CocoaPods/Specs.git'

def mimo_pods
  pod 'lottie-ios'
  # Maps are provided by the 2GIS Mobile SDK, added via Swift Package Manager
  # (https://github.com/2gis/mobile-sdk-map-swift-package). Google Maps removed.
  pod 'SwiftMaskTextfield'
  pod 'KeychainAccess'
  pod 'SDWebImage'
  pod 'SwiftStomp'
  pod 'Starscream', '4.0.4'
  pod 'PhoneNumberKit', '~> 3.3'
  pod 'libPhoneNumber-iOS', '~> 0.8'
  pod 'IQKeyboardManagerSwift'
  pod 'MercariQRScanner'
  pod 'Kingfisher', '~> 7.0'
  pod 'SwiftMessages'
end

target 'Impuls' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Impuls
  mimo_pods
end

target 'Impuls-Dev' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Impuls
  mimo_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
#      if target.name == "lottie-ios"
#        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
#      end
#
#      if target.name == "SwiftStomp" or target.name == ""
#        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
#      end
    end
  end
end
