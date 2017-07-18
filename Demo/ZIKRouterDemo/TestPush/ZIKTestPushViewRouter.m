//
//  ZIKTestPushViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestPushViewRouter.h"
#import "ZIKTestPushViewController.h"

RegisterRoutableView(ZIKTestPushViewController, ZIKTestPushViewRouter)

@implementation ZIKTestPushViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestPushViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPush"];;
    destination.title = @"Test Push";
    return destination;
}

@end
