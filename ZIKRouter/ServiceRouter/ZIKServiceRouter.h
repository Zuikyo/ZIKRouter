//
//  ZIKServiceRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"
#import "ZIKServiceRoutable.h"
#import "ZIKServiceModuleRoutable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Abstract superclass of service router for discovering service and injecting dependencies with registered protocol. Subclass it and override those methods in `ZIKRouterInternal` and `ZIKServiceRouterInternal` to make router of your service.
 
 How to create router for LoginService:
 
 1. Declare a routable protocol for LoginService:
 @code
 // LoginServiceInput inherits from ZIKServiceRoutable, and conformed by LoginService
 @protocol LoginServiceInput <ZIKServiceRoutable>
 @end
 @endcode
 
 2. Create router subclass for LoginService:
 @code
 // Make router subclass for your module
 @import ZIKRouter;
 @interface LoginServiceRouter: ZIKServiceRouter
 @end
 
 @import ZIKRouter.Internal;
 DeclareRoutableService(LoginService, LoginServiceRouter)
 @implementation LoginServiceRouter
 
 + (void)registerRoutableDestination {
    [self registerService:[LoginService class]];
    [self registerServiceProtocol:ZIKRoutable(LoginServiceInput)];
 }
 
 - (id<LoginServiceInput>)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    LoginService *destination = [[LoginService alloc] init];
    return destination;
 }
 
 @end
 @endcode
 
 @code
 // If you don't want to use a router subclass, just register class and protocol with ZIKServiceRouter
 [ZIKServiceRouter registerServiceProtocol:ZIKRoutable(LoginServiceInput) forMakingService:[LoginService class]];
 @endcode
 
 Then you can use the module:
 @code
 // Use the service
 id<LoginServiceInput> loginService;
 loginService = [ZIKRouterToService(LoginServiceInput)
                    makeDestinationWithPreparation:^(id<LoginServiceInput> destination) {
                      // Prepare service
                }];
 @endcode
 */
@interface ZIKServiceRouter<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRouter<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

@end

/// Find router with service protocol. See ZIKRouteErrorInvalidProtocol.
FOUNDATION_EXTERN ZIKRouteAction const ZIKRouteActionToService;
/// Find router with service module protocol. See ZIKRouteErrorInvalidProtocol.
FOUNDATION_EXTERN ZIKRouteAction const ZIKRouteActionToServiceModule;

/**
 Error handler for all service routers, for debug and log.
 @discussion
 Actions: performRoute, removeRoute
 
 @param router The router where error happens
 @param routeAction The action where error happens
 @param error Error in ZIKRouteErrorDomain or domain from subclass router, see ZIKServiceRouteError for detail
 */
typedef void(^ZIKServiceRouteGlobalErrorHandler)(__kindof ZIKServiceRouter * _Nullable router, ZIKRouteAction routeAction, NSError *error);

@interface ZIKServiceRouter (ErrorHandle)

//Set error handler for all service router instance. Use this to debug and log.
@property (class, copy, nullable) void(^globalErrorHandler)(__kindof ZIKServiceRouter *_Nullable router, ZIKRouteAction action, NSError *error);

@end

@interface ZIKServiceRouter (Register)

/**
 Register a service class with this router class.
 One router may manage multi services. You can register multi service classes to a same router class.
 
 @param serviceClass The service class registered with this router class.
 */
+ (void)registerService:(Class)serviceClass;

/**
 Register a service class with this router class, then no other router can be registered for this service class. It has much better performance than `+registerService:`.
 @discussion
 If the service will hold and use its router, and the router has its custom functions for this service, that means the service is coupled with the router. You can use this method to register. If another router class try to register with the service class, there will be an assert failure.
 
 @param serviceClass The service class uniquely registered with this router class.
 */
+ (void)registerExclusiveService:(Class)serviceClass;

/**
 Register a service protocol that all services registered with the router conforming to, then use ZIKRouterToService() to get the router class. In Swift, use `register(RoutableService<ServiceProtocol>())` in ZRouter instead.
 
 @param serviceProtocol The protocol conformed by service. Should inherit from ZIKServiceRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 */
+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol;

/**
 Register a module config protocol the router's default configuration conforms, then use ZIKRouterToServiceModule() to get the router class. In Swift, use `register(RoutableServiceModule<ModuleProtocol>())` in ZRouter instead.
 
 When the service module is not only a single service class, but also other internal services, and you can't prepare the module with a simple service protocol, then you need a module config protocol, and let router prepare the module inside..
 
 @param configProtocol The protocol conformed by default route configuration of this router class. Should inherit from ZIKServiceModuleRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 */
+ (void)registerModuleProtocol:(Protocol<ZIKServiceModuleRoutable> *)configProtocol;

/// Register a unique identifier for this router class.
+ (void)registerIdentifier:(NSString *)identifier;

/// Is registration all finished. Can't register any router after registration is finished.
+ (BOOL)isRegistrationFinished;

@end

@interface ZIKServiceRouter<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (RegisterMaking)

/**
 Register protocol with service class, without using any router subclass. The service will be created with `[[serviceClass alloc] init]` when used. Use this if your service is very easy and don't need a router subclass.
 
 @code
 // Just registering with ZIKServiceRouter
 [ZIKServiceRouter registerServiceProtocol:ZIKRoutable(ServiceProtocol) forMakingService:[Service class]];
 @endcode
 
 @warning
 You can't register a pure swift class or swift class which has custom designated initializer, `[[serviceClass alloc] init]` will crash.
 For swift class, you can use `registerServiceProtocol:forMakingService:making:` instead.

 @param serviceProtocol The protocol conformed by service. Should inherit from ZIKServiceRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 @param serviceClass The service class.
 */
+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol forMakingService:(Class)serviceClass;

/**
 Register protocol with service class and factory function, without using any router subclass. The service will be created with the factory function when used. Use this if your service is very easy and don't need a router subclass.
 
 @param serviceProtocol The protocol conformed by service. Should inherit from ZIKServiceRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 @param serviceClass The service class.
 @param function Function to create destination.
 */
+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol forMakingService:(Class)serviceClass factory:(_Nullable Destination(*_Nonnull)(RouteConfig))function;

/**
 Register protocol with service class and factory block, without using any router subclass. The service will be created with the `making` block when used. Use this if your service is very easy and don't need a router subclass.

 @code
 // Just registering with ZIKServiceRouter
 [ZIKServiceRouter
    registerServiceProtocol:ZIKRoutable(ServiceProtocol)
    forMakingService:[EasyService class]
    making:^id _Nullable(ZIKPerformRouteConfiguration *config, __kindof ZIKServiceRouter *router) {
        return [[EasyService alloc] init];
 }];
 @endcode
 
 @param serviceProtocol The protocol conformed by service. Should inherit from ZIKServiceRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 @param serviceClass The service class.
 @param makeDestination Block creating the service.
 */
+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol
               forMakingService:(Class)serviceClass
                         making:(_Nullable Destination(^)(RouteConfig config))makeDestination;

/**
 Register module config protocol with service class and config factory function, without using any router subclass or configuration subclass. The service will be created with the `makeDestination` block in the configuration. Use this if your service is very easy and don't need a router subclass or configuration subclass.
 
 If a module need a few required parameters when creating destination, you can declare makeDestinationWith in module config protocol:
 @code
 @protocol LoginServiceModuleInput <ZIKServiceModuleRoutable>
 /// Pass required parameter and return destination with LoginServiceInput type.
 @property (nonatomic, copy, readonly) id<LoginServiceInput> _Nullable(^makeDestinationWith)(NSString *account);
 @end
 @endcode
 
 Then register module with module config factory block:
 @code
 // Let ZIKServiceMakeableConfiguration conform to LoginServiceModuleInput
 DeclareRoutableServiceModuleProtocol(LoginServiceModuleInput)
 
 // C function that creating the configuration
 ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *makeLoginServiceModuleConfiguration(void) {
    ZIKServiceMakeableConfiguration *config = [ZIKServiceMakeableConfiguration new];
    __weak typeof(config) weakConfig = config;
    config._prepareDestination = ^(id destination) {
        // Prepare the destination
    };
    // User is responsible for calling makeDestinationWith and giving parameters
    config.makeDestinationWith = id^(NSString *account) {
 
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        weakConfig.makeDestination = ^LoginService * _Nullable{
            // Use custom initializer
            LoginService *destination = [LoginService alloc] initWithAccount:account];
            return destination;
        };
        // Set makedDestination, so the router won't make destination and prepare destination again when perform with this configuration
        weakConfig.makedDestination = weakConfig.makeDestination();
        return weakConfig.makedDestination;
    };
    return config;
 }
 
 // Register the function with LoginServiceModuleInput in some +registerRoutableDestination
 [ZIKModuleServiceRouter(LoginServiceModuleInput)
    registerModuleProtocol:ZIKRoutable(LoginServiceModuleInput)
    forMakingService:[LoginService class]
    factory:makeLoginServiceModuleConfiguration];
 @endcode
 
 You can use this module with LoginServiceModuleInput:
 @code
 [ZIKRouterToServiceModule(LoginServiceModuleInput)
    performWithConfiguring:^(ZIKPerformRouteConfiguration<LoginServiceModuleInput> *config) {
         id<LoginServiceInput> destination = config.makeDestinationWith(@"account");
 }];
 @endcode
 
 @param configProtocol The protocol conformed by configuration. Should inherit from ZIKServiceModuleRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 @param serviceClass The service class.
 @param function Function creating the configuration. The configuration should has makeDestination block.
 */
+ (void)registerModuleProtocol:(Protocol<ZIKServiceModuleRoutable> *)configProtocol
              forMakingService:(Class)serviceClass
                       factory:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull (*_Nonnull)(void))function;

/**
 Register module config protocol with service class and config factory block, without using any router subclass or configuration subclass. The service will be created with the `makeDestination` block in the configuration. Use this if your service is very easy and don't need a router subclass or configuration subclass.
 
 If a module need a few required parameters when creating destination, you can declare makeDestinationWith in module config protocol:
 @code
 @protocol LoginServiceModuleInput <ZIKServiceModuleRoutable>
 /// Pass required parameter and return destination with LoginServiceInput type.
 @property (nonatomic, copy, readonly) id<LoginServiceInput> _Nullable(^makeDestinationWith)(NSString *account);
 @end
 @endcode
 
 Then register module with module config factory block:
 @code
 // Let ZIKServiceMakeableConfiguration conform to LoginServiceModuleInput
 DeclareRoutableServiceModuleProtocol(LoginServiceModuleInput)
 
 // Register in some +registerRoutableDestination
 [ZIKModuleServiceRouter(LoginServiceModuleInput)
    registerModuleProtocol:ZIKRoutable(LoginServiceModuleInput)
    forMakingService:[LoginService class]
    making:^ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull{
 
        ZIKServiceMakeableConfiguration *config = [ZIKServiceMakeableConfiguration new];
        __weak typeof(config) weakConfig = config;
        config._prepareDestination = ^(id destination) {
            // Prepare the destination
        };
        // User is responsible for calling makeDestinationWith and giving parameters
        config.makeDestinationWith = id^(NSString *account) {
 
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            weakConfig.makeDestination = ^LoginService * _Nullable{
                // Use custom initializer
                LoginService *destination = [LoginService alloc] initWithAccount:account];
                return destination;
            };
            // Set makedDestination, so the router won't make destination and prepare destination again when perform with this configuration
            weakConfig.makedDestination = weakConfig.makeDestination();
            return weakConfig.makedDestination;
        };
        return config;
 }];
 @endcode
 
 You can use this module with LoginServiceModuleInput:
 @code
 [ZIKRouterToServiceModule(LoginServiceModuleInput)
     performWithConfiguring:^(ZIKPerformRouteConfiguration<LoginServiceModuleInput> *config) {
        id<LoginServiceInput> destination = config.makeDestinationWith(@"account");
 }];
 @endcode
 
 @param configProtocol The protocol conformed by configuration. Should inherit from ZIKServiceModuleRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 @param serviceClass The service class.
 @param makeConfiguration Block creating the service configuration.
 */
+ (void)registerModuleProtocol:(Protocol<ZIKServiceModuleRoutable> *)configProtocol
              forMakingService:(Class)serviceClass
                        making:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))makeConfiguration;

/**
 Register identifier with service class, without using any router subclass. The service will be created with `[[serviceClass alloc] init]` when used. Use this if your service is very easy and don't need a router subclass.
 
 @code
 // Just registering with ZIKServiceRouter
 [ZIKServiceRouter registerIdentifier:@"app://service" forMakingService:[Service class]];
 @endcode
 
 For swift class, you can use `registerIdentifier:forMakingService:making:` instead.
 
 @param identifier The unique identifier for this class.
 @param serviceClass The service class.
 */
+ (void)registerIdentifier:(NSString *)identifier forMakingService:(Class)serviceClass;

/**
 Register identifier with service class, without using any router subclass. The service will be created with the factory function when used. Use this if your service is very easy and don't need a router subclass.
 
 @param identifier The unique identifier for this class.
 @param serviceClass The service class.
 @param function Function to create destination.
 */
+ (void)registerIdentifier:(NSString *)identifier forMakingService:(Class)serviceClass factory:(_Nullable Destination(*_Nonnull)(RouteConfig))function;

/**
 Register identifier with service class, without using any router subclass. The service will be created with the `making` block when used. Use this if your service is very easy and don't need a router subclass.
 
 @code
 // Just registering with ZIKServiceRouter
 [ZIKServiceRouter
     registerIdentifier:@"app://service"
     forMakingService:[Service class]
     making:^id _Nullable(ZIKPerformRouteConfiguration *config, __kindof ZIKServiceRouter *router) {
        return [[Service alloc] init];
 }];
 @endcode
 
 @param identifier The unique identifier for this class.
 @param serviceClass The service class.
 @param makeDestination Block creating the service.
 */
+ (void)registerIdentifier:(NSString *)identifier
          forMakingService:(Class)serviceClass
                    making:(_Nullable Destination(^)(RouteConfig config))makeDestination;

/**
 Register identifier with service class and config factory function, without using any router subclass or configuration subclass. The service will be created with the `makeDestination` block in the configuration. Use this if your service is very easy and don't need a router subclass or configuration subclass.
 
 See registerModuleProtocol:forMakingService:factory:
 
 @param identifier The unique identifier for this class.
 @param serviceClass The service class.
 @param function Function creating the configuration.
 */
+ (void)registerIdentifier:(NSString *)identifier
          forMakingService:(Class)serviceClass
      configurationFactory:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> * _Nonnull (*_Nonnull)(void))function;

/**
 Register identifier with service class and config factory block, without using any router subclass or configuration subclass. The service will be created with the `makeDestination` block in the configuration. Use this if your service is very easy and don't need a router subclass or configuration subclass.
 
 See registerModuleProtocol:forMakingService:making:
 
 @param identifier The unique identifier for this class.
 @param serviceClass The service class.
 @param makeConfiguration Block creating the configuration.
 */
+ (void)registerIdentifier:(NSString *)identifier
          forMakingService:(Class)serviceClass
       configurationMaking:(ZIKPerformRouteConfiguration<ZIKConfigurationMakeable> *(^)(void))makeConfiguration;

@end

/// Add module config protocol that only has makeDestinationWith, or constructDestination and didMakeDestination to ZIKServiceMakeableConfiguration.
#define DeclareRoutableServiceModuleProtocol(PROTOCOL) ZIX_ADD_CATEGORY(ZIKServiceMakeableConfiguration, PROTOCOL)

@interface ZIKServiceRouter (Utility)

/**
 Enumerate all service routers. You can notify custom events to service routers with it.
 
 @param handler The enumerator gives subclasses of ZIKServiceRouter.
 */
+ (void)enumerateAllServiceRouters:(void(NS_NOESCAPE ^)(Class routerClass))handler;

@end

/// If a class conforms to ZIKRoutableService, there must be a router for it and its subclass. Don't use it in other place.
@protocol ZIKRoutableService

@end

/// Convenient macro to let service conform to ZIKRoutableService, and declare that it's routable.
#define DeclareRoutableService(RoutableService, ExtensionName)    \
@interface RoutableService (ExtensionName) <ZIKRoutableService>    \
@end    \
@implementation RoutableService (ExtensionName) \
@end    \

#pragma mark Alias

typedef ZIKServiceRouter<id, ZIKPerformRouteConfig *> ZIKAnyServiceRouter;
#define ZIKDestinationServiceRouter(Destination) ZIKServiceRouter<Destination, ZIKPerformRouteConfig *>
#define ZIKModuleServiceRouter(ModuleConfigProtocol) ZIKServiceRouter<id, ZIKPerformRouteConfig<ModuleConfigProtocol> *>

NS_ASSUME_NONNULL_END
