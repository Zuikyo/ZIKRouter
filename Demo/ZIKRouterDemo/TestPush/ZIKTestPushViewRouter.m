//
//  ZIKTestPushViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPushViewRouter.h"
#import "ZIKTestPushViewController.h"

@interface ZIKTestPushViewController (ZIKTestPushViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestPushViewController (ZIKTestPushViewRouter)
@end

@implementation ZIKTestPushViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestPushViewController class]];
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestPushViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPush"];
    destination.title = @"Test Push";
    return destination;
}

@end
