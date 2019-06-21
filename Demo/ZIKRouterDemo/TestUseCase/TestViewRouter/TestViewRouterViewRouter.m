//
//  TestViewRouterViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2019/6/22.
//Copyright © 2019 zuik. All rights reserved.
//

#import "TestViewRouterViewRouter.h"
#import <ZIKRouter/ZIKRouterInternal.h>
#import <ZIKRouter/ZIKViewRouterInternal.h>
#import "TestViewRouterViewController.h"

DeclareRoutableView(TestViewRouterViewController, ViewRouteViewRouter)

@interface TestViewRouterViewRouter ()

@end

@implementation TestViewRouterViewRouter

+ (void)registerRoutableDestination {
    [self registerExclusiveView:[TestViewRouterViewController class]];
}

- (nullable TestViewRouterViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    TestViewRouterViewController *destination = [[TestViewRouterViewController alloc] init];
    return destination;
}

@end
