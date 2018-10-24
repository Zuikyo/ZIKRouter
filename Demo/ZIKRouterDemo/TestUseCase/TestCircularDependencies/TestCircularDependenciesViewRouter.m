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
    [self registerViewProtocol:ZIKRoutable(ZIKParentViewProtocol)];
    [self registerIdentifier:@"testCircularDependencies"];
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
        destination.child = [ZIKRouterToView(ZIKChildViewProtocol) makeDestinationWithPreparation:^(id<ZIKChildViewProtocol>  _Nonnull child) {
            //The child may fetch parent in its router, you must set child's parent to avoid infinite recursion
            child.parent = destination;
        }];
    }
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

@end
