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

/// Get service router in a type safe way. There will be compile error if the service protocol is not ZIKServiceRoutable.
#define ZIKRouterToService(ServiceProtocol) [ZIKServiceRouter<id<ServiceProtocol>,ZIKPerformRouteConfiguration *> toService](ZIKRoutable(ServiceProtocol))

/// Get service router in a type safe way. There will be compile error if the module protocol is not ZIKServiceModuleRoutable.
#define ZIKRouterToServiceModule(ModuleProtocol) [ZIKServiceRouter<id,ZIKPerformRouteConfiguration<ModuleProtocol> *> toModule](ZIKRoutable(ModuleProtocol))

@interface ZIKServiceRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> (Discover)

/**
 Get the router class registered with a service protocol. Always use macro `ZIKRouterToService` to get router class, don't use this method directly.
 
 The parameter serviceProtocol of the block is: the protocol conformed by the service. Should be a ZIKServiceRoutable protocol.
 
 The return value `ZIKServiceRouterType` of the block is a router matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) ZIKServiceRouterType<Destination, RouteConfig> * _Nullable (^toService)(Protocol<ZIKServiceRoutable> *serviceProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableService<ServiceProtocol>())` in ZRouter instead");

/**
 Get the router class combined with a custom ZIKRouteConfiguration conforming to a unique protocol. Always use `ZIKRouterToModule`, don't use this method directly.
 
 The parameter configProtocol of the block is: the protocol conformed by defaultConfiguration of router. Should be a ZIKServiceModuleRoutable protocol.
 The return value `ZIKServiceRouterType` of the block is a router matched with the service. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
@property (nonatomic,class,readonly) ZIKServiceRouterType<Destination, RouteConfig> * _Nullable (^toModule)(Protocol<ZIKServiceModuleRoutable> *configProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableServiceModule<ModuleProtocol>())` in ZRouter instead");

/**
 Get all service routers for the destination class and its super class. The result will be empty if destination class doesn't conform to ZIKRoutableService. This method is for handling external destination. You can prepare the external destination when you don't know its router.
 
 @note
 It searchs routers for the destination class, then its super class. If you want to perform route on the destination, choose the first router in the array.
 @warning
 If the router requires to prepare the destination with its protocol, the route action may fail. So only use this method when necessary.
 */
@property (nonatomic, class, readonly) NSArray<ZIKAnyServiceRouterType *> * (^routersToClass)(Class destinationClass);

/// Find service router registered with the unique identifier.
@property (nonatomic, class, readonly) ZIKAnyServiceRouterType * _Nullable (^toIdentifier)(NSString *identifier);

@end

NS_ASSUME_NONNULL_END
