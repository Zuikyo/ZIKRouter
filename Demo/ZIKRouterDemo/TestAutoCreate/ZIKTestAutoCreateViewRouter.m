//
//  ZIKTestAutoCreateViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestAutoCreateViewRouter.h"
#import "TestAutoCreateViewController.h"

@interface TestAutoCreateViewController (ZIKTestAutoCreateViewRouter) <ZIKRoutableView>
@end
@implementation TestAutoCreateViewController (ZIKTestAutoCreateViewRouter)
@end

@implementation ZIKTestAutoCreateViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestAutoCreateViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestAutoCreateViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAutoCreate"];
    destination.title = @"Test AutoCreate";
    return destination;
}

@end
