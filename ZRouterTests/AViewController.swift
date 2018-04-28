//
//  AViewController.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import UIKit
import ZRouter
import ZIKRouter
import ZIKRouter.Internal

class AViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}

protocol AViewInput: class {
    var title: String? { get set }
}

extension AViewController: ZIKRoutableView, AViewInput {
    
}

extension RoutableView where Protocol == AViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol AViewModuleInput: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AViewInput) -> Void)
}

extension RoutableViewModule where Protocol == AViewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class AViewModuleConfiguration: ZIKViewRouteConfiguration, AViewModuleInput {
    var completion: ((AViewInput) -> Void)?
    
    var title: String?
    func makeDestinationCompletion(_ block: @escaping (AViewInput) -> Void) {
        completion = block
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! AViewModuleConfiguration
        copy.title = self.title
        return copy
    }
}

class AViewRouter: ZIKViewRouter<AViewController, AViewModuleConfiguration> {
    
    override class func registerRoutableDestination() {
        registerView(AViewController.self)
        register(RoutableView<AViewInput>())
        register(RoutableViewModule<AViewModuleInput>())
    }
    
    override class func defaultRouteConfiguration() -> AViewModuleConfiguration {
        return AViewModuleConfiguration()
    }
    
    override func destination(with configuration: AViewModuleConfiguration) -> AViewController? {
        if TestConfig.routeShouldFail {
            return nil
        }
        return AViewController()
    }
    
    override func prepareDestination(_ destination: AViewController, configuration: AViewModuleConfiguration) {
        if let title = configuration.title {
            destination.title = title
        }
    }
    
    override func didFinishPrepareDestination(_ destination: AViewController, configuration: AViewModuleConfiguration) {
        if let completion = configuration.completion {
            completion(destination)
        }
    }
    
}
