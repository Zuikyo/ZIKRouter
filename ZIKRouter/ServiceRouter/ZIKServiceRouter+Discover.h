//
//  ZIKServiceRouter+Discover.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter.h"
#import "ZIKServiceRouterType.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UNAVAILABLE("ZIKDestinationServiceRouterType is a fake class")
///Fake class to use ZIKServiceRouter class type to handle specific destination with compile time checking. The real object is ZIKServiceRouterType. Don't check whether a type is kind of ZIKDestinationServiceRouterType.
@interface ZIKDestinationServiceRouterType<__covariant Destination: id<ZIKServiceRoutable>, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKServiceRouterType<Destination, RouteConfig>

@end

NS_SWIFT_UNAVAILABLE("ZIKModuleServiceRouterType is a fake class")
///Fake class to use ZIKServiceRouter class type to handle specific view module config with compile time checking. The real object is ZIKServiceRouterType. Don't check whether a type is kind of ZIKModuleServiceRouterType.
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
 Get the router class combined with a custom ZIKRouteConfiguration conforming to a unique protocol. Always use `ZIKServiceRouterToModule`, don't use this method directly.
 
 The parameter configProtocol of the block is: the protocol conformed by defaultConfiguration of router. Should be a ZIKServiceModuleRoutable protocol when ZIKROUTER_CHECK is enabled.
 The return Class of the block is: a router class matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) ZIKModuleServiceRouterType<Destination, id<ZIKServiceModuleRoutable>, RouteConfig> * _Nullable (^toModule)(Protocol *configProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableServiceModule<ModuleProtocol>())` in ZRouter instead");

///Find service router registered with the unique identifier.
@property (nonatomic, class, readonly) ZIKAnyServiceRouterType * _Nullable (^toIdentifier)(NSString *identifier);

@end

@interface ZIKDestinationServiceRouterType<__covariant Destination: id<ZIKServiceRoutable>, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Extension)

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The router.
 */
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                           void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                           void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                                           ))configBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route, and you can remove the route with remove configuration later.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return The router.
 */
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                           void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                           void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                                           ))configBuilder
                                                                       strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config,
                                                                                                                     void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                                     ))removeConfigBuilder;

@end

@interface ZIKModuleServiceRouterType<__covariant Destination: id, __covariant ModuleConfig: id<ZIKServiceModuleRoutable>, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Extension)

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The router.
 */
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                           void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                           void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                                           ))configBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route, and you can remove the route with remove configuration later.
 
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return The router.
 */
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                           void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                           void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                                           ))configBuilder
                                                                       strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config,
                                                                                                                     void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                                     ))removeConfigBuilder;

@end

NS_ASSUME_NONNULL_END
