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

extension AService: ZIKRoutableService, AServiceInput {
    
}

extension RoutableService where Protocol == AServiceInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

protocol AServiceModuleInput: class {
    var title: String? { get set }
    func makeDestinationCompletion(_ block: @escaping (AServiceInput) -> Void)
}

extension RoutableServiceModule where Protocol == AServiceModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class AServiceModuleConfiguration: ZIKPerformRouteConfiguration, AServiceModuleInput {
    var completion: ((AServiceInput) -> Void)?
    
    var title: String?
    func makeDestinationCompletion(_ block: @escaping (AServiceInput) -> Void) {
        completion = block
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
        register(RoutableService<AServiceInput>())
        register(RoutableServiceModule<AServiceModuleInput>())
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

