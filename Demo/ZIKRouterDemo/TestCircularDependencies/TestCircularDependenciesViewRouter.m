//
//  TestCircularDependenciesViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestCircularDependenciesViewRouter.h"
#import "TestCircularDependenciesViewController.h"
#import "ZIKParentViewProtocol.h"
#import "ZIKChildViewProtocol.h"

@interface TestCircularDependenciesViewController (TestCircularDependenciesViewRouter) <ZIKRoutableView>
@end
@implementation TestCircularDependenciesViewController (TestCircularDependenciesViewRouter)
@end

@implementation TestCircularDependenciesViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestCircularDependenciesViewController class]];
    [self registerViewProtocol:ZIKRoutableProtocol(ZIKParentViewProtocol)];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    TestCircularDependenciesViewController *destination = [[TestCircularDependenciesViewController alloc] init];
    destination.title = @"Test Circular Dependencies";
    
    return destination;
}

+ (BOOL)destinationPrepared:(TestCircularDependenciesViewController *)destination {
    if (destination.child != nil) {
        return YES;
    }
    return NO;
}

- (void)prepareDestination:(TestCircularDependenciesViewController *)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    //Must check to avoid unnecessary preparation
    if (destination.child == nil) {
        [ZIKViewRouterToView(ZIKChildViewProtocol)
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
