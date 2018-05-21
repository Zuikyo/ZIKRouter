Pod::Spec.new do |s|

  s.name         = "ZIKRouter"
  s.version      = "1.0.0"
  s.summary      = "Interface-Oriented iOS router for discovering modules and injecting dependencies with protocol in both Swift and Objective-C."
  s.description  = <<-DESC
                Interface-Oriented iOS router for discovering modules and injecting dependencies with protocol in both Swift and Objective-C, designed for VIPER. The view router can perform all navigation types in UIKit through one method. The service router can discover service with protocol.
                   DESC
  s.homepage         = "https://github.com/Zuikyo/ZIKRouter"
  s.license      = "MIT"
  s.author       = { "Zuikyo" => "zuikxyo@gmail.com" }

  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/Zuikyo/ZIKRouter.git", :tag => "#{s.version}" }

  s.frameworks = "Foundation", "UIKit"
  s.requires_arc = true

  s.default_subspecs = 'Core', 'ViewRouter'

  s.subspec 'Core' do |core|
  s.preserve_path = 'ZIKRouter/Framework/Core/module.modulemap'
  s.module_map = 'ZIKRouter/Framework/Core/module.modulemap'
    core.source_files = "ZIKRouter/Router/*.{h,m,mm,cpp}",
                        "ZIKRouter/Router/**/*.{h,m,mm,cpp}",
                        "ZIKRouter/ServiceRouter/*.{h,m,mm,cpp}",
                        "ZIKRouter/ServiceRouter/**/*.{h,m,mm,cpp}",
                        "ZIKRouter/Utilities/*.{h,m,mm,cpp}",
                        "ZIKRouter/Utilities/**/*.{h,m,mm,cpp}",
                        "ZIKRouter/Utilities/**/**/*.{h,m,mm,cpp}",
                        "ZIKRouter/Framework/Core/*.h"
    core.public_header_files = "ZIKRouter/*.h",
                               "ZIKRouter/Router/*.h",
                               "ZIKRouter/Router/**/*.h",
                               "ZIKRouter/ServiceRouter/*.h",
                               "ZIKRouter/ServiceRouter/**/*.h",
                               "ZIKRouter/Utilities/*.h",
                               "ZIKRouter/Framework/Core/*.h"
    core.private_header_files = "ZIKRouter/Router/Private/*.h",
                                "ZIKRouter/ServiceRouter/BlockRouter/ZIKBlockServiceRouter.h",
                                "ZIKRouter/Utilities/Debug/*.h"
  end

  s.subspec 'ViewRouter' do |viewRouter|
    viewRouter.dependency 'ZIKRouter/Core'
    s.preserve_path = 'ZIKRouter/Framework/ViewRouter/module.modulemap'
    s.module_map = 'ZIKRouter/Framework/ViewRouter/module.modulemap'
    viewRouter.source_files = "ZIKRouter/ViewRouter/*.{h,m,mm,cpp}",
                              "ZIKRouter/ViewRouter/**/*.{h,m,mm,cpp}",
                              "ZIKRouter/ViewRouter/**/**/*.{h,m,mm,cpp}",
                              "ZIKRouter/Framework/ViewRouter/*.h"
    viewRouter.public_header_files = "ZIKRouter/ViewRouter/*.h",
                                     "ZIKRouter/ViewRouter/**/*.h",
                                     "ZIKRouter/Framework/ViewRouter/*.h"
    viewRouter.private_header_files = "ZIKRouter/ViewRouter/Private/*.h",
                                      "ZIKRouter/ViewRouter/BlockRouter/BlockViewRouters/*.h"
  end

end
