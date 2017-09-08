//
//  ZIKServiceRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKRouter.h"
#import "ZIKServiceRoutable.h"
#import "ZIKServiceConfigRoutable.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kZIKServiceRouterErrorDomain;

@class ZIKServiceRouter, ZIKServiceRouteConfiguration;

@protocol ZIKServiceRouterProtocol <NSObject>

+ (void)registerRoutableDestination;
- (nullable id)destinationWithConfiguration:(__kindof ZIKServiceRouteConfiguration *)configuration;

@end



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
 Service router for discovering service and inject dependencies. Subclass it and implement ZIKRouterProtocol to make router of your service.
 
 @code
 __block id<ZIKLoginServiceInput> loginService;
 [ZIKServiceRouterForService(@protocol(ZIKLoginServiceInput))
     performWithConfigure:^(__kindof ZIKServiceRouteConfiguration *config) {
         config.prepareForRoute = ^(id<ZIKLoginServiceInput> destination) {
             //Prepare service
         };
         config.routeCompletion = ^(id destination) {
             loginService = destination;
         };
 }];
 @endcode
 
 @note
 Default implement of -performXX will call routeCompletion synchronously, so the user can get service synchronously. If a service can only be generated asynchronously, Subclass router should override -performWithConfiguration:, and call -attachDestination: asynchronously.
 */
@interface ZIKServiceRouter : ZIKRouter <ZIKServiceRouterProtocol>

///Covariant from superclass
- (__kindof ZIKServiceRouteConfiguration *)configuration;

- (nullable instancetype)initWithConfiguration:(__kindof ZIKServiceRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKRouteConfiguration *)removeConfiguration NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKServiceRouteConfiguration *config))configBuilder
                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(__kindof ZIKRouteConfiguration *config))removeConfigBuilder;

///Convenient method to perform route
+ (nullable __kindof ZIKServiceRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKServiceRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKRouteConfiguration *config))removeConfigBuilder;
+ (nullable __kindof ZIKServiceRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKServiceRouteConfiguration *config))configBuilder;

///Default implemenation will call routeCompletion synchronously, so the user can get service synchronously. Subclass router may return NO if it's service can only be generated asynchronously.
+ (BOOL)completeSynchronously;

///Set error callback for all service router instance. Use this to debug and log
+ (void)setGlobalErrorHandler:(ZIKServiceRouteGlobalErrorHandler)globalErrorHandler;
@end

typedef NS_ENUM(NSInteger, ZIKServiceRouteError) {
    ZIKServiceRouteErrorInvaidProtocol,
    ZIKServiceRouteErrorServiceUnavailable
};

@interface ZIKServiceRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareForRoute to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareForRoute)(id destination);

/**
 Completion for performRoute. Default implemenation will call routeCompletion synchronously.
 
 @note
 Use weakSelf in routeCompletion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^routeCompletion)(id destination);
@end

extern _Nullable Class ZIKServiceRouterForService(Protocol<ZIKServiceRoutable> *serviceProtocol);

extern _Nullable Class ZIKServiceRouterForConfig(Protocol<ZIKServiceConfigRoutable> *configProtocol);

#pragma mark Router Register

#ifdef DEBUG
#define ZIKSERVICEROUTER_CHECK true
#else
#define ZIKSERVICEROUTER_CHECK false
#endif

/**
 Register a service class with it's router's class.
 One router may manage multi services. You can register multi service classes to a same router class.
 
 @param serviceClass The service class managed by router
 @param routerClass The router class to bind with service class
 */
extern void ZIKServiceRouter_registerService(Class serviceClass, Class routerClass);

/**
 If the service will hold and use it's router, and the router has it's custom functions for this service, that means the service is coupled with the router. In this situation, you can use this function to combine serviceClass with a specific routerClass, then no other routerClass can be used for this serviceClass. If another routerClass try to register with the serviceClass, there will be an assert failure.
 
 @param serviceClass The service class requiring a specific router class
 @param routerClass The unique router class to bind with service class
 */
extern void ZIKServiceRouter_registerServiceForExclusiveRouter(Class serviceClass, Class routerClass);

/**
 Register a service protocol that all services registered with the router conform to, then use ZIKServiceRouterForService() to get the router class.You can register your protocol and let the service conforms to the protocol in category in your interface adapter.
 
 @param serviceProtocol The protocol conformed by service to identify the routerClass
 @param routerClass The router class to bind with service class
 */
extern void ZIKServiceRouter_registerServiceProtocol(Protocol *serviceProtocol, Class routerClass);

/**
 Register a config protocol the router's default configuration conforms, then use ZIKServiceRouterForConfig() to get the router class.You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass
 @param routerClass The router class to bind with service class
 */
extern void ZIKServiceRouter_registerConfigProtocol(Protocol *configProtocol, Class routerClass);

///It's a mark for service classes with router. Don't use it in other place.
@protocol ZIKRoutableService <NSObject>

@end

NS_ASSUME_NONNULL_END
