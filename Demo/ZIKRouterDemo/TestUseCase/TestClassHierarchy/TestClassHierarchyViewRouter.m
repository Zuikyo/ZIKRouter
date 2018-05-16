//
//  TestClassHierarchyViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/11/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestClassHierarchyViewRouter.h"
#import "TestClassHierarchyViewController.h"

@interface TestClassHierarchyViewController (TestClassHierarchyViewRouter) <ZIKRoutableView>
@end
@implementation TestClassHierarchyViewController (TestClassHierarchyViewRouter)
@end

@implementation TestClassHierarchyViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestClassHierarchyViewController class]];
    [self registerIdentifier:@"testClassHierarchy"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    TestClassHierarchyViewController *destination = [[TestClassHierarchyViewController alloc] init];
    destination.title = @"Test Class Hierarchy";
    return destination;
}

@end
