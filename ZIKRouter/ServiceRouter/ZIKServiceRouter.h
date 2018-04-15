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

///Find router with service protocol. See ZIKRouteErrorInvalidProtocol.
extern ZIKRouteAction const ZIKRouteActionToService;
///Find router with service module protocol. See ZIKRouteErrorInvalidProtocol.
extern ZIKRouteAction const ZIKRouteActionToServiceModule;

@class ZIKServiceRouter;
/**
 Error handler for all service routers, for debug and log.
 @discussion
 Actions: performRoute, removeRoute
 
 @param router The router where error happens
 @param routeAction The action where error happens
 @param error Error in ZIKRouteErrorDomain or domain from subclass router, see ZIKServiceRouteError for detail
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

//Set error handler for all service router instance. Use this to debug and log.
@property (class, copy, nullable) void(^globalErrorHandler)(__kindof ZIKServiceRouter *_Nullable router, ZIKRouteAction action, NSError *error);

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
+ (void)registerServiceProtocol:(Protocol<ZIKServiceRoutable> *)serviceProtocol;

/**
 Register a module config protocol the router's default configuration conforms, then use ZIKServiceRouterToModule() to get the router class. You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 When the service module contains not only a single service class, but also other internal services, and you can't prepare the module with a simple service protocol, then you need a module config protocol.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass. Should inherit from ZIKServiceModuleRoutable when ZIKROUTER_CHECK is enabled. Use macro `ZIKRoutableProtocol` to check whether the protocol is routable.
 */
+ (void)registerModuleProtocol:(Protocol<ZIKServiceModuleRoutable> *)configProtocol;

///Is registration all finished.
+ (BOOL)isRegistrationFinished;

@end

///If a class conforms to ZIKRoutableService, there must be a router for it and it's subclass. Don't use it in other place.
@protocol ZIKRoutableService

@end

///Convenient macro to let service conform to ZIKRoutableService, and declare that it's routable.
#define DeclareRoutableService(RoutableService, ExtensionName)    \
@interface RoutableService (ExtensionName) <ZIKRoutableService>    \
@end    \
@implementation RoutableService (ExtensionName) \
@end    \



NS_ASSUME_NONNULL_END
