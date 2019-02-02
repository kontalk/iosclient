# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

source 'https://gitlab.com/a.cappelli87/kontalkrepo.git'
source 'https://github.com/CocoaPods/Specs.git'
target 'Kontalk' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Kontalk
  pod 'XMPPFramework/Swift', :git => 'https://github.com/kontalk/XMPPFramework.git' 
  pod 'OpenSSL-Universal'
  pod 'ObjectivePGP', :git => 'https://github.com/kontalk/ObjectivePGP.git'

  pod 'SwiftyBeaver'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Alamofire', '~> 4.7'
  pod 'SwiftEventBus', :tag => '3.0.1', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
  
  pod 'SecurityExtensions'
  
  #pod 'CocoaLumberjack' # Skip pinning version because of the awkward 2.x->3.x transition
  #pod 'KissXML', '~> 5.2'
  #pod 'libidn', '~> 1.35'
  
  # UI
  pod "FlagPhoneNumber"
  pod 'RAMAnimatedTabBarController'
  pod 'NVActivityIndicatorView'
  
  pod 'RxSwift',    '~> 4.0'
  pod 'RxCocoa',    '~> 4.0'

  target 'KontalkTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'KontalkUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
