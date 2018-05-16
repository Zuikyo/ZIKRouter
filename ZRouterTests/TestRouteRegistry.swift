//
//  TestRouteRegistry.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter
import ZIKRouter.Internal

class TestRouteRegistry {
    static var registerRoutes: () = {
        ZIKRouteRegistry.autoRegister = false
        
        registerServiceRouter()
        registerViewRouter()
        
        ZIKRouteRegistry.notifyRegistrationFinished()
    }()
    
    class func setUp() {
        _ = self.registerRoutes
    }
    
    class func registerServiceRouter() {
        AServiceRouter.registerRoutableDestination()
        
        let route = ZIKServiceRoute<AService, AServiceModuleConfiguration>
            .make(withDestination: AService.self, makeDestination: { (config, router) -> AService? in
                if TestConfig.routeShouldFail {
                    return nil
                }
                return AService()
            }).makeDefaultConfiguration({
                return AServiceModuleConfiguration()
            }).prepareDestination({ (destination, config, router) in
                if let title = config.title {
                    destination.title = title
                }
            }).didFinishPrepareDestination({ (destination, config, router) in
                if let completion = config.completion {
                    completion(destination)
                    config.completion = nil
                }
            })
        
        if TEST_BLOCK_ROUTE {
            _ = route.register(RoutableService<AServiceInput>())
                .register(RoutableServiceModule<AServiceModuleInput>())
        }
        
        AServiceAdapter.registerRoutableDestination()
    }
    
    class func registerViewRouter() {
        AViewRouter.registerRoutableDestination()
        BSubviewRouter.registerRoutableDestination()
        
        do {
            let route = ZIKViewRoute<AViewController, AViewModuleConfiguration>
                .make(withDestination: AViewController.self, makeDestination: ({ (config, router) -> AViewController? in
                    if TestConfig.routeShouldFail {
                        return nil
                    }
                    return AViewController()
                })).makeDefaultConfiguration({
                    return AViewModuleConfiguration()
                }).prepareDestination({ (destination, config, router) in
                    if let title = config.title {
                        destination.title = title
                    }
                }).didFinishPrepareDestination({ (destination, config, router) in
                    if let completion = config.completion {
                        completion(destination)
                        config.completion = nil
                    } else if let completion = config.objcCompletion {
                        completion(destination)
                        config.objcCompletion = nil
                    }
                })
            if TEST_BLOCK_ROUTE {
                _ = route.register(RoutableView<AViewInput>())
                    .register(RoutableView<AViewObjcInput>())
                    .register(RoutableView<UIViewController & AViewObjcInput>())
                    .register(RoutableViewModule<AViewModuleInput>())
                    .register(RoutableView<UIViewController & AViewInput>())
            }
        }
        
        do {
            let route = ZIKViewRoute<BSubview, BSubviewModuleConfiguration>
                .make(withDestination: BSubview.self, makeDestination: ({ (config, router) -> BSubview? in
                    if TestConfig.routeShouldFail {
                        return nil
                    }
                    return BSubview()
                })).makeSupportedRouteTypes({
                    return .viewDefault
                }).makeDefaultConfiguration({
                    return BSubviewModuleConfiguration()
                }).prepareDestination({ (destination, config, router) in
                    if let title = config.title {
                        destination.title = title
                    }
                }).didFinishPrepareDestination({ (destination, config, router) in
                    if let completion = config.completion {
                        completion(destination)
                        config.completion = nil
                    }
                })
            if TEST_BLOCK_ROUTE {
                _ = route.register(RoutableView<BSubviewInput>())
                    .register(RoutableViewModule<BSubviewModuleInput>())
            }
        }
        
        
        AViewAdapter.registerRoutableDestination()
    }
}
