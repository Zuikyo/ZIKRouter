//
//  SwiftSampleViewRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017 zuik. All rights reserved.
//

import UIKit
import ZIKRouter.Internal
import ZRouter

protocol SwiftSampleViewModuleInput {
    
}

//Custom configuration of this router.
class SwiftSampleViewConfiguration: ZIKViewMakeableConfiguration<SwiftSampleViewController>, SwiftSampleViewModuleInput {

}

//Router for SwiftSampleViewController.
class SwiftSampleViewRouter: ZIKViewRouter<SwiftSampleViewController, ZIKViewMakeableConfiguration<SwiftSampleViewController>> {
    
    override class func registerRoutableDestination() {
        registerView(SwiftSampleViewController.self)
        register(RoutableView<SwiftSampleViewInput>())
        register(RoutableView<PureSwiftSampleViewInput>())
        register(RoutableViewModule<SwiftSampleViewModuleInput>())
        registerIdentifier("swiftSample")
    }
    
    override class func defaultRouteConfiguration() -> ZIKViewMakeableConfiguration<SwiftSampleViewController> {
        return SwiftSampleViewConfiguration()
    }
    
    override func destination(with configuration: ZIKViewMakeableConfiguration<SwiftSampleViewController>) -> SwiftSampleViewController? {
        if let make = configuration.makeDestination {
            return make()
        }
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
        destination.title = "Swift Sample"
        return destination
    }
    
    override func destinationFromExternalPrepared(destination: SwiftSampleViewController) -> Bool {
        if (destination.injectedAlertRouter != nil) {
            return true
        }
        return false
    }
    override func prepareDestination(_ destination: SwiftSampleViewController, configuration: ZIKViewRouteConfiguration) {
        destination.injectedAlertRouter = Router.to(RoutableViewModule<RequiredCompatibleAlertModuleInput>())
    }
}

// MARK: Declare Routable

//Declare SwiftSampleViewController is routable
extension SwiftSampleViewController: ZIKRoutableView {
}

//Declare PureSwiftSampleViewInput is routable
extension RoutableView where Protocol == PureSwiftSampleViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
//Declare SwiftSampleViewConfig is routable
extension RoutableViewModule where Protocol == SwiftSampleViewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
