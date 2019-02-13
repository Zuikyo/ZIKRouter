//
//  AService.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter
import ZIKRouter
import ZIKRouter.Internal

class AService {
    var title: String?
}

protocol AServiceInput: class {
    var title: String? { get set }
}

protocol AServiceInputAdapter: class {
    var title: String? { get set }
}

protocol AServiceInputAdapter2: class {
    var title: String? { get set }
}

@objc protocol AServiceInputObjcAdapter: ZIKServiceRoutable {
    var title: String? { get set }
}

@objc protocol AServiceInputObjcAdapter2: ZIKServiceRoutable {
    var title: String? { get set }
}

@objc protocol AServiceInputObjcAdapter3: ZIKServiceRoutable {
    var title: String? { get set }
}

extension AService: ZIKRoutableService, AServiceInput, AServiceInputAdapter, AServiceInputAdapter2, AServiceInputObjcAdapter, AServiceInputObjcAdapter2, AServiceInputObjcAdapter3 {
    
}

extension RoutableService where Protocol == AServiceInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension RoutableService where Protocol == AServiceInputAdapter {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol AServiceModuleInput: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AServiceInput) -> Void)
}

protocol AServiceModuleInput2: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AServiceInput) -> Void)
}

protocol AServiceModuleInputAdapter: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AServiceInput) -> Void)
}

@objc protocol AServiceModuleInputObjcAdapter: ZIKServiceModuleRoutable {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AServiceInputObjcAdapter) -> Void)
}

extension RoutableServiceModule where Protocol == AServiceModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension RoutableServiceModule where Protocol == AServiceModuleInput2 {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension RoutableServiceModule where Protocol == AServiceModuleInputAdapter {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class AServiceModuleConfiguration: ZIKPerformRouteConfiguration, AServiceModuleInput, AServiceModuleInputAdapter, AServiceModuleInputObjcAdapter {
    var completion: ((AServiceInput) -> Void)?
    var objcCompletion: ((AServiceInputObjcAdapter) -> Void)?
    
    var title: String?
    func makeDestinationCompletion(_ block: @escaping (AServiceInput) -> Void) {
        completion = block
    }
    func makeDestinationCompletion(_ block: @escaping (AServiceInputObjcAdapter) -> Void) {
        objcCompletion = block
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! AServiceModuleConfiguration
        copy.title = self.title
        return copy
    }
}

class AServiceRouter: ZIKServiceRouter<AnyObject, AServiceModuleConfiguration> {
    
    override class func registerRoutableDestination() {
        registerService(AService.self)
        if !TEST_BLOCK_ROUTE {
            register(RoutableService<AServiceInput>())
            register(RoutableServiceModule<AServiceModuleInput>())
        }
    }
    
    override class func defaultRouteConfiguration() -> AServiceModuleConfiguration {
        return AServiceModuleConfiguration()
    }
    
    override func destination(with configuration: AServiceModuleConfiguration) -> AnyObject? {
        if TestConfig.routeShouldFail {
            return nil
        }
        return AService()
    }
    
    override func prepareDestination(_ destination: AnyObject, configuration: AServiceModuleConfiguration) {
        guard let destination = destination as? AServiceInput else {
            return
        }
        if let title = configuration.title {
            destination.title = title
        }
    }
    
    override func didFinishPrepareDestination(_ destination: AnyObject, configuration: AServiceModuleConfiguration) {
        if let completion = configuration.completion, let destination = destination as? AServiceInput {
            completion(destination)
            configuration.completion = nil
        }
    }
    
}

class AServiceAdapter: ZIKServiceRouteAdapter {
    override static func registerRoutableDestination() {
        ZIKAnyServiceRouter.register(RoutableServiceModule<AServiceModuleInput2>(), forMakingService: AService.self) { () -> AServiceModuleInput2 in
            class AServiceModuleConfiguration: ServiceMakeableConfiguration<AServiceInput, (String) -> Void>, AServiceModuleInput2 {
                var title: String? {
                    didSet {
                        makeDestination = { [unowned self] () in
                            if TestConfig.routeShouldFail {
                                return nil
                            }
                            let destination = AService()
                            destination.title = self.title
                            return destination
                        }
                    }
                }
                func makeDestinationCompletion(_ block: @escaping (AServiceInput) -> Void) {
                    self.didMakeDestination = block
                }
                
                func makeDestinationCompletion(_ block: @escaping (AServiceInputObjcAdapter) -> Void) {
                    self.didMakeDestination = { d in
                        if let d = d as? AServiceInputObjcAdapter {
                            block(d)
                        }
                    }
                }
            }
            let config = AServiceModuleConfiguration({_ in})
            config.makeDestination = {
                if TestConfig.routeShouldFail {
                    return nil
                }
                let destination = AService()
                return destination
            }
            return config
        }
        
        register(adapter: RoutableService<AServiceInputObjcAdapter>(), forAdaptee: RoutableService<AServiceInputAdapter>())
        register(adapter: RoutableService<AServiceInputAdapter>(), forAdaptee: RoutableService<AServiceInputObjcAdapter2>())
        register(adapter: RoutableService<AServiceInputObjcAdapter2>(), forAdaptee: RoutableService<AServiceInputObjcAdapter3>())
        register(adapter: RoutableService<AServiceInputObjcAdapter3>(), forAdaptee: RoutableService<AServiceInput>())
        register(adapter: RoutableServiceModule<AServiceModuleInputAdapter>(), forAdaptee: RoutableServiceModule<AServiceModuleInputObjcAdapter>())
        register(adapter: RoutableServiceModule<AServiceModuleInputObjcAdapter>(), forAdaptee: RoutableServiceModule<AServiceModuleInput>())
    }
}
