//
//  ZIKChildViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKChildViewRouter.h"
#import "ZIKChildViewController.h"
#import "ZIKChildViewProtocol.h"
#import "ZIKParentViewProtocol.h"

@interface ZIKChildViewController (ZIKChildViewRouter) <ZIKRoutableView>
@end
@implementation ZIKChildViewController (ZIKChildViewRouter)
@end

@implementation ZIKChildViewRouter

+ (void)registerRoutableDestination {
    ZIKViewRouter_registerView([ZIKChildViewController class], self);
    ZIKViewRouter_registerViewProtocol(@protocol(ZIKChildViewProtocol), self);
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    ZIKChildViewController *destination = [[ZIKChildViewController alloc] init];
    destination.title = @"Test Circular Dependencies";
    destination.view.backgroundColor = [UIColor greenColor];
    return destination;
}

+ (BOOL)destinationPrepared:(ZIKChildViewController *)destination {
    if (destination.parent != nil) {
        return YES;
    }
    return NO;
}

- (void)prepareDestination:(ZIKChildViewController *)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    //Must check to avoid unnecessary preparation
    if (destination.parent == nil) {
        [ZIKViewRouterForView(@protocol(ZIKParentViewProtocol)) performWithConfigure:^(ZIKViewRouteConfiguration * _Nonnull config) {
            config.routeType = ZIKViewRouteTypeGetDestination;
            config.prepareForRoute = ^(id<ZIKParentViewProtocol> parent) {
                parent.child = destination;
            };
            config.routeCompletion = ^(id  _Nonnull parent) {
                destination.parent = parent;
            };
        }];
    }
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

@end
