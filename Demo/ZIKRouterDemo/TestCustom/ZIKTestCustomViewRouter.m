//
//  ZIKTestCustomViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestCustomViewRouter.h"
#import "ZIKTestCustomViewController.h"

RegisterRoutableView(ZIKTestCustomViewController, ZIKTestCustomViewRouter)

@implementation ZIKTestCustomViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestCustomViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testCustom"];;
    destination.title = @"Test Custom";
    return destination;
}

@end
