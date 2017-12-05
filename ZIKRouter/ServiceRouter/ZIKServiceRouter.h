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
 __block id<LoginServiceInput> loginService;
 loginService = [ZIKServiceRouter.toService(@protocol(LoginServiceInput))
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
 If the service will hold and use it's router, and the router has it's custom functions for this service, that means the service is coupled with the router. In this situation, you can use this function to combine serviceClass with a specific routerClass, then no other routerClass can be used for this serviceClass. If another routerClass try to register with the serviceClass, there will be an assert failure.
 
 @param serviceClass The service class requiring a specific router class.
 */
+ (void)registerExclusiveService:(Class)serviceClass;

/**
 Register a service protocol that all services registered with the router conform to, then use ZIKServiceRouter.toService() to get the router class.You can register your protocol and let the service conforms to the protocol in category in your interface adapter.
 
 @param serviceProtocol The protocol conformed by service to identify the routerClass. Should inherit from ZIKServiceRoutable when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceRoutable.
 */
+ (void)registerServiceProtocol:(Protocol *)serviceProtocol;

/**
 Register a module config protocol the router's default configuration conforms, then use ZIKServiceRouter.toModule() to get the router class. You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 When the service module contains not only a single service class, but also other internal services, and you can't prepare the module with a simple service protocol, then you need a moudle config protocol.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass. Should inherit from ZIKServiceModuleRoutable when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceModuleRoutable.
 */
+ (void)registerModuleProtocol:(Protocol *)configProtocol;

@end

@interface ZIKServiceRouter (Discover)

/**
 Get the router class registered with a service protocol.
 
 The parameter serviceProtocol of the block is: the protocol conformed by the service. Should be a ZIKServiceRoutable protocol when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceRoutable.
 
 The return Class of the block is: a router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) Class _Nullable (^toService)(Protocol *serviceProtocol) NS_SWIFT_UNAVAILABLE("Use Registry.router(to:) function in ZRouter instead.");

/**
 Get the router class combined with a custom ZIKRouteConfiguration conforming to a unique protocol.
 
 The parameter configProtocol of the block is: the protocol conformed by defaultConfiguration of router. Should be a ZIKServiceModuleRoutable protocol when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceModuleRoutable.
 The return Class of the block is: a router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) Class _Nullable (^toModule)(Protocol *configProtocol) NS_SWIFT_UNAVAILABLE("Use Registry.router(to:) function in ZRouter instead.");

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

NS_ASSUME_NONNULL_END
