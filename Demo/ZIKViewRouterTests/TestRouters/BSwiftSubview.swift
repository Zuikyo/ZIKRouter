//
//  BSwiftSubview.swift
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/26.
//  Copyright © 2018 zuik. All rights reserved.
//

import UIKit
import ZRouter

class BSwiftSubview: UIView {
    var title: String?
}

// MARK: View Router

protocol BSwiftSubviewInput: class {
    var title: String? { get set }
}

extension BSwiftSubview: ZIKRoutableView {
    
}

extension BSwiftSubview: BSwiftSubviewInput {
    
}

extension RoutableView where Protocol == BSwiftSubviewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

// MARK: View Module Router

protocol BSwiftSubviewModuleInput: class {
    var title: String? { get set }
}

class BSwiftSubviewModuleConfiguration: ViewRouteConfig, BSwiftSubviewModuleInput {
    var title: String?
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! BSwiftSubviewModuleConfiguration
        copy.title = self.title
        return copy
    }
}

extension RoutableViewModule where Protocol == BSwiftSubviewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class BSwiftSubviewRouter: ZIKViewRouter<BSwiftSubview, ViewRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerView(BSwiftSubview.self)
        register(RoutableView<BSwiftSubviewInput>())
        register(RoutableViewModule<BSwiftSubviewModuleInput>())
    }
    
    override class func supportedRouteTypes() -> ZIKViewRouteTypeMask {
        return .uiViewDefault
    }
    
    override class func defaultRouteConfiguration() -> ViewRouteConfig {
        return BSwiftSubviewModuleConfiguration()
    }
    
    override func destination(with configuration: ViewRouteConfig) -> BSwiftSubview? {
        let destination = BSwiftSubview()
        return destination
    }
    
    override func prepareDestination(_ destination: BSwiftSubview, configuration: ViewRouteConfig) {
        
    }
    
    override func didFinishPrepareDestination(_ destination: BSwiftSubview, configuration: ViewRouteConfig) {
        
    }
}
