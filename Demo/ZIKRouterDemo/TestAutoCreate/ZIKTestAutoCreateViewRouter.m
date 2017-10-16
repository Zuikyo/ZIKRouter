//
//  ZIKTestAutoCreateViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestAutoCreateViewRouter.h"
#import "ZIKTestAutoCreateViewController.h"

@interface ZIKTestAutoCreateViewController (ZIKTestAutoCreateViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestAutoCreateViewController (ZIKTestAutoCreateViewRouter)
@end

@implementation ZIKTestAutoCreateViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestAutoCreateViewController class]];
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestAutoCreateViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAutoCreate"];
    destination.title = @"Test AutoCreate";
    return destination;
}

@end
