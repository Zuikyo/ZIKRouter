//
//  ZIKTestCustomViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestCustomViewRouter.h"
#import "ZIKTestCustomViewController.h"

@interface ZIKTestCustomViewController (ZIKTestCustomViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestCustomViewController (ZIKTestCustomViewRouter)
@end

@implementation ZIKTestCustomViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestCustomViewController class]];
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestCustomViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testCustom"];;
    destination.title = @"Test Custom";
    return destination;
}

@end
