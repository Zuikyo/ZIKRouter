Pod::Spec.new do |s|

  s.name         = "ZIKRouterSwift"
  s.version      = "0.0.1"
  s.summary      = "An iOS Swift router for discovering modules and injecting dependencies with protocol."
  s.description  = <<-DESC
                An iOS Swift router for discovering modules and injecting dependencies with protocol, designed for VIPER. The view router can perform all navigation types in UIKit through one method. The service router can discover service with protocol.
                   DESC
  s.homepage         = "https://github.com/Zuikyo/ZIKRouter"
  s.license      = "MIT"
  s.author             = { "Zuikyo" => "zuilongzhizhu@gmail.com" }

  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/Zuikyo/ZIKRouter.git", :tag => "#{s.version}" }

  s.source_files  = "ZIKRouterSwift/*.swift"
  s.public_header_files = "ZIKRouterSwift/*.h"

  s.requires_arc = true

  s.dependency "ZIKRouter", '>= 0.6.3'

end
