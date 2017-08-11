Pod::Spec.new do |s|

  s.name         = "ZIKRouter"
  s.version      = "0.4.1"
  s.summary      = "An iOS router for decoupling between modules, and injecting dependencies with protocol."
  s.description  = <<-DESC
                An iOS router for decoupling between modules, and injecting dependencies with protocol. The view router can perform all navigation types in UIKit through one method, designed for VIPER. The service router can discover service with protocol.
                   DESC
  s.homepage         = "https://github.com/Zuikyo/ZIKRouter"
  s.license      = "MIT"
  s.author             = { "Zuikyo" => "zuilongzhizhu@gmail.com" }

  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/Zuikyo/ZIKRouter.git", :tag => "#{s.version}" }

  s.source_files  = "ZIKRouter/*.{h,m}", "ZIKRouter/Additions/*.{h,m}", "ZIKRouter/Framework/*.h"
  s.preserve_path = 'ZIKRouter/Framework/module.modulemap'
  s.module_map = 'ZIKRouter/Framework/module.modulemap'

  s.frameworks = "Foundation", "UIKit"
  s.requires_arc = true

end
