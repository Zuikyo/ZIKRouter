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

protocol ASwiftViewModuleInput: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (ASwiftViewInput) -> Void)
}

class ASwiftViewModuleConfiguration: ViewRouteConfig, ASwiftViewModuleInput {
    var makeDestinationCompletion: ((ASwiftViewInput) -> Void)?
    var title: String?
    
    func makeDestinationCompletion(_ block: @escaping (ASwiftViewInput) -> Void) {
        self.makeDestinationCompletion = block
    }
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ASwiftViewModuleConfiguration
        copy.title = self.title
        return copy
    }
}

extension RoutableViewModule where Protocol == ASwiftViewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class ASwiftViewRouter: ZIKViewRouter<ASwiftViewController, ASwiftViewModuleConfiguration> {
    
    override class func registerRoutableDestination() {
        registerView(ASwiftViewController.self)
        register(RoutableView<ASwiftViewInput>())
        register(RoutableViewModule<ASwiftViewModuleInput>())
    }
    
    override class func defaultRouteConfiguration() -> ASwiftViewModuleConfiguration {
        return ASwiftViewModuleConfiguration()
    }
    
    override func destination(with configuration: ASwiftViewModuleConfiguration) -> ASwiftViewController? {
        let destination = ASwiftViewController()
        return destination
    }
    
    override func prepareDestination(_ destination: ASwiftViewController, configuration: ASwiftViewModuleConfiguration) {
        
    }
    
    override func didFinishPrepareDestination(_ destination: ASwiftViewController, configuration: ASwiftViewModuleConfiguration) {
        if let completion = configuration.makeDestinationCompletion {
            completion(destination)
            configuration.makeDestinationCompletion = nil
        }
    }
    
    override class func supportedRouteTypes() -> ZIKViewRouteTypeMask {
        return [.viewControllerDefault, .custom]
    }
    
    override func canPerformCustomRoute() -> Bool {
        return true
    }
    
    override func performCustomRoute(onDestination destination: ASwiftViewController, fromSource s: Any?, configuration: ASwiftViewModuleConfiguration) {
        beginPerformRoute()
        guard let source = s as? UIViewController else {
            endPerformRouteWithError(ZIKAnyViewRouter.viewRouteError(withCode: .invalidSource, localizedDescription: "Source \(String(describing: s)) should be UIViewController"))
            return
        }
        source.addChildViewController(destination)
        destination.view.frame = source.view.frame
        destination.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5, animations: {
            destination.view.backgroundColor = .red
            source.view.addSubview(destination.view)
            destination.view.transform = CGAffineTransform.identity
        }) { (finished) in
            destination.didMove(toParentViewController: source)
            self.endPerformRouteWithSuccess()
        }
    }
    
    override func canRemoveCustomRoute() -> Bool {
        return _canRemoveFromParentViewController()
    }
    
    override func removeCustomRoute(onDestination destination: ASwiftViewController, fromSource s: Any?, removeConfiguration: ZIKViewRemoveConfiguration, configuration: ASwiftViewModuleConfiguration) {
        beginRemoveRoute(fromSource: s)
        guard let source = s as? UIViewController else {
            endRemoveRouteWithError(ZIKAnyViewRouter.viewRouteError(withCode: .invalidSource, localizedDescription: "Source \(String(describing: s)) should be UIViewController"))
            return
        }
        destination.willMove(toParentViewController: nil)
        destination.view.transform = CGAffineTransform.identity
        UIView.animate(withDuration: 0.5, animations: {
            destination.view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { (finished) in
            destination.view.removeFromSuperview()
            destination.removeFromParentViewController()
            self.endRemoveRouteWithSuccess(onDestination: destination, fromSource: source)
        }
    }
}



