//
//  ZIKInfoViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKInfoViewRouter.h"
#import "ZIKInfoViewController.h"

@interface ZIKInfoViewController (ZIKInfoViewRouter) <ZIKRoutableView>
@end
@implementation ZIKInfoViewController (ZIKInfoViewRouter)
@end

@implementation ZIKInfoViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKInfoViewController class]];
    [self registerViewProtocol:ZIKRoutable(ZIKInfoViewProtocol)];
    [self registerIdentifier:@"info"];
}

- (id<ZIKInfoViewProtocol>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKInfoViewController *destination = [sb instantiateViewControllerWithIdentifier:@"info"];
    destination.title = @"info";
    NSAssert([destination conformsToProtocol:@protocol(ZIKInfoViewProtocol)], nil);
    return destination;
}

+ (BOOL)destinationPrepared:(UIViewController<ZIKInfoViewProtocol> *)destination {
    NSParameterAssert([destination isKindOfClass:[ZIKInfoViewController class]]);
    if (destination.name.length > 0 && destination.age > 0) {
        return YES;
    }
    return NO;
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ➡️ will\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ✅ did\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ⬅️ will\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ❎ did\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

@end
