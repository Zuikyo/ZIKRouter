//
//  ZIKSimpleLabelRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKSimpleLabelRouter.h"
#import "ZIKSimpleLabel.h"

@interface ZIKSimpleLabel (ZIKSimpleLabelRouter) <ZIKRoutableView>
@end
@implementation ZIKSimpleLabel (ZIKSimpleLabelRouter)
@end

@implementation ZIKSimpleLabelRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKSimpleLabel class]];
    [self registerViewProtocol:ZIKRoutable(ZIKSimpleLabelProtocol)];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    ZIKSimpleLabel *destination = [[ZIKSimpleLabel alloc] init];
    NSAssert([destination conformsToProtocol:@protocol(ZIKSimpleLabelProtocol)], nil);
    return destination;
}

+ (BOOL)destinationPrepared:(ZIKSimpleLabel *)destination {
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
