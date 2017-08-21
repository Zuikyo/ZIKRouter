//
//  ZIKDemoParentViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKDemoParentViewRouter.h"
#import "ZIKDemoParentViewController.h"

@interface ZIKDemoParentViewController (ZIKDemoParentViewRouter) <ZIKRoutableView>
@end
@implementation ZIKDemoParentViewController (ZIKDemoParentViewRouter)
@end

@implementation ZIKDemoParentViewRouter

+ (void)registerRoutableDestination {
    ZIKViewRouter_registerView([ZIKDemoParentViewController class], self);
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKDemoParentViewController *destination = [sb instantiateViewControllerWithIdentifier:@"demoParent"];;
    destination.title = @"Demo Parent";
    return destination;
}

+ (BOOL)destinationPrepared:(id)destination {
    return YES;
}

- (void)prepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
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
