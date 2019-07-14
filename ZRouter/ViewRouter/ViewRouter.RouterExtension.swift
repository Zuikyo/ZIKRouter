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

public extension ViewRouteConfig {
    func configurePath(_ path: ViewRoutePath) {
        if let source = path.source {
            self.source = source
        }
        self.routeType = path.routeType
    }
}

// MARK: View Router Extension

/// Add Swift methods for ZIKViewRouter. Unavailable for any other classes.
public protocol ViewRouterExtension: class {
    static func register<Protocol>(_ routableView: RoutableView<Protocol>)
    static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>)
    static func register<Protocol>(_ routableView: RoutableView<Protocol>, forMakingView viewClass: AnyClass)
    static func register<Protocol>(_ routableView: RoutableView<Protocol>, forMakingView viewClass: AnyClass, making factory: @escaping (ViewRouteConfig) -> Protocol?)
    static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forMakingView viewClass: AnyClass, making factory: @escaping () -> Protocol)
}

public extension ViewRouterExtension {
    /// Register a view protocol that all views registered with the router conforming to.
    ///
    /// - Parameter routableView: A routabe entry carrying a protocol conformed by the destination of the router.
    static func register<Protocol>(_ routableView: RoutableView<Protocol>) {
        Registry.register(routableView, forRouter: self)
    }
    
    /// Register a module config protocol conformed by the router's default route configuration.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
    static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) {
        Registry.register(routableViewModule, forRouter: self)
    }
    
    /// Register view class with protocol without using any router subclass. The view will be created with `[[viewClass alloc] init]` when used. Use this if your view is very easy and don't need a router subclass.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a protocol conformed by the destination.
    ///   - viewClass: The view class.
    static func register<Protocol>(_ routableView: RoutableView<Protocol>, forMakingView viewClass: AnyClass) {
        Registry.register(routableView, forMakingView: viewClass)
    }
    
    /// Register view class with protocol without using any router subclass. The view will be created with the `making` block when used. Use this if your view is very easy and don't need a router subclass.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a protocol conformed by the destination.
    ///   - viewClass: The view class.
    ///   - making: Block creating the view.
    static func register<Protocol>(_ routableView: RoutableView<Protocol>, forMakingView viewClass: AnyClass, making factory: @escaping (ViewRouteConfig) -> Protocol?) {
        Registry.register(routableView, forMakingView: viewClass, making: factory)
    }
    
    /**
     Register view class with module config protocol without using any router subclass. The view will be created with the `makeDestination` block in the configuration. Use this if your view is very easy and don't need a router subclass.
     
     If a module need a few required parameters when creating destination, you can declare makeDestiantionWith in module config protocol:
     ```
     protocol LoginViewModuleInput {
        // Pass required parameter and return destination with LoginViewInput type.
        var makeDestinationWith: (_ account: String) -> LoginViewInput? { get }
     }
     
     // Declare routable protocol
     extension RoutableViewModule where Protocol == LoginViewModuleInput {
        init() { self.init(declaredProtocol: Protocol.self) }
     }
     ```
     Then register module with module config factory block:
     ```
     // Let ViewMakeableConfiguration conform to LoginViewModuleInput
     extension ViewMakeableConfiguration: LoginViewModuleInput where Destination == LoginViewInput, Constructor == (String) -> LoginViewInput? {
     }
     
     // Register in some +registerRoutableDestination
     ZIKAnyViewRouter.register(RoutableViewModule<LoginViewModuleInput>(), forMakingView: LoginViewController.self) { () -> LoginViewModuleInput in
        let config = ViewMakeableConfiguration<LoginViewInput, (String) -> Void>({_,_ in })
        config.__prepareDestination = { destination in
            // Prepare the destination
        }
        // User is responsible for calling makeDestinationWith and giving parameters
        config.makeDestinationWith = { [unowned config] (account) in
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            config.makeDestination = { () -> LoginViewInput?
                let destination = LoginViewController(account: account)
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
     You can use this module with LoginViewModuleInput:
     ```
     Router.makeDestination(to: RoutableViewModule<LoginViewModuleInput>()) { (config) in
         let destination: LoginViewInput = config.makeDestinationWith("account")
     }
     ```
     
     - Parameters:
     - routableViewModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
     - viewClass: The view class.
     - making: Block creating the configuration. The configuration  must be a ZIKViewRouteConfiguration conforming to ZIKConfigurationMakeable with makeDestination or constructDestiantion property.
     */
    static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forMakingView viewClass: AnyClass, making factory: @escaping () -> Protocol) {
        Registry.register(routableViewModule, forMakingView: viewClass, making: factory)
    }
}

extension ZIKViewRouter: ViewRouterExtension {
    
}

// MARK: Adapter Extension

public extension ZIKViewRouteAdapter {
    
    /// Register adapter and adaptee protocols conformed by the destination. Then if you try to find router with the adapter, there will return the adaptee's router.
    ///
    /// - Parameter adapter: The required protocol used in the user. The protocol should not be directly registered with any router yet.
    /// - Parameter adaptee: The provided protocol.
    static func register<Adapter, Adaptee>(adapter: RoutableView<Adapter>, forAdaptee adaptee: RoutableView<Adaptee>) {
        Registry.register(adapter: adapter, forAdaptee: adaptee)
    }
    
    /// Register adapter and adaptee protocols conformed by the default configuration of the adaptee's router. Then if you try to find router with the adapter, there will return the adaptee's router.
    ///
    /// - Parameter adapter: The required protocol used in the user. The protocol should not be directly registered with any router yet.
    /// - Parameter adaptee: The provided protocol.
    static func register<Adapter, Adaptee>(adapter: RoutableViewModule<Adapter>, forAdaptee adaptee: RoutableViewModule<Adaptee>) {
        Registry.register(adapter: adapter, forAdaptee: adaptee)
    }
}

// MARK: View Route Extension

/// Add Swift methods for ZIKViewRoute. Unavailable for any other classes.
public protocol ViewRouteExtension: class {
    #if swift(>=4.1)
    @discardableResult func register<Protocol>(_ routableView: RoutableView<Protocol>) -> Self
    @discardableResult func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) -> Self
    #else
    func register<Protocol>(_ routableView: RoutableView<Protocol>)
    func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>)
    #endif
}

public extension ViewRouteExtension {
    
    #if swift(>=4.1)
    
    /// Register pure Swift protocol or objc protocol for your view with this ZIKViewRoute.
    ///
    /// - Parameter routableView: A routabe entry carrying a protocol conformed by the destination of the router.
    /// - Returns: Self
    @discardableResult func register<Protocol>(_ routableView: RoutableView<Protocol>) -> Self {
        Registry.register(routableView, forRoute: self)
        return self
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKViewRoute. You must add `makeDefaultConfiguration` for this route, and router will check whether the registered config protocol is conformed by the defaultRouteConfiguration.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
    /// - Returns: Self
    @discardableResult func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) -> Self {
        Registry.register(routableViewModule, forRoute: self)
        return self
    }
    
    #else
    
    func register<Protocol>(_ routableView: RoutableView<Protocol>) {
        Registry.register(routableView, forRoute: self)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKViewRoute. You must add `makeDefaultConfiguration` for this route, and router will check whether the registered config protocol is conformed by the defaultRouteConfiguration.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router.
    /// - Returns: Self
    func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) {
        Registry.register(routableViewModule, forRoute: self)
    }
    
    #endif
}

extension ZIKViewRoute: ViewRouteExtension {
    
}
