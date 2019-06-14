//
//  ZIKSimpleLabelRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKSimpleLabelRouter.h"
#import "ZIKSimpleLabel.h"
#import "AppRouteRegistry.h"

@interface ZIKSimpleLabel (ZIKSimpleLabelRouter) <ZIKRoutableView>
@end
@implementation ZIKSimpleLabel (ZIKSimpleLabelRouter)
@end

@implementation ZIKSimpleLabelRouter

+ (void)registerRoutableDestination {
    
#if TEST_BLOCK_ROUTES
    [ZIKDestinationViewRoute(id<ZIKSimpleLabelProtocol>) makeRouteWithDestination:[ZIKSimpleLabel class] makeDestination:^id<ZIKSimpleLabelProtocol> _Nullable(ZIKViewRouteConfig * _Nonnull config, __kindof ZIKRouter<id<ZIKSimpleLabelProtocol>,ZIKViewRouteConfig *,ZIKViewRemoveConfiguration *> * _Nonnull router) {
        return [[ZIKSimpleLabel alloc] init];
    }]
    .registerDestinationProtocol(ZIKRoutable(ZIKSimpleLabelProtocol))
    .shouldAutoCreateForDestination(^BOOL(ZIKSimpleLabel *destination, id  _Nullable source) {
        if ([destination zix_isRootView] && [destination zix_isDuringNavigationTransitionBack]) {
            return NO;
        }
        return YES;
    })
    .prepareDestination(^(id _Nonnull destination, ZIKViewRouteConfig * _Nonnull config, ZIKViewRouter * _Nonnull router) {
        
    })
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskViewDefault;
    });
#else
    [self registerViewProtocol:ZIKRoutable(ZIKSimpleLabelProtocol)];
#endif
    
    [self registerView:[ZIKSimpleLabel class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
    NSAssert([destination conformsToProtocol:@protocol(ZIKSimpleLabelProtocol)], nil);
    return destination;
}

+ (BOOL)shouldAutoCreateForDestination:(ZIKSimpleLabel *)destination fromSource:(id)source {
    // You can check whether the destination already has a router or is already prepared, then you can ignore this auto creating.
    if ([destination zix_isRootView] && [destination zix_isDuringNavigationTransitionBack]) {
        return NO;
    }
    return YES;
}

- (BOOL)destinationFromExternalPrepared:(ZIKSimpleLabel *)destination {
    if (destination.text.length == 0) {
        return NO;
    }
    return YES;
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault;
}

+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ➡️ will\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}
///AOP support. Callback to all routers managing the same view class, when any router of them did perform route.
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ✅ did\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}
///AOP support. Callback to all routers managing the same view class, when any router of them will remove route.
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ⬅️ will\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}
///AOP support. Callback to all routers managing the same view class, when any router of them did remove route.
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ❎ did\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

@end
