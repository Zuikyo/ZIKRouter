//
//  ZIKViewRouterType.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRouterType.h"
#import "ZIKViewRouteConfiguration.h"
#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Proxy and wrapper to use ZIKViewRouter class type or ZIKViewRoute with compile time checking. These instance methods are actually class methods in ZIKViewRouter class.
@interface ZIKViewRouterType<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKRouterType<Destination, RouteConfig, ZIKViewRemoveConfiguration *>

///Router doesn't support all routeTypes, for example, router for a UIView destination can't support those UIViewController's routeTypes
- (BOOL)supportRouteType:(ZIKViewRouteType)type;

/**
 Perform route from source view to destination view.
 
 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Build the configuration in the block.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Perform route from source view to destination view, and config the remove route.
 
 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Build the configuration in the block.
 @param removeConfigBuilder Build the remove configuration in the block.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                            configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                               removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

///If this destination doesn't need any variable to initialize, just pass source and perform route.
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route.
 @param configBuilder Builder for config when perform route.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination fromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                               configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route.
 @param source The source view.
 @param routeType Route type to perform.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination fromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType;

/**
 Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                             configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                                removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

@end

typedef ZIKViewRouterType<id<ZIKRoutableView>, ZIKViewRouteConfiguration *> ZIKAnyViewRouterType;

NS_ASSUME_NONNULL_END
