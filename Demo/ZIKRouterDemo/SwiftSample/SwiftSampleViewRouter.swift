//
//  SwiftSampleViewRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017 zuik. All rights reserved.
//

import UIKit
import ZIKRouter

//Declare SwiftSampleViewController is routable
extension SwiftSampleViewController: ZIKRoutableView {
}

class SwiftSampleViewRouter: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration> {
    override class func registerRoutableDestination() {
        ZIKViewRouter_registerView(SwiftSampleViewController.self, self)
        ZIKViewRouter_registerViewProtocol(SwiftSampleViewProtocol.self, self)
    }
    override func destination(with configuration: ZIKViewRouteConfiguration) -> ZIKRoutableView? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
        return destination
    }
    override func prepareDestination(_ destination: Any, configuration: ZIKViewRouteConfiguration) {
        if let des = destination as? SwiftSampleViewController {
            des.alertRouterClass = ZIKCompatibleAlertViewRouter.self
        }
    }
}
