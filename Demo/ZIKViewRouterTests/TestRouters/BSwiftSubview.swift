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
    func makeDestinationCompletion(_ block: @escaping (BSwiftSubviewInput) -> Void)
}

class BSwiftSubviewModuleConfiguration: ViewRouteConfig, BSwiftSubviewModuleInput {
    var makeDestinationCompletion: ((BSwiftSubviewInput) -> Void)?
    var title: String?
    
    func makeDestinationCompletion(_ block: @escaping (BSwiftSubviewInput) -> Void) {
        self.makeDestinationCompletion = block
    }
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! BSwiftSubviewModuleConfiguration
        copy.title = self.title
        return copy
    }
}

extension RoutableViewModule where Protocol == BSwiftSubviewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class BSwiftSubviewRouter: ZIKViewRouter<BSwiftSubview, BSwiftSubviewModuleConfiguration> {
    
    override class func registerRoutableDestination() {
        registerView(BSwiftSubview.self)
        register(RoutableView<BSwiftSubviewInput>())
        register(RoutableViewModule<BSwiftSubviewModuleInput>())
    }
    
    override class func defaultRouteConfiguration() -> BSwiftSubviewModuleConfiguration {
        return BSwiftSubviewModuleConfiguration()
    }
    
    override func destination(with configuration: BSwiftSubviewModuleConfiguration) -> BSwiftSubview? {
        let destination = BSwiftSubview()
        return destination
    }
    
    override func prepareDestination(_ destination: BSwiftSubview, configuration: BSwiftSubviewModuleConfiguration) {
        
    }
    
    override func didFinishPrepareDestination(_ destination: BSwiftSubview, configuration: BSwiftSubviewModuleConfiguration) {
        if let completion = configuration.makeDestinationCompletion {
            completion(destination)
            configuration.makeDestinationCompletion = nil
        }
    }
    
    override class func supportedRouteTypes() -> ZIKViewRouteTypeMask {
        return [.viewDefault, .custom]
    }
    
    override func canPerformCustomRoute() -> Bool {
        return true
    }
    
    override func performCustomRoute(onDestination destination: BSwiftSubview, fromSource s: Any?, configuration: BSwiftSubviewModuleConfiguration) {
        beginPerformRoute()
        guard let source = s as? UIView else {
            endPerformRouteWithError(ZIKAnyViewRouter.viewRouteError(withCode: .invalidSource, localizedDescription: "Source \(String(describing: s)) should be UIView"))
            return
        }
        source.addSubview(destination)
        endPerformRouteWithSuccess()
    }
    
    override func canRemoveCustomRoute() -> Bool {
        return _canRemoveFromSuperview()
    }
    
    override func removeCustomRoute(onDestination destination: BSwiftSubview, fromSource s: Any?, removeConfiguration: ZIKViewRemoveConfiguration, configuration: BSwiftSubviewModuleConfiguration) {
        beginRemoveRoute(fromSource: s)
        guard let source = s as? UIView else {
            endRemoveRouteWithError(ZIKAnyViewRouter.viewRouteError(withCode: .invalidSource, localizedDescription: "Source \(String(describing: s)) should be UIView"))
            return
        }
        destination.removeFromSuperview()
        endRemoveRouteWithSuccess(onDestination: destination, fromSource: source)
    }
}
