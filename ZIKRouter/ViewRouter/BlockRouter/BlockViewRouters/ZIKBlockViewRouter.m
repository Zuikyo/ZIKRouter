//
//  ZIKBlockViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKBlockViewRouter.h"
#import "ZIKRouterPrivate.h"
#import "ZIKRoutePrivate.h"
#import "ZIKViewRoutePrivate.h"
#import "ZIKRouterInternal.h"
#import "ZIKViewRouterInternal.h"
#import "ZIKRouteConfigurationPrivate.h"

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
    return ZIKViewRouteTypeMaskViewControllerDefault;
}

- (nullable id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    id(^makeDestinationBlock)(ZIKViewRouteConfiguration *config, ZIKRouter *router) = self.route.makeDestinationBlock;
    if (makeDestinationBlock) {
        return makeDestinationBlock(configuration, self);
    }
    return nil;
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
        return;
    }
    [super prepareDestination:destination configuration:configuration];
}

- (void)didFinishPrepareDestination:(id)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    void(^didFinishPrepareDestinationBlock)(id destination, ZIKPerformRouteConfiguration *config, ZIKRouter *router) = self.route.didFinishPrepareDestinationBlock;
    if (didFinishPrepareDestinationBlock) {
        didFinishPrepareDestinationBlock(destination, configuration, self);
        return;
    }
    [super didFinishPrepareDestination:destination configuration:configuration];
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
        return;
    }
    [self beginPerformRoute];
    [self endPerformRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorUnsupportType localizedDescriptionFormat:@"The route (%@) supports ZIKBlockViewRouteTypeMaskCustom, but it didn't implement the custom perform route logic with -performCustomRoute.", self]];
}
- (void)removeCustomRouteOnDestination:(id)destination fromSource:(nullable id)source removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration configuration:(ZIKViewRouteConfiguration *)configuration {
    void(^removeCustomRouteBlock)(id destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router) = self.route.removeCustomRouteBlock;
    if (removeCustomRouteBlock) {
        removeCustomRouteBlock(destination, source, removeConfiguration, configuration,self);
        return;
    }
    [self beginRemoveRouteFromSource:source];
    [self endRemoveRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorUnsupportType localizedDescriptionFormat:@"The route (%@) supports ZIKBlockViewRouteTypeMaskCustom, but it didn't implement the custom remove route logic with -removeCustomRoute.", self]];
}

- (ZIKRemoveRouteConfiguration *)original_removeConfiguration {
    if (_removeConfiguration == nil) {
        NSAssert(self.original_configuration, @"Configuration shouldn't be nil when lazy get removeConfiguration");
        ZIKRoute *route = self.original_configuration.route;
        if (route && route.makeDefaultRemoveConfigurationBlock) {
            _removeConfiguration = route.makeDefaultRemoveConfigurationBlock();
        } else {
            _removeConfiguration = [[self class] defaultRemoveConfiguration];
        }
    }
    return _removeConfiguration;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@,\nroute: (%@)",[super description], self.route];
}

@end

@implementation ZIKBlockCustomViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewControllerDefault | ZIKViewRouteTypeMaskCustom;
}

@end

@implementation ZIKBlockSubviewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault;
}

@end

@implementation ZIKBlockCustomSubviewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault | ZIKViewRouteTypeMaskCustom;
}

@end

@implementation ZIKBlockCustomOnlyViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskCustom;
}

@end

@implementation ZIKBlockAnyViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewControllerDefault | ZIKViewRouteTypeMaskViewDefault;
}

@end

@implementation ZIKBlockAllViewRouter

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewControllerDefault | ZIKViewRouteTypeMaskViewDefault | ZIKViewRouteTypeMaskCustom;
}

@end
