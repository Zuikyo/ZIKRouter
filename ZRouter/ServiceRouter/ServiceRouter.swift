//
//  ServiceRouter.swift
//  ZRouter
//
//  Created by zuik on 2017/11/23.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter.Internal

/// Swift Wrapper of ZIKServiceRouter class for supporting pure Swift generic type.
public class ServiceRouterType<Destination, ModuleConfig> {
    
    /// The router type to wrap.
    public let routerType: ZIKAnyServiceRouterType
    
    internal init(routerType: ZIKAnyServiceRouterType) {
        self.routerType = routerType
    }
    
    /// Default configuration to perform route.
    public var defaultRouteConfiguration: ModuleConfig {
        return routerType.defaultRouteConfiguration() as! ModuleConfig
    }
    
    /// Default configuration to remove route.
    public var defaultRemoveConfiguration: RemoveRouteConfig {
        return routerType.defaultRemoveConfiguration()
    }
    
    // MARK: Perform
    
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    
    /// Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
    ///
    /// - Parameters:
    ///   - configBuilder: Build the configuration for performing route.
    ///     - config: Config for performing route.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigBuilder: Configure the configuration for removing route.
    ///     - config: Config for removing route.
    /// - Returns: The service router for this route.
    public func perform(
        configuring configBuilder: (PerformRouteStrictConfig<Destination>, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((RemoveRouteStrictConfig<Destination>) -> Void)? = nil
        ) -> ServiceRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ZIKRemoveRouteStrictConfiguration<AnyObject>) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
                removeConfigBuilder(RemoveRouteStrictConfig(configuration: config))
            }
        }
        let routerType = self.routerType
        let router = routerType.perform(strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(PerformRouteStrictConfig(configuration: strictConfig), prepareModule)
            #if DEBUG
            let successHandler = config.successHandler
            config.successHandler = { d in
                successHandler?(d)
                assert(ServiceRouterType._castedDestination(d, routerType: routerType) != nil, "Router (\(String(describing: routerType))) returns wrong destination type (\(d)), destination should be \(Destination.self)")
            }
            #endif
        }, strictRemoving: removeBuilder)
        if let router = router {
            return ServiceRouter<Destination, ModuleConfig>(router: router)
        } else {
            return nil
        }
    }
    
    /// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
    @discardableResult public func perform(successHandler performerSuccessHandler: ((Destination) -> Void)? = nil, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) -> ServiceRouter<Destination, ModuleConfig>? {
        return perform(configuring: { (config, _) in
            if let performerSuccessHandler = performerSuccessHandler {
                let successHandler = config.performerSuccessHandler
                config.performerSuccessHandler = { destination in
                    successHandler?(destination)
                    performerSuccessHandler(destination)
                }
            }
            if let performerErrorHandler = performerErrorHandler {
                let errorHandler = config.performerErrorHandler
                config.performerErrorHandler = { (action, error) in
                    errorHandler?(action, error)
                    performerErrorHandler(action, error)
                }
            }
        })
    }
    
    /// If this destination doesn't need any variable to initialize, just pass source and perform route with completion for current performing.
    @discardableResult public func perform(completion performerCompletion: @escaping (Bool, Destination?, ZIKRouteAction, Error?) -> Void) -> ServiceRouter<Destination, ModuleConfig>? {
        return perform(successHandler: { (destination) in
            performerCompletion(true, destination, .performRoute, nil);
        }, errorHandler: { (action, error) in
            performerCompletion(false, nil, action, error);
        })
    }
    
    /// Prepare the destination with destination protocol and perform route.
    ///
    /// - Parameters:
    ///   - preparation: Prepare the destination with destination protocol. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service router for this route.
    @discardableResult public func perform(preparation prepare: @escaping ((Destination) -> Void)) -> ServiceRouter<Destination, ModuleConfig>? {
        return perform(configuring: { (config, _) in
            config.prepareDestination = prepare
        })
    }
    
    // MARK: Make Destination
    
    /// Whether the destination is instantiated synchronously.
    public var canMakeDestinationSynchronously: Bool {
        return routerType.canMakeDestinationSynchronously()
    }
    
    /// The router may can't make destination synchronously, or it's not for providing a destination but only for performing some actions.
    public var canMakeDestination: Bool {
        return routerType.canMakeDestination()
    }
    
    /// Synchronously get destination.
    public func makeDestination() -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination()
        assert(destination == nil || ServiceRouterType._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        if let destination = destination {
            return destination as? Destination
        }
        return nil
    }
    
    /// Synchronously get destination, and prepare the destination with destination protocol. Preparation is an escaping block, use weakSelf to avoid retain cycle.
    public func makeDestination(preparation prepare: ((Destination) -> Void)? = nil) -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination(preparation: { d in
            if let destination = ServiceRouterType._castedDestination(d, routerType: routerType) {
                prepare?(destination)
            }
        })
        assert(destination == nil || ServiceRouterType._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        if let destination = destination {
            return destination as? Destination
        }
        return nil
    }
    
    /// Synchronously get destination, and prepare the destination.
    ///
    /// - Parameter configBuilder: Build the configuration for performing route.
    ///     - config: Config for performing route.
    ///     - prepareModule: Prepare custom module config.
    /// - Returns: Destination
    public func makeDestination(configuring configBuilder: (PerformRouteStrictConfig<Destination>, ModulePreparation) -> Void) -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination(strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(PerformRouteStrictConfig(configuration: strictConfig), prepareModule)
        })
        assert(destination == nil || ServiceRouterType._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        if let destination = destination {
            return destination as? Destination
        }
        return nil
    }
    
    private static func _castedDestination(_ destination: Any, routerType: ZIKAnyServiceRouterType) -> Destination? {
        if let d = destination as? Destination {
            #if DEBUG
            assert(Registry.validateConformance(destination: d, inServiceRouterType: routerType))
            #endif
            return d
        } else if let d = (destination as AnyObject) as? Destination {
            #if DEBUG
            assert(Registry.validateConformance(destination: d, inServiceRouterType: routerType))
            #endif
            return d
        } else {
            assertionFailure("Router (\(routerType)) returns wrong destination type (\(destination)), destination should be \(Destination.self)")
        }
        return nil
    }
}

/// Swift Wrapper of ZIKServiceRouter for supporting pure Swift generic type.
public class ServiceRouter<Destination, ModuleConfig> {
    /// The routed ZIKServiceRouter.
    public let router: ZIKAnyServiceRouter
    
    internal init(router: ZIKAnyServiceRouter) {
        self.router = router
    }
    
    /// State of route.
    public var state: ZIKRouterState {
        return router.state
    }
    
    /// Configuration for performRoute.
    public var configuration: PerformRouteConfig {
        return router.configuration
    }
    
    /// Configuration for module protocol.
    public var config: ModuleConfig {
        return router.configuration as! ModuleConfig
    }
    
    /// Configuration for removeRoute.
    public var removeConfiguration: RouteConfig? {
        return router.removeConfiguration
    }
    
    /// Latest error when route action failed.
    public var error: Error? {
        return router.error
    }
    
    // MARK: Perform
    
    /// Whether the router can perform route now.
    public var canPerform: Bool {
        return router.canPerform()
    }
    
    /// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
    public func performRoute(successHandler: ((Destination) -> Void)? = nil, errorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        router.performRoute(successHandler: { (d) in
            if let destination = d as? Destination {
                successHandler?(destination)
            }
        }, errorHandler: errorHandler)
    }
    
    /// If this route action doesn't need any arguments, perform directly with completion for current performing.
    public func performRoute(completion performerCompletion: @escaping (Bool, Destination?, ZIKRouteAction, Error?) -> Void) {
        performRoute(successHandler: { (destination) in
            performerCompletion(true, destination, .performRoute, nil)
        }, errorHandler: { (action, error) in
            performerCompletion(false, nil, action, error)
        })
    }
    
    // MARK: Remove
    
    /// Whether the router should be removed before another performing, when the router is performed already and the destination still exists.
    public var shouldRemoveBeforePerform: Bool {
        return router.shouldRemoveBeforePerform()
    }
    
    /// Whether the router can remove route now. Default is false.
    public var canRemove: Bool {
        return router.canRemove()
    }
    
    /// Remove with success handler and error handler. If canRemove return false, this will fail.
    public func removeRoute(successHandler performerSuccessHandler: (() -> Void)? = nil, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        router.removeRoute(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    /// Remove route with completion for current removing.
    public func removeRoute(completion performerCompletion: @escaping (Bool, ZIKRouteAction, Error?) -> Void) {
        removeRoute(successHandler: {
            performerCompletion(true, .removeRoute, nil)
        }, errorHandler: { (action, error) in
            performerCompletion(false, action, error)
        })
    }
    
    /// Remove route and prepare before removing.
    ///
    /// - Parameter configBuilder: Configure the configuration for removing route.
    ///     - config: Config for removing route.
    public func removeRoute(configuring configBuilder: @escaping (RemoveRouteStrictConfig<Destination>) -> Void) {
        let removeBuilder = { (config: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
            configBuilder(RemoveRouteStrictConfig(configuration: config))
        }
        router.removeRoute(strictConfiguring: removeBuilder)
    }
}

// MARK: Makeable Config

/// Convenient configuration as factory for destination for using custom configuration without configuration subclass.
open class ServiceMakeableConfiguration<Destination, Constructor>: ZIKSwiftServiceMakeableConfiguration {
    
    /// Make destination with block.
    ///
    /// Set this in makeDestinationWith or constructDestination block. It's for passing parameters easily, so we don't need configuration subclass to hold parameters.
    ///
    /// When using configuration with `register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forMakingService serviceClass: AnyClass, making factory: @escaping () -> Protocol)`, makeDestination is auto used for making destination.
    ///
    /// When using a router subclass with makeable configuration, the router subclass is responsible for check and use makeDestination in `-destinationWithConfiguration:`.
    public var makeDestination: (() -> Destination?)? {
        didSet {
            if self.makeDestination == nil {
                self.__makeDestination = nil
                return
            }
            self.__makeDestination = { [unowned self] () -> Any? in
                if let destination = self.makeDestination?() {
                    return destination
                }
                return nil
            }
        }
    }
    
    /**
     Factory method passing required parameters and make destination. You should set makedDestination in makeDestinationWith.
     Genetic Constructor is a factory type like: ServiceMakeableConfiguration<LoginServiceInput, (String) -> LoginServiceInput?>
     
     If a module need a few required parameters when creating destination, you can declare makeDestinationWith in module config protocol:
     
     ```
     protocol LoginServiceModuleInput {
        // Pass required parameter and return destination with LoginServiceInput type.
        var makeDestinationWith: (_ account: String) -> LoginServiceInput? { get }
     }
     extension RoutableServiceModule where Protocol == LoginServiceModuleInput {
        init() { self.init(declaredProtocol: Protocol.self) }
     }
     
     // Let ServiceMakeableConfiguration conform to LoginServiceModuleInput
     extension ServiceMakeableConfiguration: LoginServiceModuleInput where Destination == LoginServiceInput, Constructor == (String) -> LoginServiceInput? {
     }
     ```
     Register in some registerRoutableDestination:
     ```
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
     Or just:
     ```
     let destination: LoginServiceInput = Router.to(RoutableServiceModule<LoginServiceModuleInput>())?.defaultRouteConfiguration.makeDestinationWith("account")
     ```
     */
    public var makeDestinationWith: Constructor
    
    /**
     Asynchronous factory method passing required parameters for initializing destination module, and get destination in `didMakeDestination`. You should set makeDestination to capture parameters directly, so you don't need configuration subclass to hold parameters.
     Genetic Constructor is a function type like: ServiceMakeableConfiguration<LoginServiceInput, (String) -> Void>
     
     If a module need a few required parameters when creating destination, you can declare constructDestination in module config protocol:
     
     ```
     protocol LoginServiceModuleInput {
        // Pass required parameter for initializing destination.
        var constructDestination: (_ account: String) -> Void { get }
        // Designate destination is LoginServiceInput.
        var didMakeDestination:((LoginServiceInput) -> Void)? { get set }
     }
     extension RoutableServiceModule where Protocol == LoginServiceModuleInput {
        init() { self.init(declaredProtocol: Protocol.self) }
     }
     
     // Let ServiceMakeableConfiguration conform to LoginServiceModuleInput
     extension ServiceMakeableConfiguration: LoginServiceModuleInput where Destination == LoginServiceInput, Constructor == (String) -> Void {
     }
     ```
     Register in some registerRoutableDestination:
     ```
     ZIKAnyServiceRouter.register(RoutableServiceModule<LoginServiceModuleInput>(), forMakingService: LoginService.self) { () -> LoginServiceModuleInput in
        let config = ServiceMakeableConfiguration<LoginServiceInput, (String) -> Void>({_,_ in })
        config.__prepareDestination = { destination in
            // Prepare the destination
        }
        // User is responsible for calling constructDestination and giving parameters
        config.constructDestination = { [unowned config] (account) in
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            config.makeDestination = {
                let destination = LoginService(account: account)
                return destination
            }
        }
        return config
     }
     ```
     You can use this module with LoginServiceModuleInput:
     ```
     Router.makeDestination(to: RoutableServiceModule<LoginServiceModuleInput>()) { (config) in
        config.constructDestination("account")
        config.didMakeDestination = { destination in
            // Did get LoginServiceInput
        }
     }
     ```
     */
    public var constructDestination: Constructor
    
    /// Give the destination with specfic type to the caller. This is auto called and reset to nil after `didFinishPrepareDestination:configuration:`.
    public var didMakeDestination: ((Destination) -> Void)? {
        didSet {
            if self.didMakeDestination == nil {
                self.__didMakeDestination = nil
                return
            }
            self.__didMakeDestination = { [unowned self] (d: Any) -> Void in
                if let destination = d as? Destination {
                    if let didMakeDestination = self.didMakeDestination {
                        self.didMakeDestination = nil
                        didMakeDestination(destination)
                    }
                } else {
                    assertionFailure("Invalid destination. Destination is not type of (\(Destination.self)): \(d)")
                }
            }
        }
    }
    
    /// Prepare the destination from the router internal before `prepareDestination(_:configuration:)`.
    ///
    /// When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
    public var __prepareDestination: ((Destination) -> Void)? {
        didSet {
            if self.__prepareDestination == nil {
                self._prepareDestination = nil
                return
            }
            self._prepareDestination = { [unowned self] destination in
                if let destination = destination as? Destination {
                    self.__prepareDestination?(destination)
                }
            }
        }
    }
    
    /**
     Container to hold custom `makeDestinationWith` and `constructDestination` block. If the destination has multi custom initializers, you can add new constructor and store them in the container.
     
     ```
     protocol LoginServiceModuleInput {
        var makeDestinationWith: (_ account: String) -> LoginServiceInput? { get }
        var makeDestinationForNewUserWith: (_ account: String) -> LoginServiceInput? { get }
     }
     
     // Let ServiceMakeableConfiguration conform to LoginServiceModuleInput
     extension ServiceMakeableConfiguration: LoginServiceModuleInput where Destination == LoginServiceInput, Constructor == (String) -> LoginServiceInput? {
        var makeDestinationForNewUserWith: (String) -> LoginServiceInput? {
            get {
                if let block = self.constructorContainer["makeDestinationForNewUserWith"] as? (String) -> LoginServiceInput? {
                    return block
                }
                return { _ in return nil }
            }
            set {
                self.constructorContainer["makeDestinationForNewUserWith"] = newValue
            }
        }
     }
     ```
     */
    public lazy var constructorContainer: [String : Any] = [:]
    
    public init(_ constructor: Constructor) {
        makeDestinationWith = constructor
        constructDestination = constructor
        super.init()
    }
}

/**
 Convenient configuration as factory for destination for using custom configuration without configuration subclass. Support makeDestinationWith and constructDestination at the same configuration.
 
 If a module need a few required parameters when creating destination, you can declare in module config protocol:
 
 ```
 protocol LoginServiceModuleInput {
    // Pass required parameter and return destination with LoginServiceInput type.
    var makeDestinationWith: (_ account: String) -> LoginServiceInput? { get }
    // Pass required parameter for initializing destination.
    var constructDestination: (_ account: String) -> Void { get }
    // Designate destination is LoginServiceInput.
    var didMakeDestination:((LoginServiceInput) -> Void)? { get set }
 }
 extension RoutableServiceModule where Protocol == LoginServiceModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
 }
 
 // Let AnyServiceMakeableConfiguration conform to LoginServiceModuleInput
 extension AnyServiceMakeableConfiguration: LoginServiceModuleInput where Destination == LoginServiceInput, Maker == (String) -> LoginServiceInput?, Constructor == (String) -> Void {
 }
 ```
 Register in some registerRoutableDestination:
 ```
 ZIKAnyServiceRouter.register(RoutableServiceModule<LoginServiceModuleInput>(), forMakingService: LoginServiceController.self) { () -> LoginServiceModuleInput in
    let config = AnyServiceMakeableConfiguration<LoginServiceInput, (String) -> LoginServiceInput?, (String) -> Void>({_,_ in })
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
 
    // User is responsible for calling constructDestination and giving parameters
    config.constructDestination = { [unowned config] (account) in
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        config.makeDestination = {
            let destination = LoginService(account: account)
            return destination
        }
    }
    return config
 }
 ```
 You can use this module with LoginServiceModuleInput:
 ```
 Router.makeDestination(to: RoutableServiceModule<LoginServiceModuleInput>()) { (config) in
    config.constructDestination("account")
    config.didMakeDestination = { destination in
        // Did get LoginServiceInput
    }
 }
 ```
 Or:
 ```
 let destination: LoginServiceInput = Router.to(RoutableServiceModule<LoginServiceModuleInput>()).defaultRouteConfiguration.makeDestinationWith("account")
 ```
 */
open class AnyServiceMakeableConfiguration<Destination, Maker, Constructor>: ZIKSwiftServiceMakeableConfiguration {
    
    /// Make destination with block.
    ///
    /// Set this in makeDestinationWith or constructDestination block. It's for passing parameters easily, so we don't need configuration subclass to hold parameters.
    ///
    /// When using configuration with `register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forMakingService serviceClass: AnyClass, making factory: @escaping () -> Protocol)`, makeDestination is auto used for making destination.
    ///
    /// When using a router subclass with makeable configuration, the router subclass is responsible for check and use makeDestination in `-destinationWithConfiguration:`.
    public var makeDestination: (() -> Destination?)? {
        didSet {
            if self.makeDestination == nil {
                self.__makeDestination = nil
                return
            }
            self.__makeDestination = { [unowned self] () -> Any? in
                if let destination = self.makeDestination?() {
                    return destination
                }
                return nil
            }
        }
    }
    
    /// Factory method passing required parameters and make destination. You should set makedDestination in makeDestinationWith.
    public var makeDestinationWith: Maker
    
    /// Asynchronous factory method passing required parameters for initializing destination module, and get destination in `didMakeDestination`. You should set makeDestination to capture parameters directly, so you don't need configuration subclass to hold parameters.
    public var constructDestination: Constructor
    
    /// Give the destination with specfic type to the caller. This is auto called and reset to nil after `didFinishPrepareDestination:configuration:`.
    public var didMakeDestination: ((Destination) -> Void)? {
        didSet {
            if self.didMakeDestination == nil {
                self.__didMakeDestination = nil
                return
            }
            self.__didMakeDestination = { [unowned self] (d: Any) -> Void in
                if let destination = d as? Destination {
                    if let didMakeDestination = self.didMakeDestination {
                        self.didMakeDestination = nil
                        didMakeDestination(destination)
                    }
                } else {
                    assertionFailure("Invalid destination. Destination is not type of (\(Destination.self)): \(d)")
                }
            }
        }
    }
    
    /// Prepare the destination from the router internal before `prepareDestination(_:configuration:)`.
    ///
    /// When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
    public var __prepareDestination: ((Destination) -> Void)? {
        didSet {
            if self.__prepareDestination == nil {
                self._prepareDestination = nil
                return
            }
            self._prepareDestination = { [unowned self] destination in
                if let destination = destination as? Destination {
                    self.__prepareDestination?(destination)
                }
            }
        }
    }
    
    /**
     Container to hold custom `makeDestinationWith` and `constructDestination` block. If the destination has multi custom initializers, you can add new constructor and store them in the container.
     
     ```
     protocol LoginServiceModuleInput {
        var makeDestinationWith: (_ account: String) -> LoginServiceInput? { get }
        var makeDestinationForNewUserWith: (_ account: String) -> LoginServiceInput? { get }
     }
     
     // Let ServiceMakeableConfiguration conform to LoginServiceModuleInput
     extension ServiceMakeableConfiguration: LoginServiceModuleInput where Destination == LoginServiceInput, Constructor == (String) -> LoginServiceInput? {
        var makeDestinationForNewUserWith: (String) -> LoginServiceInput? {
            get {
                if let block = self.constructorContainer["makeDestinationForNewUserWith"] as? (String) -> LoginServiceInput? {
                    return block
                }
                return { _ in return nil }
            }
            set {
                self.constructorContainer["makeDestinationForNewUserWith"] = newValue
            }
        }
     }
     ```
     */
    public lazy var constructorContainer: [String : Any] = [:]
    
    public init(maker: Maker, constructor: Constructor) {
        makeDestinationWith = maker
        constructDestination = constructor
        super.init()
    }
}

// MARK: Strict Config

/// Proxy of ZIKRouteConfiguration to handle configuration in a type safe way.
public class RouteStrictConfig<Config: ZIKRouteStrictConfiguration<AnyObject>> {
    public fileprivate(set) var configuration: Config
    internal init(configuration: Config) {
        self.configuration = configuration
    }
    /// Error handler for router's provider. Each time the router was performed or removed, error handler will be called when the operation fails. It's an escaping block.
    ///
    /// - Note: Use weak self in errorHandler to avoid retain cycle.
    public var errorHandler: ((ZIKRouteAction, Error) -> Void)? {
        get { return configuration.errorHandler }
        set { configuration.errorHandler = newValue }
    }
    /// Error handler for current performing, will reset to nil after performed.
    public var performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? {
        get { return configuration.performerErrorHandler }
        set { configuration.performerErrorHandler = newValue }
    }
    /// Monitor state. It's an escaping block.
    ///
    /// - Note: Use weak self in stateNotifier to avoid retain cycle.
    public var stateNotifier: ((ZIKRouterState, ZIKRouterState) -> Void)? {
        get { return configuration.stateNotifier }
        set { configuration.stateNotifier = newValue }
    }
}

/// Proxy of ZIKPerformRouteConfiguration to handle configuration in a type safe way.
public class PerformRouteStrictConfig<Destination>: RouteStrictConfig<ZIKPerformRouteStrictConfiguration<AnyObject>> {
    internal override init(configuration: ZIKPerformRouteStrictConfiguration<AnyObject>) {
        super.init(configuration: configuration)
    }
    /// Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info. It's an escaping block.
    ///
    /// - Note: Use weak self in prepareDestination to avoid retain cycle.
    public var prepareDestination: ((Destination) -> Void)? {
        get {
            if let prepare = configuration.prepareDestination {
                return { destiantion in
                    prepare(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let prepare = newValue {
                configuration.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            } else {
                configuration.prepareDestination = nil
            }
        }
    }
    
    /// Success handler for router's provider. Each time the router was performed, success handler will be called when the operation succeed. It's an escaping block.
    ///
    /// - Note: Use weak self in successHandler to avoid retain cycle.
    public var successHandler: ((Destination) -> Void)? {
        get {
            if let handler = configuration.successHandler {
                return { destiantion in
                    handler(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let handler = newValue {
                configuration.successHandler = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    handler(destination)
                }
            } else {
                configuration.successHandler = nil
            }
        }
    }
    
    /// Success handler for current performing, will reset to nil after performed.
    public var performerSuccessHandler: ((Destination) -> Void)? {
        get {
            if let handler = configuration.performerSuccessHandler {
                return { destiantion in
                    handler(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let handler = newValue {
                configuration.performerSuccessHandler = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    handler(destination)
                }
            } else {
                configuration.performerSuccessHandler = nil
            }
        }
    }
    
    /// Completion handler for performRoute. It's an escaping block.
    ///
    /// - Note: Use weak self in completionHandler to avoid retain cycle.
    public var completionHandler: ((Bool, Destination?, ZIKRouteAction, Error?) -> Void)? {
        get {
            if let handler = configuration.completionHandler {
                return { (success, destiantion: Destination?, action, error) in
                    handler(success, destiantion as AnyObject, action, error)
                }
            }
            return nil
        }
        set {
            if let handler = newValue {
                configuration.completionHandler = { (success, d, action, error) in
                    if d == nil {
                        handler(success, nil, action, error)
                    } else if let destination = d as? Destination {
                        handler(success, destination, action, error)
                    } else {
                        assertionFailure("Bad implementation in router, destination (\(d!)) should be type (\(Destination.self))")
                    }
                }
            } else {
                configuration.completionHandler = nil
            }
        }
    }
    
    /// User info when handle route action from URL Scheme.
    public var userInfo: [String : Any] {
        get { return configuration.userInfo }
    }
    
    /// Add user info.
    ///
    /// - Note: You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
    public func addUserInfo(forKey key: String, object: Any) {
        configuration.addUserInfo(forKey: key, object: object)
    }
    
    /// Add user info.
    ///
    /// - Note: You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
    public func addUserInfo(_ userInfo: [String : Any]) {
        configuration.addUserInfo(userInfo)
    }
}

/// Proxy of ZIKRemoveRouteConfiguration to handle configuration in a type safe way.
public class RemoveRouteStrictConfig<Destination>: RouteStrictConfig<ZIKRemoveRouteStrictConfiguration<AnyObject>> {
    internal override init(configuration: ZIKRemoveRouteStrictConfiguration<AnyObject>) {
        super.init(configuration: configuration)
    }
    
    /// Prepare for removeRoute. Subclass can offer more specific info. It's an escaping block.
    ///
    /// - Note: Use weak self in prepareDestination to avoid retain cycle.
    public var prepareDestination: ((Destination) -> Void)? {
        get {
            if let prepare = configuration.prepareDestination {
                return { destiantion in
                    prepare(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let prepare = newValue {
                configuration.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            } else {
                configuration.prepareDestination = nil
            }
        }
    }
    
    /// Success handler for router's provider. Each time the router was removed, success handler will be called when the operation succeed. It's an escaping block.
    ///
    /// - Note: Use weak self in successHandler to avoid retain cycle.
    public var successHandler: (() -> Void)? {
        get { return configuration.successHandler }
        set { configuration.successHandler = newValue }
    }
    
    /// Success handler for current removing, will reset to nil after removed.
    public var performerSuccessHandler: (() -> Void)? {
        get { return configuration.performerSuccessHandler }
        set { configuration.performerSuccessHandler = newValue }
    }
    
    /// Completion handler for removeRoute. It's an escaping block.
    ///
    /// - Note: Use weak self in completionHandler to avoid retain cycle.
    public var completionHandler: ZIKRemoveRouteCompletion? {
        get { return configuration.completionHandler }
        set { configuration.completionHandler = newValue }
    }
}
