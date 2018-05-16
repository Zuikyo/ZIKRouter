//
//  TestPushViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPushViewRouter.h"
#import "TestPushViewController.h"

DeclareRoutableView(TestPushViewController, TestPushViewRouter)

@implementation TestPushViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPushViewController class]];
    [self registerIdentifier:@"testPush"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPushViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPush"];
    destination.title = @"Test Push";
    return destination;
}

@end
