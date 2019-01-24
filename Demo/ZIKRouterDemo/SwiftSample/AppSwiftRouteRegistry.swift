//
//  AppSwiftRouteRegistry.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter
import ZIKRouter

/// Manually register swift routers
@objc class AppSwiftRouteRegistry: NSObject {
    @objc class func manuallyRegisterEachRouter() {
        SwiftSampleViewRouter.registerRoutableDestination()
        SwiftServiceRouter.registerRoutableDestination()
        ZIKInfoViewAdapter.registerRoutableDestination()
        AppBlockRouteRegistry.registerRoutableDestination()
        EasyRouteRegistry.registerRoutableDestination()
    }
}

import ZIKRouter.Internal

class AppBlockRouteRegistry: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        do {
            let route = ZIKServiceRoute<SwiftService, PerformRouteConfig>
                .make(withDestination: SwiftService.self,
                      makeDestination: { (config, router) -> SwiftService? in
                        return SwiftService()
                }).makeDefaultConfiguration({
                    return SwiftServiceConfiguration()
                })
            if TEST_BLOCK_ROUTES == 1 {
                route.register(RoutableService<SwiftServiceInput>())
                route.register(RoutableServiceModule<SwiftServiceConfig>())
            }
        }
    }
}

typealias RequiredInfoViewInput = UIViewController & ZIKInfoViewProtocol
class ZIKInfoViewAdapter: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        register(adapter: RoutableView<UIViewController & ZIKInfoViewProtocol>(), forAdaptee: RoutableView<ZIKInfoViewProtocol>())
    }
}

extension RoutableView where Protocol == RequiredInfoViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}




class EasyRouteRegistry: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        ZIKAnyViewRouter.register(RoutableView<EasyViewInput>(), forMakingView: SwiftSampleViewController.self)
        ZIKAnyViewRouter.register(RoutableView<EasyViewInput2>(), forMakingView: SwiftSampleViewController.self) { (config, router) -> EasyViewInput2? in
            let sb = UIStoryboard.init(name: "Main", bundle: nil)
            let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
            destination.title = "Swift Sample from easy register"
            destination.injectedAlertRouter = Router.to(RoutableViewModule<RequiredCompatibleAlertModuleInput>())
            return destination
        }
        
        ZIKAnyServiceRouter.register(RoutableService<EasyServiceInput>(), forMakingService: EasyService.self)
        ZIKAnyServiceRouter.register(RoutableService<EasyServiceInput2>(), forMakingService: EasyService2.self) { (config, router) -> EasyServiceInput2? in
            return EasyService2(name: "default")
        }
    }
}

protocol EasyViewInput { }
extension RoutableView where Protocol == EasyViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol EasyViewInput2 { }
extension RoutableView where Protocol == EasyViewInput2 {
    init() { self.init(declaredProtocol: Protocol.self) }
}
extension SwiftSampleViewController: EasyViewInput, EasyViewInput2 { }

protocol EasyServiceInput { }
extension RoutableService where Protocol == EasyServiceInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol EasyServiceInput2 { }
extension RoutableService where Protocol == EasyServiceInput2 {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class EasyService: NSObject, ZIKRoutableService, EasyServiceInput {
    
}

class EasyService2: NSObject, ZIKRoutableService, EasyServiceInput, EasyServiceInput2 {
    let name: String
    init(name: String) {
        self.name = name
    }
}


