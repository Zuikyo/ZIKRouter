//
//  SwiftService.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

import Foundation
import ZIKRouter

@objc protocol SwiftServiceProtocol {
    func swiftFunction()
}
class SwiftService: SwiftServiceProtocol {
    func swiftFunction() {
        print("this is a swift function")
        ZIKSViewRouterForConfig(ZIKCompatibleAlertConfigProtocol.self)?.perform { configuration in
            let config = configuration as! ZIKViewRouteConfiguration & ZIKCompatibleAlertConfigProtocol
            config.source = UIApplication.shared.keyWindow?.rootViewController
            config.title = "SwiftService"
            config.message = "This is a swift service"
            config.addCancelButtonTitle("Cancel", handler: {
                print("Tap cancel alert")
            })
            config.addOtherButtonTitle("OK", handler: {
                print("Tap OK alert")
            })
        }
    }
}
