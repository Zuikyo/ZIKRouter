//
//  ZIKTestShowViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestShowViewRouter.h"
#import "ZIKTestShowViewController.h"

@interface ZIKTestShowViewController (ZIKTestShowViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestShowViewController (ZIKTestShowViewRouter)
@end

@implementation ZIKTestShowViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestShowViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestShowViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShow"];;
    destination.title = @"Test Show";
    return destination;
}

@end
