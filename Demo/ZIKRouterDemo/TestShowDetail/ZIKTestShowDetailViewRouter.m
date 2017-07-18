//
//  ZIKTestShowDetailViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestShowDetailViewRouter.h"
#import "ZIKTestShowDetailViewController.h"

RegisterRoutableView(ZIKTestShowDetailViewController, ZIKTestShowDetailViewRouter)

@implementation ZIKTestShowDetailViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestShowDetailViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShowDetail"];;
    destination.title = @"Test ShowDetail";
    return destination;
}

@end
