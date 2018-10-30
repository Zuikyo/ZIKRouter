//
//  ZIKViewRouterType.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouterType.h"
#import "ZIKViewRouteConfiguration.h"
#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

/// Proxy to use ZIKViewRouter class type or ZIKViewRoute with compile time checking. These instance methods are actually class methods in ZIKViewRouter class.
@interface ZIKViewRouterType<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKRouterType<Destination, RouteConfig, ZIKViewRemoveConfiguration *>
@end

@interface ZIKViewRouterType<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *>(Proxy)
/// Check whether the router support a route type.
- (BOOL)supportRouteType:(ZIKViewRouteType)type;

#pragma mark Perform

/**
 Perform route from source view to destination view.
 
 @param path The route path with source and route type.
 @param configBuilder Build the configuration in the block.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Perform route from source view to destination view, and config the remove route.
 
 @param path The route path with source and route type.
 @param configBuilder Build the configuration in the block.
 @param removeConfigBuilder Build the remove configuration in the block.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path
                                                      configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                         removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

/// If this destination doesn't need any variable to initialize, just pass source and perform route.
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path;

/// If this destination doesn't need any variable to initialize, just pass source and perform route. The successHandler and errorHandler are for current performing.
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path
                                                   successHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                                                     errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;

/// If this destination doesn't need any variable to initialize, just pass source and perform route. The escaping completion is for current performing.
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path
                                                       completion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

/// If this destination doesn't need any variable to initialize, just pass source and perform route. The blcok is an escaping block, use weak self in it.
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path preparation:(void(^)(Destination destination))prepare;

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path
                                                strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performPath:(ZIKViewRoutePath *)path
                                                strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                                   strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder;

- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                         strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                         strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                                            strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Builder for config when perform route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                      path:(ZIKViewRoutePath *)path
                                                               configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                      path:(ZIKViewRoutePath *)path
                                                               configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination path:(ZIKViewRoutePath *)path;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                      path:(ZIKViewRoutePath *)path
                                                         strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                      path:(ZIKViewRoutePath *)path
                                                         strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                                            strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder;

/**
 Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                             configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                                removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                       strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                       strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                                          strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder;

#pragma mark Deprecated

- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder API_DEPRECATED_WITH_REPLACEMENT("performPath:configuring:", ios(7.0, 7.0));

- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                            configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                               removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("performPath:configuring:removing:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType API_DEPRECATED_WITH_REPLACEMENT("performPath:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                      strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder API_DEPRECATED_WITH_REPLACEMENT("performPath:strictConfiguring:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                      strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                                         strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder
#if TARGET_OS_TV
API_DEPRECATED_WITH_REPLACEMENT("performPath:strictConfiguring:strictRemoving:", ios(7.0, 10.0))
#else
API_DEPRECATED_WITH_REPLACEMENT("performPath:strictConfiguring:strictRemoving:", ios(7.0, 8.0))
#endif
;
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                              routeType:(ZIKViewRouteType)routeType
                                                         successHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                                                           errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler API_DEPRECATED_WITH_REPLACEMENT("performPath:successHandler:errorHandler:" ,ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                               configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder API_DEPRECATED_WITH_REPLACEMENT("performOnDestination:path:configuring:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                               configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                                 routeType:(ZIKViewRouteType)routeType API_DEPRECATED_WITH_REPLACEMENT("performOnDestination:path:", ios(7.0, 7.0));

@end

typedef ZIKViewRouterType<id, ZIKViewRouteConfiguration *> ZIKAnyViewRouterType;

NS_ASSUME_NONNULL_END
