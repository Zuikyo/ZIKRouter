//
//  ZIKTestShowViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestShowViewRouter.h"
#import "ZIKTestShowViewController.h"

RegisterRoutableView(ZIKTestShowViewController, ZIKTestShowViewRouter)

@implementation ZIKTestShowViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestShowViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShow"];;
    destination.title = @"Test Show";
    return destination;
}

@end
