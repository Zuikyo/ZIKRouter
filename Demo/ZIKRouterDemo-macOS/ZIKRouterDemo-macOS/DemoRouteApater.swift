//
//  DemoApater.swift
//  ZIKRouterDemo-macOS
//
//  Created by zuik on 2018/10/27.
//  Copyright © 2018 duoyi. All rights reserved.
//

import ZIKRouter
import ZIKRouter.Internal
import ZRouter

import ZIKLoginModule

class DemoRouteApater: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        // Adapt login view and alert required by login view
        self.register(adapter: RoutableView<RequiredLoginViewInput>(), forAdaptee: RoutableView<ZIKLoginViewInput>())
        
        // You can adapt other alert module. In ZIKRouterDemo-macOS, it's `NSAlert` in `AlertViewRouter`. in ZIKRouterDemo, it's ZIKAlertModule
        self.register(adapter: RoutableViewModule<ZIKLoginModuleRequiredAlertInput>(), forAdaptee: RoutableViewModule<AlertViewModuleInput>())
    }
}

// MARK: Adapt Login View

protocol RequiredLoginViewInput {
    
}
extension RoutableView where Protocol == RequiredLoginViewInput {
    init() { self.init(declaredTypeName: "RequiredLoginViewInput") }
}
extension ZIKLoginViewController: RequiredLoginViewInput {
    
}

// MARK: Adapt Alert

extension AlertViewConfiguration: ZIKLoginModuleRequiredAlertInput {
    func addCancelButtonTitle(_ cancelButtonTitle: String, handler: (() -> Void)? = nil) {
        addCancelButton(withTitle: cancelButtonTitle, handler: handler)
    }
    
    func addOtherButtonTitle(_ otherButtonTitle: String, handler: (() -> Void)? = nil) {
        addButton(withTitle: otherButtonTitle, handler: handler)
    }
    
    func addDestructiveButtonTitle(_ destructiveButtonTitle: String, handler: @escaping () -> Void) {
        addButton(withTitle: destructiveButtonTitle, handler: handler)
    }
    
    
}
