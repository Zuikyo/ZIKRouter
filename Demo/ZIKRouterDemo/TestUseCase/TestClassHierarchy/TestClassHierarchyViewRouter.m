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
    [self registerIdentifier:@"com.zuik.viewController.testClassHierarchy"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    TestClassHierarchyViewController *destination = [[TestClassHierarchyViewController alloc] init];
    NSString *title = @"Test Class Hierarchy";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
