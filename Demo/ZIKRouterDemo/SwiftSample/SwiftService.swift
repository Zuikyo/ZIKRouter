//
//  SwiftService.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

import Foundation
import ZIKRouter
import ZRouter

protocol SwiftServiceInput {
    func swiftFunction()
}

protocol SwiftServiceInput2 {
    
}

class SwiftService: SwiftServiceInput, SwiftServiceInput2 {
    func swiftFunction() {
        print("this is a swift function")
        _ = Router.perform(
            for: RoutableViewModule<ZIKCompatibleAlertConfigProtocol>(),
            routeConfig: { config in
                config.source = UIApplication.shared.keyWindow?.rootViewController
                config.routeType = ViewRouteType.custom
        },
            preparation: { module in
                module.title = "SwiftService"
                module.message = "This is a swift service"
                module.addCancelButtonTitle("Cancel", handler: {
                    print("Tap cancel alert")
                })
                module.addOtherButtonTitle("OK", handler: {
                    print("Tap OK alert")
                })
            })
    }
}
