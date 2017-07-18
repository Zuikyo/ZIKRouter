//
//  ZIKTestPresentModallyViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestPresentModallyViewRouter.h"
#import "ZIKTestPresentModallyViewController.h"

RegisterRoutableView(ZIKTestPresentModallyViewController, ZIKTestPresentModallyViewRouter)

@implementation ZIKTestPresentModallyViewRouter

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestPresentModallyViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentModally"];;
    destination.title = @"Test PresentModally";
    return destination;
}

@end
