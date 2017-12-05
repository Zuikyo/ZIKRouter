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

protocol SwiftSampleViewConfig {
    
}

//Custom configuration of this router.
class SwiftSampleViewConfiguration: ZIKViewRouteConfiguration, SwiftSampleViewConfig {
    override func copy(with zone: NSZone? = nil) -> Any {
        return super.copy(with: zone)
    }
}

//Router for SwiftSampleViewController.
class SwiftSampleViewRouter: ZIKViewRouter<SwiftSampleViewController, SwiftSampleViewConfiguration> {
    
    override class func registerRoutableDestination() {
        registerView(SwiftSampleViewController.self)
        registerViewProtocol(SwiftSampleViewInput.self)
        Registry.register(RoutableView<PureSwiftSampleViewInput>(), forRouter: self)
        Registry.register(RoutableViewModule<SwiftSampleViewConfig>(), forRouter: self)
    }
    
    override class func _autoRegistrationDidFinished() {
        //Make sure all routable dependencies in this module is available.
        assert((Registry.router(to: RoutableService<SwiftServiceInput>()) != nil))
    }
    
    override class func defaultRouteConfiguration() -> SwiftSampleViewConfiguration {
        return SwiftSampleViewConfiguration()
    }
    
    override func destination(with configuration: SwiftSampleViewConfiguration) -> SwiftSampleViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
        return destination
    }
    
    override static func destinationPrepared(_ destination: SwiftSampleViewController) -> Bool {
        if (destination.injectedAlertRouter != nil) {
            return true
        }
        return false
    }
    override func prepareDestination(_ destination: SwiftSampleViewController, configuration: ZIKViewRouteConfiguration) {
        destination.injectedAlertRouter = Registry.router(to: RoutableViewModule<ZIKCompatibleAlertConfigProtocol>())
    }
}

// MARK: Declare Routable

//Declare SwiftSampleViewController is routable
extension SwiftSampleViewController: ZIKRoutableView {
}

//Declare PureSwiftSampleViewInput is routable
extension RoutableView where Protocol == PureSwiftSampleViewInput {
    init() { }
}
//Declare PureSwiftSampleViewInput is routable
extension RoutableView where Protocol == PureSwiftSampleViewInput2 {
    init() { }
}
//Declare SwiftSampleViewConfig is routable
extension RoutableViewModule where Protocol == SwiftSampleViewConfig {
    init() { }
}
