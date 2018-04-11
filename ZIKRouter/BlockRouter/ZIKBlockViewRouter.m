//
//  ZIKBlockViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKBlockViewRouter.h"
#import "ZIKRoutePrivate.h"
#import "ZIKViewRoutePrivate.h"
#import "ZIKRouterInternal.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKViewRouterPrivate.h"
#import "ZIKPerformRouteConfiguration+Route.h"

@interface ZIKBlockViewRouter()
@end

@implementation ZIKBlockViewRouter

+ (BOOL)isAbstractRouter {
    return YES;
}

- (ZIKViewRoute *)route {
    ZIKViewRoute *route = (ZIKViewRoute *)self.original_configuration.route;
    NSAssert1(route, @"Can't find ZIKViewRoute for block router (%@). If you add new class method in ZIKRouter or ZIKViewRouter to create router, you must check your class method in ZIKRoute or ZIKViewRoute to inject route to router.",self);
    return route;
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskUIViewControllerDefault | ZIKViewRouteTypeMaskUIViewDefault;
}

- (nullable id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    id(^makeDestinationBlock)(ZIKViewRouteConfiguration *config, ZIKRouter *router) = self.route.makeDestinationBlock;
    if (makeDestinationBlock) {
        return makeDestinationBlock(configuration, self);
    }
    return nil;
}

+ (BOOL)destinationPrepared:(id)destination {
    return [super destinationPrepared:destination];
}

- (BOOL)destinationFromExternalPrepared:(id)destination {
    BOOL(^destinationFromExternalPreparedBlock)(id destination, ZIKViewRouter *router) = self.route.destinationFromExternalPreparedBlock;
    if (destinationFromExternalPreparedBlock) {
        return destinationFromExternalPreparedBlock(destination, self);
    }
    return [super destinationFromExternalPrepared:destination];
}

- (void)prepareDestination:(id)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    void(^prepareDestinationBlock)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router) = self.route.prepareDestinationBlock;
    if (prepareDestinationBlock) {
        prepareDestinationBlock(destination, configuration, self);
    }
}

- (void)didFinishPrepareDestination:(id)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    void(^didFinishPrepareDestinationBlock)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router) = self.route.didFinishPrepareDestinationBlock;
    if (didFinishPrepareDestinationBlock) {
        didFinishPrepareDestinationBlock(destination, configuration, self);
    }
}

- (BOOL)canPerformCustomRoute {
    BOOL(^canPerformCustomRouteBlock)(ZIKViewRouter *router) = self.route.canPerformCustomRouteBlock;
    if (canPerformCustomRouteBlock) {
        return canPerformCustomRouteBlock(self);
    }
    return [super canPerformCustomRoute];
}

- (BOOL)canRemoveCustomRoute {
    BOOL(^canRemoveCustomRouteBlock)(ZIKViewRouter *router) = self.route.canRemoveCustomRouteBlock;
    if (canRemoveCustomRouteBlock) {
        return canRemoveCustomRouteBlock(self);
    }
    return [super canRemoveCustomRoute];
}

- (void)performCustomRouteOnDestination:(id)destination fromSource:(nullable id)source configuration:(ZIKViewRouteConfiguration *)configuration {
    void(^performCustomRouteBlock)(id destination, _Nullable id source, ZIKViewRouteConfiguration *config, ZIKViewRouter *router) = self.route.performCustomRouteBlock;
    if (performCustomRouteBlock) {
        performCustomRouteBlock(destination, source, configuration, self);
    }
}
- (void)removeCustomRouteOnDestination:(id)destination fromSource:(nullable id)source removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration configuration:(ZIKViewRouteConfiguration *)configuration {
    void(^removeCustomRouteBlock)(id destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router) = self.route.removeCustomRouteBlock;
    if (removeCustomRouteBlock) {
        removeCustomRouteBlock(destination, source, removeConfiguration, configuration,self);
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@,\nroute: (%@)",[super description], self.route];
}

@end
