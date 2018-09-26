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
    var viewTitle: String? { get set }
}

@objc protocol AViewObjcInput: ZIKViewRoutable {
    var title: String? { get set }
}

protocol AViewInputAdapter: class {
    var title: String? { get set }
}

@objc protocol AViewInputObjcAdapter: ZIKViewRoutable {
    var title: String? { get set }
}

extension AViewController: ZIKRoutableView, AViewInput, AViewObjcInput, AViewInputAdapter, AViewInputObjcAdapter {
    var viewTitle: String? {
        get {
            return title
        }
        set {
            title = newValue
        }
    }
}

extension RoutableView where Protocol == AViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension RoutableView where Protocol == UIViewController & AViewInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension RoutableView where Protocol == UIViewController & AViewObjcInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension RoutableView where Protocol == AViewInputAdapter {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol AViewModuleInput: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AViewInput) -> Void)
}

protocol AViewModuleInputAdapter: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AViewInput) -> Void)
}

@objc protocol AViewModuleInputObjcAdapter: ZIKViewModuleRoutable {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AViewInputObjcAdapter) -> Void)
}

extension RoutableViewModule where Protocol == AViewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension RoutableViewModule where Protocol == AViewModuleInputAdapter {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class AViewModuleConfiguration: ZIKViewRouteConfiguration, AViewModuleInput, AViewModuleInputAdapter, AViewModuleInputObjcAdapter {
    var completion: ((AViewInput) -> Void)?
    var objcCompletion: ((AViewInputObjcAdapter) -> Void)?
    
    var title: String?
    func makeDestinationCompletion(_ block: @escaping (AViewInput) -> Void) {
        completion = block
    }
    func makeDestinationCompletion(_ block: @escaping (AViewInputObjcAdapter) -> Void) {
        objcCompletion = block
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
        if !TEST_BLOCK_ROUTE {
            register(RoutableView<AViewInput>())
            register(RoutableView<AViewObjcInput>())
            register(RoutableView<UIViewController & AViewObjcInput>())
            register(RoutableViewModule<AViewModuleInput>())
            register(RoutableView<UIViewController & AViewInput>())
        }
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
            configuration.completion = nil
        } else if let completion = configuration.objcCompletion {
            completion(destination)
            configuration.objcCompletion = nil
        }
    }
    
}

class AViewAdapter: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        register(adapter: RoutableView<AViewInputAdapter>(), forAdaptee: RoutableView<AViewInput>())
        register(adapter: RoutableView<AViewInputObjcAdapter>(), forAdaptee: RoutableView<AViewInput>())
        register(adapter: RoutableViewModule<AViewModuleInputAdapter>(), forAdaptee: RoutableViewModule<AViewModuleInput>())
        register(adapter: RoutableViewModule<AViewModuleInputObjcAdapter>(), forAdaptee: RoutableViewModule<AViewModuleInput>())
    }
}
