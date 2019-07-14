//
//  RouterExtension.swift
//  ZRouter
//
//  Created by zuik on 2018/1/20.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter

// MARK: Service Router Extension

/// Add Swift methods for ZIKServiceRouter. Unavailable for any other classes.
public protocol ServiceRouterExtension: class {
    static func register<Protocol>(_ routableService: RoutableService<Protocol>)
    static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>)
    static func register<Protocol>(_ routableService: RoutableService<Protocol>, forMakingService serviceClass: AnyClass)
    static func register<Protocol>(_ routableService: RoutableService<Protocol>, forMakingService serviceClass: AnyClass, making factory: @escaping (PerformRouteConfig) -> Protocol?)
    static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forMakingService serviceClass: AnyClass, making factory: @escaping () -> Protocol)
}

public extension ServiceRouterExtension {
    /// Register a service protocol that all services registered with the router conforming to.
    ///
    /// - Parameter routableService: A routabe entry carrying a protocol conformed by the destination of the router.
    static func register<Protocol>(_ routableService: RoutableService<Protocol>) {
        Registry.register(routableService, forRouter: self)
    }
    
    /// Register a module config protocol conformed by the router's default route configuration.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
    static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) {
        Registry.register(routableServiceModule, forRouter: self)
    }
    
    /// Register service class with protocol without using any router subclass. The service will be created with `[[serviceClass alloc] init]` when used. Use this if your service is very easy and don't need a router subclass.
    ///
    /// - Note:
    /// You should not use this method if the class is pure swift class, or it has designated initializer.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a protocol conformed by the destination.
    ///   - serviceClass: The service class. Should be subclass of NSObject.
    static func register<Protocol>(_ routableService: RoutableService<Protocol>, forMakingService serviceClass: AnyClass) {
        Registry.register(routableService, forMakingService: serviceClass)
    }
    
    /// Register service class with protocol without using any router subclass. The service will be created with the `making` block when used. Use this if your service is very easy and don't need a router subclass.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a protocol conformed by the destination.
    ///   - serviceClass: The service class.
    ///   - making: Block creating the service.
    static func register<Protocol>(_ routableService: RoutableService<Protocol>, forMakingService serviceClass: AnyClass, making factory: @escaping (PerformRouteConfig) -> Protocol?) {
        Registry.register(routableService, forMakingService: serviceClass, making: factory)
    }
    
    /**
     Register service class with module config protocol without using any router subclass. The service will be created with the `makeDestination` block in the configuration. Use this if your service is very easy and don't need a router subclass.
     
     If a module need a few required parameters when creating destination, you can declare makeDestinationWith in module config protocol:
     ```
     protocol LoginServiceModuleInput {
        // Pass required parameter and return destination with LoginServiceInput type.
        var makeDestinationWith: (_ account: String) -> LoginServiceInput? { get }
     }
     
     // Declare routable protocol
     extension RoutableServiceModule where Protocol == LoginServiceModuleInput {
        init() { self.init(declaredProtocol: Protocol.self) }
     }
     ```
     Then register module with module config factory block:
     ```
     // Let ServiceMakeableConfiguration conform to LoginServiceModuleInput
     extension ServiceMakeableConfiguration: LoginServiceModuleInput where Destination == LoginServiceInput, Constructor == (String) -> LoginServiceInput? {
     }
     
     // Register in some +registerRoutableDestination
     ZIKAnyServiceRouter.register(RoutableServiceModule<LoginServiceModuleInput>(), forMakingService: LoginService.self) { () -> LoginServiceModuleInput in
        let config = ServiceMakeableConfiguration<LoginServiceInput, (String) -> Void>({_,_ in })
        config.__prepareDestination = { destination in
            // Prepare the destination
        }
        // User is responsible for calling makeDestinationWith and giving parameters
        config.makeDestinationWith = { [unowned config] (account) in
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            config.makeDestination = { () -> LoginServiceInput?
            let destination = LoginService(account: account)
                return destination
            }
            if let destination = config.makeDestination?() {
                config.makedDestination = destination
                return destination
            }
            return nil
        }
        return config
     }
     ```
     You can use this module with LoginServiceModuleInput:
     ```
     Router.makeDestination(to: RoutableServiceModule<LoginServiceModuleInput>()) { (config) in
         let destination = config.makeDestinationWith("account")
     }
     ```
     
      - Parameters:
        - routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
        - serviceClass: The service class.
        - making: Block creating the configuration. The configuration must be a ZIKPerformRouteConfiguration conforming to ZIKConfigurationMakeable with makeDestination or constructDestiantion property.
     */
    static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forMakingService serviceClass: AnyClass, making factory: @escaping () -> Protocol) {
        Registry.register(routableServiceModule, forMakingService: serviceClass, making: factory)
    }
}

extension ZIKServiceRouter: ServiceRouterExtension {
    
}

// MARK: Adapter Extension

public extension ZIKServiceRouteAdapter {
    
    /// Register adapter and adaptee protocols conformed by the destination. Then if you try to find router with the adapter, there will return the adaptee's router.
    ///
    /// - Parameter adapter: The required protocol used in the user. The protocol should not be directly registered with any router yet.
    /// - Parameter adaptee: The provided protocol.
    static func register<Adapter, Adaptee>(adapter: RoutableService<Adapter>, forAdaptee adaptee: RoutableService<Adaptee>) {
        Registry.register(adapter: adapter, forAdaptee: adaptee)
    }
    
    /// Register adapter and adaptee protocols conformed by the default configuration of the adaptee's router. Then if you try to find router with the adapter, there will return the adaptee's router.
    ///
    /// - Parameter adapter: The required protocol used in the user. The protocol should not be directly registered with any router yet.
    /// - Parameter adaptee: The provided protocol.
    static func register<Adapter, Adaptee>(adapter: RoutableServiceModule<Adapter>, forAdaptee adaptee: RoutableServiceModule<Adaptee>) {
        Registry.register(adapter: adapter, forAdaptee: adaptee)
    }
}

// MARK: Service Route Extension

/// Add Swift methods for ZIKServiceRoute. Unavailable for any other classes.
public protocol ServiceRouteExtension: class {
    #if swift(>=4.1)
    @discardableResult func register<Protocol>(_ routableService: RoutableService<Protocol>) -> Self
    @discardableResult func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) -> Self
    #else
    func register<Protocol>(_ routableService: RoutableService<Protocol>)
    func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>)
    #endif
}

public extension ServiceRouteExtension {
    
    #if swift(>=4.1)
    
    /// Register pure Swift protocol or objc protocol for your service with this ZIKServiceRoute.
    ///
    /// - Parameter routableService: A routabe entry carrying a protocol conformed by the destination of the router. Can be pure Swift protocol or objc protocol.
    /// - Returns: Self
    @discardableResult func register<Protocol>(_ routableService: RoutableService<Protocol>) -> Self {
        Registry.register(routableService, forRoute: self)
        return self
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRoute. You must add `makeDefaultConfiguration` for this route, and router will check whether the registered config protocol is conformed by the defaultRouteConfiguration.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
    /// - Returns: Self
    @discardableResult func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) -> Self {
        Registry.register(routableServiceModule, forRoute: self)
        return self
    }
    
    #else
    
    /// Register pure Swift protocol or objc protocol for your service with this ZIKServiceRoute.
    ///
    /// - Parameter routableService: A routabe entry carrying a protocol conformed by the destination of the router. Can be pure Swift protocol or objc protocol.
    func register<Protocol>(_ routableService: RoutableService<Protocol>) {
        Registry.register(routableService, forRoute: self)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRoute. You must add `makeDefaultConfiguration` for this route, and router will check whether the registered config protocol is conformed by the defaultRouteConfiguration.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
    func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) {
        Registry.register(routableServiceModule, forRoute: self)
    }
    
    #endif
}

extension ZIKServiceRoute: ServiceRouteExtension {
    
}
