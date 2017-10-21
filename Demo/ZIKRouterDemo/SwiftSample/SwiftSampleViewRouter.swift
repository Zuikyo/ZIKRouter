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
        registerViewProtocol(SwiftSampleViewProtocol.self)
        Router.registerViewConfig(SwiftSampleViewConfig.self, router: self)
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
        if let des = destination as? SwiftSampleViewController {
            if (des.alertRouterClass != nil) {
                return true
            }
        }
        return false
    }
    override func prepareDestination(_ destination: Any, configuration: ZIKViewRouteConfiguration) {
        if let des = destination as? SwiftSampleViewController {
            des.alertRouterClass = ZIKViewRouterForConfig(ZIKCompatibleAlertConfigProtocol.self) as! ZIKViewRouter<ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol, ZIKViewRemoveConfiguration>.Type
        }
    }
}
