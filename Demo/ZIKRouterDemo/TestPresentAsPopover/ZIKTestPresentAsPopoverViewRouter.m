//
//  ZIKTestPresentAsPopoverViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestPresentAsPopoverViewRouter.h"
#import "ZIKTestPresentAsPopoverViewController.h"

RegisterRoutableView(ZIKTestPresentAsPopoverViewController, ZIKTestPresentAsPopoverViewRouter)

@implementation ZIKTestPresentAsPopoverViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestPresentAsPopoverViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentAsPopover"];;
    destination.title = @"Test PresentAsPopover";
    return destination;
}

@end
