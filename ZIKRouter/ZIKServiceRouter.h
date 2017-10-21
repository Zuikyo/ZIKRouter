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
#import "ZIKServiceConfigRoutable.h"
#import "ZIKServiceRouteConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kZIKServiceRouterErrorDomain;

@class ZIKServiceRouter, ZIKServiceRouteConfiguration;

@protocol ZIKServiceRouterProtocol <NSObject>

///Register the destination class with those ZIKServiceRouter_registerXXX functions. ZIKServiceRouter will call this method at startup. If a router was not registered with any service class, there'll be an assert failure.
+ (void)registerRoutableDestination;

///Create and initialize destination with configuration.
- (nullable id)destinationWithConfiguration:(__kindof ZIKServiceRouteConfiguration *)configuration;

@end

#ifdef DEBUG
#define ZIKSERVICEROUTER_CHECK 1
#else
#define ZIKSERVICEROUTER_CHECK 0
#endif

/**
 Error handler for all service routers, for debug and log.
 @discussion
 Actions: performRoute, removeRoute
 
 @param router The router where error happens
 @param routeAction The action where error happens
 @param error Error in kZIKServiceRouterErrorDomain or domain from subclass router, see ZIKServiceRouteError for detail
 */
typedef void(^ZIKServiceRouteGlobalErrorHandler)(__kindof ZIKServiceRouter * _Nullable router, SEL routeAction, NSError *error);

/**
 Service router for discovering service and injecting dependencies. Subclass it and implement ZIKRouterProtocol to make router of your service.
 
 @code
 __block id<ZIKLoginServiceInput> loginService;
 [ZIKServiceRouterForService(@protocol(ZIKLoginServiceInput))
     performWithConfigure:^(ZIKServiceRouteConfiguration *config) {
         config.prepareForRoute = ^(id<ZIKLoginServiceInput> destination) {
             //Prepare service
         };
         config.routeCompletion = ^(id destination) {
             loginService = destination;
         };
 }];
 @endcode
 
 In Swift, you can use router type with generic and protocol:
 @code
 //Injected dependency from outside
 var loginServiceRouterClass: ZIServiceRouter<ZIKServiceRouteConfiguration & ZIKLoginServiceConfigProtocol, ZIKRouteConfiguration>.Type!
 
 //Use the router type to perform route
 self.loginServiceRouterClass.perform { config in
     //config conforms to ZIKLoginServiceConfigProtocol, modify config to prepare service
     config.prepareForRoute = { destination in
         
     }
     config.routeCompletion = { destination in
         loginService = destination;
     }
 }
 @endcode
 In Objective-C, you can't use a type like Swift, you can only declare a router instance, and let the router be injected from outside:
 @code
 @property (nonatomic, strong) ZIKServiceRouter<ZIKServiceRouteConfiguration<ZIKLoginServiceConfigProtocol> *, ZIKRouteConfiguration*> *loginServiceRouter;
 @endcode
 So, it only works as a dependency daclaration. But this design pattern let you hide subclass type.
 */
@interface ZIKServiceRouter<ServiceRouteConfig: ZIKServiceRouteConfiguration *, ServiceRemoveConfig: ZIKRouteConfiguration *> : ZIKRouter<ServiceRouteConfig, ServiceRemoveConfig, ZIKServiceRouter *> <ZIKServiceRouterProtocol>

///Convenient method to perform route
+ (nullable ZIKServiceRouter<ServiceRouteConfig, ServiceRemoveConfig> *)performWithConfigure:(void(NS_NOESCAPE ^)(ServiceRouteConfig config))configBuilder
                                                                             removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(ServiceRemoveConfig config))removeConfigBuilder;
+ (nullable ZIKServiceRouter<ServiceRouteConfig, ServiceRemoveConfig> *)performWithConfigure:(void(NS_NOESCAPE ^)(ServiceRouteConfig config))configBuilder;

///Default implemenation of -performXX will call routeCompletion synchronously, so the user can get service synchronously. Subclass router may return NO if it's service can only be generated asynchronously.
+ (BOOL)completeSynchronously;

///Set error callback for all service router instance. Use this to debug and log
+ (void)setGlobalErrorHandler:(ZIKServiceRouteGlobalErrorHandler)globalErrorHandler;

#pragma mark Router Register

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
 Register a service protocol that all services registered with the router conform to, then use ZIKServiceRouterForService() to get the router class.You can register your protocol and let the service conforms to the protocol in category in your interface adapter.
 
 @param serviceProtocol The protocol conformed by service to identify the routerClass. Should be a ZIKServiceRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceRoutable.
 */
+ (void)registerServiceProtocol:(Protocol *)serviceProtocol;

/**
 Register a config protocol the router's default configuration conforms, then use ZIKServiceRouterForConfig() to get the router class.You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass. Should be a ZIKServiceConfigRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceConfigRoutable.
 */
+ (void)registerConfigProtocol:(Protocol *)configProtocol;
@end

typedef NS_ENUM(NSInteger, ZIKServiceRouteError) {
    ///The protocol you use to fetch the router is not registered.
    ZIKServiceRouteErrorInvaidProtocol,
    ///Router returns nil for destination, you can't use this service now. Maybe your configuration is invalid, or there is a bug in the router.
    ZIKServiceRouteErrorServiceUnavailable,
    ///Infinite recursion for performing route detected. See ZIKViewRouterProtocol's -prepareDestination:configuration: for more detail.
    ZIKServiceRouteErrorInfiniteRecursion
};

#pragma mark Dynamic Discover

/**
 Get the router class registered with a service class (a ZIKRoutableService) conforming to a unique protocol. Similar to ZIKViewRouterForView().
 
 @param serviceProtocol The protocol conformed by the service. Should be a ZIKServiceRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceRoutable.
 @return A router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKServiceRouterForService(Protocol *serviceProtocol);

/**
 Get the router class combined with a custom ZIKRouteConfiguration conforming to a unique protocol. Similar to ZIKViewRouterForConfig().

 @param configProtocol The protocol conformed by defaultConfiguration of router. Should be a ZIKServiceConfigRoutable protocol when ZIKSERVICEROUTER_CHECK is enabled. When ZIKSERVICEROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKServiceConfigRoutable.
 @return A router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKServiceRouterForConfig(Protocol *configProtocol);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerService:]",ios(7.0,7.0))
extern void ZIKServiceRouter_registerService(Class serviceClass, Class routerClass);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerExclusiveService:]",ios(7.0,7.0))
extern void ZIKServiceRouter_registerServiceForExclusiveRouter(Class serviceClass, Class routerClass);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerServiceProtocol:]",ios(7.0,7.0))
extern void ZIKServiceRouter_registerServiceProtocol(Protocol *serviceProtocol, Class routerClass);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerConfigProtocol:]",ios(7.0,7.0))
extern void ZIKServiceRouter_registerConfigProtocol(Protocol *configProtocol, Class routerClass);

///If a class conforms to ZIKRoutableService, there must be a router for it and it's subclass. Don't use it in other place.
@protocol ZIKRoutableService

@end

NS_ASSUME_NONNULL_END
