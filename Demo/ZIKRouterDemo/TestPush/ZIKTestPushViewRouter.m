//
//  ZIKTestPushViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPushViewRouter.h"
#import "TestPushViewController.h"

DeclareRoutableView(TestPushViewController, ZIKTestPushViewRouter)

@implementation ZIKTestPushViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPushViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPushViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPush"];
    destination.title = @"Test Push";
    return destination;
}

@end
