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

extern ZIKRouteAction const ZIKRouteActionToService;
extern ZIKRouteAction const ZIKRouteActionToServiceModule;
extern NSString *const kZIKServiceRouterErrorDomain;

@class ZIKServiceRouter;
/**
 Error handler for all service routers, for debug and log.
 @discussion
 Actions: performRoute, removeRoute
 
 @param router The router where error happens
 @param routeAction The action where error happens
 @param error Error in kZIKServiceRouterErrorDomain or domain from subclass router, see ZIKServiceRouteError for detail
 */
typedef void(^ZIKServiceRouteGlobalErrorHandler)(__kindof ZIKServiceRouter * _Nullable router, ZIKRouteAction routeAction, NSError *error);

/**
 Abstract superclass of service router for discovering service and injecting dependencies with registered protocol. Subclass it and override those methods in `ZIKRouterInternal` and `ZIKServiceRouterInternal` to make router of your service.
 
 @code
 id<LoginServiceInput> loginService;
 loginService = [ZIKServiceRouterToService(LoginServiceInput)
                    makeDestinationWithPreparation:^(id<LoginServiceInput> destination) {
                      //Prepare service
                }];
 @endcode
 */
@interface ZIKServiceRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRouter<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

@end

@interface ZIKServiceRouter (ErrorHandle)

///Set error callback for all service router instance. Use this to debug and log.
+ (void)setGlobalErrorHandler:(ZIKServiceRouteGlobalErrorHandler)globalErrorHandler;

@end

@interface ZIKServiceRouter (Register)

/**
 Register a service class with it's router's class.
 One router may manage multi services. You can register multi service classes to a same router class.
 
 @param serviceClass The service class managed by router.
 */
+ (void)registerService:(Class)serviceClass;

/**
 combine serviceClass with a specific routerClass, then no other routerClass can be used for this serviceClass.
 @discussion
 If the service will hold and use it's router, and the router has it's custom functions for this service, that means the service is coupled with the router. You can use this method to register viewClass and routerClass. If another routerClass try to register with the serviceClass, there will be an assert failure.
 
 @param serviceClass The service class requiring a specific router class.
 */
+ (void)registerExclusiveService:(Class)serviceClass;

/**
 Register a service protocol that all services registered with the router conform to, then use ZIKServiceRouterToService() to get the router class.You can register your protocol and let the service conforms to the protocol in category in your interface adapter.
 
 @param serviceProtocol The protocol conformed by service to identify the routerClass. Should inherit from ZIKServiceRoutable when ZIKROUTER_CHECK is enabled. Use macro `ZIKRoutableProtocol` to check whether the protocol is routable.
 */
+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol  NS_SWIFT_UNAVAILABLE("Use `register<Protocol>(_ routableService: RoutableService<Protocol>)` in ZRouter instead");

/**
 Register a module config protocol the router's default configuration conforms, then use ZIKServiceRouterToModule() to get the router class. You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 When the service module contains not only a single service class, but also other internal services, and you can't prepare the module with a simple service protocol, then you need a moudle config protocol.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass. Should inherit from ZIKServiceModuleRoutable when ZIKROUTER_CHECK is enabled. Use macro `ZIKRoutableProtocol` to check whether the protocol is routable.
 */
+ (void)registerModuleProtocol:(Protocol<ZIKServiceModuleRoutable> *)configProtocol  NS_SWIFT_UNAVAILABLE("Use `register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>)`  in ZRouter instead");

@end

NS_ASSUME_NONNULL_END

#import "ZIKRouterType.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UNAVAILABLE("ZIKServiceRouterType is a fake class")
///Fake class to use ZIKServiceRouter class type with compile time checking. The real object is Class of ZIKServiceRouter, so these instance methods are actually class methods in ZIKServiceRouter class. Don't check whether a type is kind of ZIKServiceRouterType.
@interface ZIKServiceRouterType<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRouterType<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

@end

NS_SWIFT_UNAVAILABLE("ZIKDestinationServiceRouterType is a fake class")
///Fake class to use ZIKServiceRouter class type to handle specific destination with compile time checking. The real object is Class of ZIKServiceRouter, so these instance methods are actually class methods in ZIKServiceRouter class. Don't check whether a type is kind of ZIKDestinationServiceRouterType.
@interface ZIKDestinationServiceRouterType<__covariant Destination: id<ZIKServiceRoutable>, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKServiceRouterType<Destination, RouteConfig>

@end

NS_SWIFT_UNAVAILABLE("ZIKModuleServiceRouterType is a fake class")
///Fake class to use ZIKServiceRouter class type to handle specific view module config with compile time checking. The real object is Class of ZIKServiceRouter, so these instance methods are actually class methods in ZIKServiceRouter class. Don't check whether a type is kind of ZIKModuleServiceRouterType.
@interface ZIKModuleServiceRouterType<__covariant Destination: id, __covariant ModuleConfig: id<ZIKServiceModuleRoutable>, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKServiceRouterType<Destination, RouteConfig>

@end

///Get service router in a type safe way. There will be complie error if the service protocol is not ZIKServiceRoutable.
#define ZIKRouterToService(ServiceProtocol) (ZIKDestinationServiceRouterType<id<ServiceProtocol>,ZIKPerformRouteConfiguration *> *)[ZIKServiceRouter<id<ServiceProtocol>,ZIKPerformRouteConfiguration *> toService](@protocol(ServiceProtocol))

///Get service router in a type safe way. There will be complie error if the module protocol is not ZIKServiceModuleRoutable.
#define ZIKRouterToServiceModule(ModuleProtocol) (ZIKModuleServiceRouterType<id,id<ModuleProtocol>,ZIKPerformRouteConfiguration<ModuleProtocol> *> *)[ZIKServiceRouter<id,ZIKPerformRouteConfiguration<ModuleProtocol> *> toModule](@protocol(ModuleProtocol))

///Get service router in a type safe way. There will be complie error if the service protocol is not ZIKServiceRoutable.
#define ZIKServiceRouterToService(ServiceProtocol) (ZIKDestinationServiceRouterType<id<ServiceProtocol>,ZIKPerformRouteConfiguration *> *)[ZIKServiceRouter<id<ServiceProtocol>,ZIKPerformRouteConfiguration *> toService](@protocol(ServiceProtocol))

///Get service router in a type safe way. There will be complie error if the module protocol is not ZIKServiceModuleRoutable.
#define ZIKServiceRouterToModule(ModuleProtocol) (ZIKModuleServiceRouterType<id,id<ModuleProtocol>,ZIKPerformRouteConfiguration<ModuleProtocol> *> *)[ZIKServiceRouter<id,ZIKPerformRouteConfiguration<ModuleProtocol> *> toModule](@protocol(ModuleProtocol))

@interface ZIKServiceRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Discover)

/**
 Get the router class registered with a service protocol. Always use macro `ZIKServiceRouterToService` to get router class, don't use this method directly.
 
 The parameter serviceProtocol of the block is: the protocol conformed by the service. Should be a ZIKServiceRoutable protocol when ZIKROUTER_CHECK is enabled.
 
 The return Class of the block is: a router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) ZIKDestinationServiceRouterType<id<ZIKServiceRoutable>, RouteConfig> * _Nullable (^toService)(Protocol *serviceProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableService<ServiceProtocol>())` in ZRouter instead");

/**
 Return the subclass of ZIKServiceRouter for the protocol. See `toService`. Use macro `ZIKRoutableProtocol` to check whether the protocol is routable.
 @code
 ZIKServiceRouter.classToService(ZIKRoutableProtocol(ServiceProtocol))
 @endcode
 */
@property (nonatomic,class,readonly) Class _Nullable (^classToService)(Protocol<ZIKServiceRoutable> *serviceProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableService<ServiceProtocol>())` in ZRouter instead");

/**
 Get the router class combined with a custom ZIKRouteConfiguration conforming to a unique protocol. Always use `ZIKServiceRouterToModule`, don't use this method directly.
 
 The parameter configProtocol of the block is: the protocol conformed by defaultConfiguration of router. Should be a ZIKServiceModuleRoutable protocol when ZIKROUTER_CHECK is enabled.
 The return Class of the block is: a router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) ZIKModuleServiceRouterType<Destination, id<ZIKServiceModuleRoutable>, RouteConfig> * _Nullable (^toModule)(Protocol *configProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableServiceModule<ModuleProtocol>())` in ZRouter instead");

/**
 Return the subclass of ZIKServiceRouter for the protocol. See `toModule`. Use macro `ZIKRoutableProtocol` to check whether the protocol is routable.
 @code
 ZIKServiceRouter.classToModule(ZIKRoutableProtocol(ServiceModuleProtocol))
 @endcode
 */
@property (nonatomic,class,readonly) Class _Nullable (^classToModule)(Protocol<ZIKServiceModuleRoutable> *configProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableServiceModule<ModuleProtocol>())` in ZRouter instead");

@end

typedef NS_ENUM(NSInteger, ZIKServiceRouteError) {
    ///The protocol you use to fetch the router is not registered.
    ZIKServiceRouteErrorInvalidProtocol,
    ///Router returns nil for destination, you can't use this service now. Maybe your configuration is invalid, or there is a bug in the router.
    ZIKServiceRouteErrorServiceUnavailable,
    ///Perform or remove route action failed. Remove route when destiantion was already dealloced.
    ZIKServiceRouteErrorActionFailed,
    ///Infinite recursion for performing route detected. See -prepareDestination:configuration: for more detail.
    ZIKServiceRouteErrorInfiniteRecursion
};

///If a class conforms to ZIKRoutableService, there must be a router for it and it's subclass. Don't use it in other place.
@protocol ZIKRoutableService

@end

///Convenient macro to let service conform to ZIKRoutableService, and declare that it's routable.
#define DeclareRoutableService(RoutableService, ExtensionName)    \
@interface RoutableService (ExtensionName) <ZIKRoutableService>    \
@end    \
@implementation RoutableService (ExtensionName) \
@end    \

@interface ZIKServiceRouterType<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Extension)

///If this route action doesn't need any arguments, just perform directly.
- (nullable instancetype)performRoute;
///Set dependencies required by destination and perform route.
- (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
- (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config))removeConfigBuilder;

@end

@interface ZIKDestinationServiceRouterType<__covariant Destination: id<ZIKServiceRoutable>, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Extension)

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The router.
 */
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                          ))configBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route, and you can remove the route with remove configuration later.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it).
 @return The router.
 */
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                          ))configBuilder
                                       routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config,
                                                                                    void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                    ))removeConfigBuilder;

@end

@interface ZIKModuleServiceRouterType<__covariant Destination: id, __covariant ModuleConfig: id<ZIKServiceModuleRoutable>, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Extension)

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The router.
 */
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                          ))configBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route, and you can remove the route with remove configuration later.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it).
 @return The router.
 */
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                          ))configBuilder
                                       routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config,
                                                                                    void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                    ))removeConfigBuilder;

@end
NS_ASSUME_NONNULL_END
