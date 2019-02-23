//
//  ZIKRoute.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKRouter, ZIKPerformRouteConfiguration, ZIKRemoveRouteConfiguration;

/**
 Abstract superclass to add route with blocks, rather than subclass. Don't use this class directly.
 @note
 The instance can forward class methods in ZIKRouter. When adding class methods in ZIKRouter, the same instance methods should be added in ZIKRoute or its subclass.
 */
@interface ZIKRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject
@property (nonatomic, copy, nullable) NSString *name;

/// The router class to handle this route. ZIKRoute subclass can override and use custom rouer class.
- (Class)routerClass;

/**
 Make and register route. Same with the initializer.
 @note The route object will always exists, won't be released.
 
 @param destinationClass The destination class handled by this route.
 @param makeDestination Create destination and initialize it with configuration. If the configuration is invalid, return nil to make this route failed.
 @return The router.
 */
+ (instancetype)makeRouteWithDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, __kindof ZIKRouter<Destination, RouteConfig, RemoveConfig> *router))makeDestination;

/**
 Make and register route with an exclusive destination.
 @note The route object will always exists, won't be released.
 
 @param destinationClass The exclusive destination class handled by this route.
 @param makeDestination Create destination and initialize it with configuration. If the configuration is invalid, return nil to make this route failed.
 @return The router.
 */
+ (instancetype)makeRouteWithExclusiveDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, __kindof ZIKRouter<Destination, RouteConfig, RemoveConfig> *router))makeDestination;

/**
 Make and register route with destination.
 @note The route object will always exists, won't be released.
 
 @param destinationClass The destination class handled by this route.
 @param makeDestination Create destination and initialize it with configuration. If the configuration is invalid, return nil to make this route failed.
 @return The router.
 */
- (instancetype)initWithDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, __kindof ZIKRouter<Destination, RouteConfig, RemoveConfig> *router))makeDestination NS_DESIGNATED_INITIALIZER;

/**
 Make and register route with an exclusive destination.
 @note The route object will always exists, won't be released.
 
 @param destinationClass The exclusive destination class handled by this route.
 @param makeDestination Create destination and initialize it with configuration. If the configuration is invalid, return nil to make this route failed.
 @return The router.
 */
- (instancetype)initWithExclusiveDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, __kindof ZIKRouter<Destination, RouteConfig, RemoveConfig> *router))makeDestination NS_DESIGNATED_INITIALIZER;

/**
 Create route for making some destination.
 @note The route object is not auto retained. You can use this to create a temp route.

 @param makeDestination Create destination and initialize it with configuration. If the configuration is invalid, return nil to make this route failed.
 @return The router.
 */
- (instancetype)initWithMakeDestination:(_Nullable Destination(^)(RouteConfig config, __kindof ZIKRouter<Destination, RouteConfig, RemoveConfig> *router))makeDestination NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^nameAs)(NSString *name);

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerDestination)(Class destinationClass);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerExclusiveDestination)(Class destinationClass);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerDestinationProtocol)(Protocol *destinationProtocol);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerModuleProtocol)(Protocol *moduleConfigProtocol);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerIdentifier)(NSString *identifier);

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^makeDefaultRemoveConfiguration)(RemoveConfig(^)(void));

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKRouter *router));
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKRouter *router));

@end

NS_ASSUME_NONNULL_END
