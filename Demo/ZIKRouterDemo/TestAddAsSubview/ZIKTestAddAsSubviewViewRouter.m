//
//  ZIKTestAddAsSubviewViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKTestAddAsSubviewViewRouter.h"
#import "ZIKTestAddAsSubviewViewController.h"

@interface ZIKTestAddAsSubviewViewController (ZIKTestAddAsSubviewViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestAddAsSubviewViewController (ZIKTestAddAsSubviewViewRouter)
@end

@implementation ZIKTestAddAsSubviewViewRouter

+ (void)registerRoutableDestination {
    ZIKViewRouter_registerView([ZIKTestAddAsSubviewViewController class], self);
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestAddAsSubviewViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsSubview"];;
    destination.title = @"Test AddAsSubview";
    return destination;
}

@end
