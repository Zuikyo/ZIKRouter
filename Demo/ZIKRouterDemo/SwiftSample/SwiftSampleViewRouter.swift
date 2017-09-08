//
//  SwiftSampleViewRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/9/8.
//  Copyright © 2017年 zuik. All rights reserved.
//

import UIKit
import ZIKRouter

//Declare SwiftSampleViewController is routable
extension SwiftSampleViewController: ZIKRoutableView {
}

class SwiftSampleViewRouter: ZIKViewRouter {
    override static func registerRoutableDestination() {
        ZIKViewRouter_registerView(SwiftSampleViewController.self, self)
        ZIKViewRouter_registerViewProtocol(SwiftSampleViewProtocol.self, self)
    }
    override func destination(with configuration: ZIKViewRouteConfiguration) -> ZIKRoutableView? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "SwiftSampleViewController") as! SwiftSampleViewController
        return destination
    }
}
