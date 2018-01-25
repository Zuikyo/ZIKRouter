//
//  ZIKTestShowViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestShowViewRouter.h"
#import "TestShowViewController.h"

@interface TestShowViewController (ZIKTestShowViewRouter) <ZIKRoutableView>
@end
@implementation TestShowViewController (ZIKTestShowViewRouter)
@end

@implementation ZIKTestShowViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestShowViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestShowViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShow"];;
    destination.title = @"Test Show";
    return destination;
}

@end
