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
