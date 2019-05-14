Pod::Spec.new do |s|

  s.name         = "ZIKRouter"
  s.version      = "1.0.12"
  s.summary      = "Interface-Oriented iOS router for discovering modules and injecting dependencies with protocol in both Swift and Objective-C."
  s.description  = <<-DESC
                Interface-Oriented iOS router for discovering modules and injecting dependencies with protocol in both Swift and Objective-C, designed for VIPER. The view router can perform all navigation types in UIKit through one method. The service router can discover service with protocol.
                   DESC
  s.homepage         = "https://github.com/Zuikyo/ZIKRouter"
  s.license      = "MIT"
  s.author       = { "Zuikyo" => "zuikxyo@gmail.com" }

  s.ios.deployment_target = "7.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"


  s.source       = { :git => "https://github.com/Zuikyo/ZIKRouter.git", :tag => "#{s.version}" }

  s.ios.frameworks = "Foundation", "UIKit"
  s.tvos.frameworks = "Foundation", "UIKit"
  s.osx.frameworks = "Foundation", "AppKit"
  s.libraries = 'c++'
  s.requires_arc = true

  s.preserve_path = 'ZIKRouter/Framework/module.modulemap'
  s.module_map = 'ZIKRouter/Framework/module.modulemap'

  s.default_subspecs = 'ServiceRouter','ViewRouter'

  s.subspec 'ServiceRouter' do |serviceRouter|
    serviceRouter.source_files = "ZIKRouter/Router/*.{h,m,mm,cpp}",
                                 "ZIKRouter/Router/**/*.{h,m,mm,cpp}",
                                 "ZIKRouter/ServiceRouter/*.{h,m,mm,cpp}",
                                 "ZIKRouter/ServiceRouter/**/*.{h,m,mm,cpp}",
                                 "ZIKRouter/Utilities/*.{h,m,mm,cpp}",
                                 "ZIKRouter/Utilities/**/*.{h,m,mm,cpp}",
                                 "ZIKRouter/Utilities/**/**/*.{h,m,mm,cpp}",
                                 "ZIKRouter/Framework/*.h",
                                 "ZIKRouter/ViewRouter/BlockRouter/ZIKViewRoute.h",
                                 "ZIKRouter/ViewRouter/ZIKViewRouterInternal.h",
                                 "ZIKRouter/ViewRouter/Registry/ZIKViewRouteRegistry.h"
    serviceRouter.public_header_files = "ZIKRouter/*.h",
                                        "ZIKRouter/Router/*.h",
                                        "ZIKRouter/Router/**/*.h",
                                        "ZIKRouter/ServiceRouter/*.h",
                                        "ZIKRouter/ServiceRouter/**/*.h",
                                        "ZIKRouter/Utilities/*.h",
                                        "ZIKRouter/Framework/*.h",
                                        "ZIKRouter/ViewRouter/BlockRouter/ZIKViewRoute.h",
                                        "ZIKRouter/ViewRouter/ZIKViewRouterInternal.h",
                                        "ZIKRouter/ViewRouter/Registry/ZIKViewRouteRegistry.h"
    serviceRouter.private_header_files = "ZIKRouter/Router/Private/*.h",
                                         "ZIKRouter/ServiceRouter/BlockRouter/ZIKBlockServiceRouter.h"
                                         "ZIKRouter/Utilities/Debug/*.h"
  end

  s.subspec 'ViewRouter' do |viewRouter|
    viewRouter.dependency 'ZIKRouter/ServiceRouter'
    viewRouter.source_files = "ZIKRouter/ViewRouter/*.{h,m,mm,cpp}",
                              "ZIKRouter/ViewRouter/**/*.{h,m,mm,cpp}",
                              "ZIKRouter/ViewRouter/**/**/*.{h,m,mm,cpp}"
    viewRouter.public_header_files = "ZIKRouter/ViewRouter/*.h",
                                     "ZIKRouter/ViewRouter/**/*.h"
    viewRouter.private_header_files = "ZIKRouter/ViewRouter/Private/*.h",
                                      "ZIKRouter/ViewRouter/BlockRouter/ZIKBlockViewRouter.h"
  end

  s.subspec 'ServiceURLRouter' do |serviceURLRouter|
    serviceURLRouter.dependency 'ZIKRouter/ServiceRouter'
    serviceURLRouter.source_files = "ZIKRouter/URLRouter/ZIKURLRouter.{h,m}",
                                    "ZIKRouter/URLRouter/ZIKRouter+URLRouter.{h,m}",
                                    "ZIKRouter/URLRouter/ZIKURLRouteResult.{h,m}"
    serviceURLRouter.public_header_files = "ZIKRouter/URLRouter/ZIKRouter+URLRouter.h",
                                           "ZIKRouter/URLRouter/ZIKURLRouteResult.h"
    serviceURLRouter.private_header_files = "ZIKRouter/URLRouter/ZIKURLRouter.h"
  end

  s.subspec 'ViewURLRouter' do |viewURLRouter|
    viewURLRouter.dependency 'ZIKRouter/ViewRouter'
    viewURLRouter.dependency 'ZIKRouter/ServiceURLRouter'
    viewURLRouter.source_files = "ZIKRouter/URLRouter/ZIKViewRouter+URLRouter.{h,m}"
    viewURLRouter.public_header_files = "ZIKRouter/URLRouter/ZIKViewRouter+URLRouter.h"
  end

  s.subspec 'URLRouter' do |urlRouter|
    urlRouter.dependency 'ZIKRouter/ServiceURLRouter'
    urlRouter.dependency 'ZIKRouter/ViewURLRouter'
  end

end
