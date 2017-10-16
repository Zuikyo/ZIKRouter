//
//  ZIKTestShowDetailViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestShowDetailViewRouter.h"
#import "ZIKTestShowDetailViewController.h"

@interface ZIKTestShowDetailViewController (ZIKTestShowDetailViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestShowDetailViewController (ZIKTestShowDetailViewRouter)
@end

@implementation ZIKTestShowDetailViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestShowDetailViewController class]];
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestShowDetailViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShowDetail"];;
    destination.title = @"Test ShowDetail";
    return destination;
}

@end
