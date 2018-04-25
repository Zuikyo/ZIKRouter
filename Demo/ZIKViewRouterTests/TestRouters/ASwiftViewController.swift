//
//  ASwiftViewController.swift
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/26.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter

class ASwiftViewController: UIViewController {
    
}

// MARK: View Router

protocol ASwiftViewInput: class {
    var title: String? { get set }
}

extension ASwiftViewController: ZIKRoutableView {
    
}

extension ASwiftViewController: ASwiftViewInput {
    
}

extension RoutableView where Protocol == ASwiftViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

// MARK: View Module Router

protocol ASwiftViewMdouleInput: class {
    var title: String? { get set }
}

class ASwiftViewModuleConfiguration: ViewRouteConfig, ASwiftViewMdouleInput {
    var title: String?
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ASwiftViewModuleConfiguration
        copy.title = self.title
        return copy
    }
}

extension RoutableViewModule where Protocol == ASwiftViewMdouleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class ASwiftViewRouter: ZIKViewRouter<ASwiftViewController, ViewRouteConfig> {
    
    override class func registerRoutableDestination() {
        registerView(ASwiftViewController.self)
        register(RoutableView<ASwiftViewInput>())
        register(RoutableViewModule<ASwiftViewMdouleInput>())
    }
    
    override class func defaultRouteConfiguration() -> ViewRouteConfig {
        return ASwiftViewModuleConfiguration()
    }
    
    override func destination(with configuration: ViewRouteConfig) -> ASwiftViewController? {
        let destination = ASwiftViewController()
        return destination
    }
    
    override func prepareDestination(_ destination: ASwiftViewController, configuration: ViewRouteConfig) {
        
    }
    
    override func didFinishPrepareDestination(_ destination: ASwiftViewController, configuration: ViewRouteConfig) {
        
    }
}



