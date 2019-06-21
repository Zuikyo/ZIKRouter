//
//  DecoupleSampleViewRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2019/6/22.
//Copyright © 2019 zuik. All rights reserved.
//

import ZRouter
import ZIKRouter.Internal

class DecoupleSampleViewRouter: ZIKViewRouter<DecoupleSampleViewController, ViewRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerExclusiveView(DecoupleSampleViewController.self)
        register(RoutableView<DecoupleSampleViewInput>())
    }
    
    override func destination(with configuration: ViewRouteConfig) -> DecoupleSampleViewController? {
        let destination: DecoupleSampleViewController? = DecoupleSampleViewController()
        return destination
    }
    
    override func prepareDestination(_ destination: DecoupleSampleViewController, configuration: ViewRouteConfig) {
        // Prepare destination
    }
    
}

@objc protocol DecoupleSampleViewInput: ZIKViewRoutable {
    
}

extension DecoupleSampleViewController: ZIKRoutableView, DecoupleSampleViewInput {
    
}
