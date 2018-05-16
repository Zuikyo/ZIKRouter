//
//  BSubview.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import UIKit
import ZRouter
import ZIKRouter
import ZIKRouter.Internal

class BSubview: UIView {
    var title: String?
}

protocol BSubviewInput: class {
    var title: String? { get set }
}

extension BSubview: ZIKRoutableView, BSubviewInput {
    
}

extension RoutableView where Protocol == BSubviewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol BSubviewModuleInput: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (BSubviewInput) -> Void)
}

extension RoutableViewModule where Protocol == BSubviewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class BSubviewModuleConfiguration: ZIKViewRouteConfiguration, BSubviewModuleInput {
    var completion: ((BSubviewInput) -> Void)?
    
    var title: String?
    func makeDestinationCompletion(_ block: @escaping (BSubviewInput) -> Void) {
        completion = block
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! BSubviewModuleConfiguration
        copy.title = self.title
        return copy
    }
}

class BSubviewRouter: ZIKViewRouter<BSubview, BSubviewModuleConfiguration> {
    
    override class func registerRoutableDestination() {
        registerView(BSubview.self)
        if !TEST_BLOCK_ROUTE {
            register(RoutableView<BSubviewInput>())
            register(RoutableViewModule<BSubviewModuleInput>())
        }
    }
    
    override class func defaultRouteConfiguration() -> BSubviewModuleConfiguration {
        return BSubviewModuleConfiguration()
    }
    
    override class func supportedRouteTypes() -> ZIKViewRouteTypeMask {
        return .viewDefault
    }
    
    override func destination(with configuration: BSubviewModuleConfiguration) -> BSubview? {
        if TestConfig.routeShouldFail {
            return nil
        }
        return BSubview()
    }
    
    override func prepareDestination(_ destination: BSubview, configuration: BSubviewModuleConfiguration) {
        if let title = configuration.title {
            destination.title = title
        }
    }
    
    override func didFinishPrepareDestination(_ destination: BSubview, configuration: BSubviewModuleConfiguration) {
        if let completion = configuration.completion {
            completion(destination)
            configuration.completion = nil
        }
    }
    
}
