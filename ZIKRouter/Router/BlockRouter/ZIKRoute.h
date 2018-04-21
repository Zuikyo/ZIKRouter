//
//  ZIKRoute.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKRouter, ZIKPerformRouteConfiguration, ZIKRemoveRouteConfiguration;

/**
 Abstract superclass to add route with blocks, rather than subclass. Don't use this class directly.
 @note
 The instance can forward class methods in ZIKRouter. When adding class methods in ZIKRouter, the same instance methods should be added in ZIKRoute or it's subclass.
 */
@interface ZIKRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject
@property (nonatomic, copy, nullable) NSString *name;

+ (instancetype)makeRouteWithDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, __kindof ZIKRouter<Destination, RouteConfig, RemoveConfig> *router))makeDestination;

- (instancetype)initWithDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, __kindof ZIKRouter<Destination, RouteConfig, RemoveConfig> *router))makeDestination NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerDestination)(Class destinationClass);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerExclusiveDestination)(Class destinationClass);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerDestinationProtocol)(Protocol *destinationProtocol);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerModuleProtocol)(Protocol *moduleConfigProtocol);

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^makeDefaultRemoveConfiguration)(RemoveConfig(^)(void));

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKRouter *router));
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKRouter *router));

@end

NS_ASSUME_NONNULL_END
