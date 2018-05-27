//
//  SwiftService.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

import Foundation
import ZRouter

protocol SwiftServiceInput {
    func swiftFunction()
}

class SwiftService: SwiftServiceInput {
    func swiftFunction() {
        print("this is a swift function")
        _ = Router.perform(
            to: RoutableViewModule<RequiredCompatibleAlertModuleInput>(),
            path: .custom(from: UIApplication.shared.keyWindow?.rootViewController),
            configuring: { (config, prepareModule) in
                prepareModule({ module in
                    module.title = "SwiftService"
                    module.message = "This is a swift service"
                    module.addCancelButtonTitle("Cancel", handler: {
                        print("Tap cancel alert")
                    })
                    module.addOtherButtonTitle("OK", handler: {
                        print("Tap OK alert")
                    })
                })
        })
    }
}
