//
//  ZIKTestAddAsChildViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestAddAsChildViewRouter.h"
#import "ZIKTestAddAsChildViewController.h"

@interface ZIKTestAddAsChildViewController (ZIKTestAddAsChildViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestAddAsChildViewController (ZIKTestAddAsChildViewRouter)
@end

@implementation ZIKTestAddAsChildViewRouter

+ (void)registerRoutableDestination {
    ZIKViewRouter_registerView([ZIKTestAddAsChildViewController class], self);
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestAddAsChildViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsChild"];;
    destination.title = @"Test AddAsChild";
    return destination;
}

@end
