//
//  ZIKTestServiceRouterViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestServiceRouterViewRouter.h"
#import "ZIKTestServiceRouterViewController.h"

@interface ZIKTestServiceRouterViewController (ZIKTestPushViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestServiceRouterViewController (ZIKTestPushViewRouter)
@end

@implementation ZIKTestServiceRouterViewRouter

+ (void)registerRoutableDestination {
    ZIKViewRouter_registerView([ZIKTestServiceRouterViewController class], self);
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestServiceRouterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testServiceRouter"];;
    destination.title = @"Test ServiceRouter";
    return destination;
}

@end
