//
//  ZIKServiceRoute.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRoute.h"
#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Use ZIKServiceRoute to add service route with blocks, rather than creating subclass of ZIKServiceRouter.
 
 @code
 [ZIKDestinationServiceRoute(id<LoginServiceInput>)
    makeRouteWithDestination:[LoginService class]
    makeDestination:^id<LoginServiceInput> _Nullable(ZIKPerformRouteConfig *config, __kindof ZIKRouter *router) {
        LoginService *destination = [[LoginService alloc] init];
        return destination;
 }]
 .prepareDestination(^(id<LoginServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
    // Prepare the destination
 })
 .registerDestinationProtocol(ZIKRoutable(LoginServiceInput));
 @endcode
 */
@interface ZIKServiceRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRoute<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

//Set name of this route.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^nameAs)(NSString *name);

/// Register a service class with this route. See +registerService:.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerDestination)(Class destinationClass);

/// Combine service class with this route, then no other router can be registered for this service class. See +registerExclusiveService:.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerExclusiveDestination)(Class destinationClass);

/// Register a service protocol that all services registered with the router conforming to, then use ZIKRouterToService() to get the router class. In Swift, use `register(RoutableService<ServiceProtocol>())` in ZRouter instead. See +registerServiceProtocol:.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerDestinationProtocol)(Protocol<ZIKServiceRoutable> *destinationProtocol);

/// Register a module config protocol the router's default configuration conforms, then use ZIKRouterToServiceModule() to get the router class. In Swift, use `register(RoutableServiceModule<ModuleProtocol>())` in ZRouter instead. See +registerModuleProtocol:.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerModuleProtocol)(Protocol<ZIKServiceModuleRoutable> *moduleConfigProtocol);

/// Register a unique identifier for this route.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerIdentifier)(NSString *identifier);

/// If the router use a custom configuration, override this and return the configuration. See +defaultRouteConfiguration.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));

/// If the router use a custom configuration, override this and return the configuration. See +defaultRemoveConfiguration.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^makeDefaultRemoveConfiguration)(ZIKRemoveRouteConfiguration *(^)(void));

/// Prepare the destination after -prepareDestination is invoked.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKServiceRouter *router));

/// Check whether destination is prepared correctly.
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKServiceRouter *router));

@end

typedef ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> ZIKAnyServiceRoute;
#define ZIKDestinationServiceRoute(Destination) ZIKServiceRoute<Destination, ZIKPerformRouteConfig *>
#define ZIKModuleServiceRoute(ModuleConfigProtocol) ZIKServiceRoute<id, ZIKPerformRouteConfig<ModuleConfigProtocol> *>

NS_ASSUME_NONNULL_END
