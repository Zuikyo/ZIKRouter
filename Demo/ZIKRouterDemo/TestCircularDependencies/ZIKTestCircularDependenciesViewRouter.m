//
//  ZIKTestCircularDependenciesViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestCircularDependenciesViewRouter.h"
#import "ZIKTestCircularDependenciesViewController.h"
#import "ZIKParentViewProtocol.h"
#import "ZIKChildViewProtocol.h"

@interface ZIKTestCircularDependenciesViewController (ZIKTestCircularDependenciesViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestCircularDependenciesViewController (ZIKTestCircularDependenciesViewRouter)
@end

@implementation ZIKTestCircularDependenciesViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestCircularDependenciesViewController class]];
    [self registerViewProtocol:@protocol(ZIKParentViewProtocol)];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    ZIKTestCircularDependenciesViewController *destination = [[ZIKTestCircularDependenciesViewController alloc] init];
    destination.title = @"Test Circular Dependencies";
    
    return destination;
}

+ (BOOL)destinationPrepared:(ZIKTestCircularDependenciesViewController *)destination {
    if (destination.child != nil) {
        return YES;
    }
    return NO;
}

- (void)prepareDestination:(ZIKTestCircularDependenciesViewController *)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    //Must check to avoid unnecessary preparation
    if (destination.child == nil) {
        [ZIKViewRouter.toView(@protocol(ZIKChildViewProtocol))
         performFromSource:nil
         configuring:^(ZIKViewRouteConfiguration * _Nonnull config) {
            config.routeType = ZIKViewRouteTypeGetDestination;
            
            //The child may fetch parent in it's router, you must set child's parent to avoid infinite recursion
            config.prepareDestination = ^(id<ZIKChildViewProtocol> child) {
                child.parent = destination;
            };
            config.routeCompletion = ^(id  _Nonnull child) {
                destination.child = child;
            };
        }];
    }
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

@end
