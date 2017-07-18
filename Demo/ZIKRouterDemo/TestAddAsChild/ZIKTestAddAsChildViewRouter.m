//
//  ZIKTestAddAsChildViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestAddAsChildViewRouter.h"
#import "ZIKTestAddAsChildViewController.h"

RegisterRoutableView(ZIKTestAddAsChildViewController, ZIKTestAddAsChildViewRouter)

@implementation ZIKTestAddAsChildViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestAddAsChildViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsChild"];;
    destination.title = @"Test AddAsChild";
    return destination;
}

@end
