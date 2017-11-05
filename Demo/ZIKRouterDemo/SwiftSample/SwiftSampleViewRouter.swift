//
//  SwiftSampleViewRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017 zuik. All rights reserved.
//

import UIKit
import ZIKRouter
import ZIKRouterSwift

//Declare SwiftSampleViewController is routable
extension SwiftSampleViewController: ZIKRoutableView {
}

protocol SwiftSampleViewConfig {
    
}

class SwiftSampleViewConfiguration: ZIKViewRouteConfiguration, SwiftSampleViewConfig {
    override func copy(with zone: NSZone? = nil) -> Any {
        return super.copy(with: zone)
    }
}

class SwiftSampleViewRouter: ZIKViewRouter<SwiftSampleViewConfiguration, ZIKViewRemoveConfiguration> {
    override class func registerRoutableDestination() {
        registerView(SwiftSampleViewController.self)
        registerViewProtocol(SwiftSampleViewInput.self)
        Router.register(viewProtocol: PureSwiftSampleViewInput.self, router: self)
        Router.register(viewModule: SwiftSampleViewConfig.self, router: self)
    }
    
    override class func defaultRouteConfiguration() -> ZIKViewRouteConfiguration {
        return SwiftSampleViewConfiguration()
    }
    
    override func destination(with configuration: ZIKViewRouteConfiguration) -> ZIKRoutableView? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
        return destination
    }
    override static func destinationPrepared(_ destination: Any) -> Bool {
        if let dest = destination as? SwiftSampleViewController {
            if (dest.alertRouterClass != nil) {
                return true
            }
        }
        return false
    }
    override func prepareDestination(_ destination: Any, configuration: ZIKViewRouteConfiguration) {
        if let dest = destination as? SwiftSampleViewController {
            dest.alertRouterClass = ZIKViewRouterForConfig(ZIKCompatibleAlertConfigProtocol.self) as! ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>.Type
        }
    }
}

extension ViewRouter where Destination == SwiftSampleViewInput {
    static var route: ViewRoute<SwiftSampleViewInput>.Type {
        return ViewRoute<SwiftSampleViewInput>.self
    }
}

extension ViewRouter where Destination == PureSwiftSampleViewInput {
    static var route: ViewRoute<PureSwiftSampleViewInput>.Type {
        return ViewRoute<PureSwiftSampleViewInput>.self
    }
}

extension ViewModuleRouter where Module == SwiftSampleViewConfig {
    static var route: ViewModuleRoute<SwiftSampleViewConfig>.Type {
        return ViewModuleRoute<SwiftSampleViewConfig>.self
    }
}

