//
//  ZIKSimpleLabelRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKSimpleLabelRouter.h"
#import "ZIKSimpleLabel.h"

RegisterRoutableViewWithViewProtocol(ZIKSimpleLabel, ZIKSimpleLabelProtocol, ZIKSimpleLabelRouter)
@implementation ZIKSimpleLabelRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
    NSAssert([destination conformsToProtocol:@protocol(ZIKSimpleLabelProtocol)], nil);
    return destination;
}

+ (BOOL)destinationPrepared:(ZIKSimpleLabel *)destination {
    if (!destination.text) {
        return NO;
    }
    return YES;
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

+ (NSArray<NSNumber *> *)supportedRouteTypes {
    return kDefaultRouteTypesForView;
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
