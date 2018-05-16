//
//  TestShowViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestShowViewRouter.h"
#import "TestShowViewController.h"

@interface TestShowViewController (TestShowViewRouter) <ZIKRoutableView>
@end
@implementation TestShowViewController (TestShowViewRouter)
@end

@implementation TestShowViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestShowViewController class]];
    [self registerIdentifier:@"testShow"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestShowViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShow"];
    destination.title = @"Test Show";
    return destination;
}

@end
