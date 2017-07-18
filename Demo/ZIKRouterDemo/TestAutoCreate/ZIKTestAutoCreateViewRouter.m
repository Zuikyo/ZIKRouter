//
//  ZIKTestAutoCreateViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestAutoCreateViewRouter.h"
#import "ZIKTestAutoCreateViewController.h"

RegisterRoutableView(ZIKTestAutoCreateViewController, ZIKTestAutoCreateViewRouter)
@implementation ZIKTestAutoCreateViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestAutoCreateViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAutoCreate"];;
    destination.title = @"Test AutoCreate";
    return destination;
}

@end
