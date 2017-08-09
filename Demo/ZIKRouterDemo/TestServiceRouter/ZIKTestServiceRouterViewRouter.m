//
//  ZIKTestServiceRouterViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestServiceRouterViewRouter.h"
#import "ZIKTestServiceRouterViewController.h"

RegisterRoutableView(ZIKTestServiceRouterViewController, ZIKTestServiceRouterViewRouter)

@implementation ZIKTestServiceRouterViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestServiceRouterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testServiceRouter"];;
    destination.title = @"Test ServiceRouter";
    return destination;
}

@end
