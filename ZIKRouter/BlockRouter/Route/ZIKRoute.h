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

///Abstract class to add route with blocks, rather than subclass. Don't use this class directly.
@interface ZIKRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject
@property (nonatomic, copy, nullable) NSString *name;

+ (instancetype)makeRouteWithDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, ZIKRouter *router))makeDestination;

- (instancetype)initWithDestination:(Class)destinationClass makeDestination:(_Nullable Destination(^)(RouteConfig config, ZIKRouter *router))makeDestination NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerDestination)(Class destinationClass);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerDestinationProtocol)(Protocol *destinationProtocol);
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^registerModuleProtocol)(Protocol *moduleConfigProtocol);

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^makeDefaultRemoveConfiguration)(RemoveConfig(^)(void));

@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKRouter *router));
@property (nonatomic, readonly) ZIKRoute<Destination, RouteConfig, RemoveConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKRouter *router));

@end

NS_ASSUME_NONNULL_END
