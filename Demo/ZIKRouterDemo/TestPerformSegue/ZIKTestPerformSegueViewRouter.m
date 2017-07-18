//
//  ZIKTestPerformSegueViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestPerformSegueViewRouter.h"
#import "ZIKTestPerformSegueViewController.h"

RegisterRoutableView(ZIKTestPerformSegueViewController, ZIKTestPerformSegueViewRouter)

@implementation ZIKTestPerformSegueViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestPerformSegueViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPerformSegue"];;
    destination.title = @"Test PerformSegue";
    return destination;
}

@end
