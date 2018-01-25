//
//  ZIKTestShowDetailViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestShowDetailViewRouter.h"
#import "TestShowDetailViewController.h"

@interface TestShowDetailViewController (ZIKTestShowDetailViewRouter) <ZIKRoutableView>
@end
@implementation TestShowDetailViewController (ZIKTestShowDetailViewRouter)
@end

@implementation ZIKTestShowDetailViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestShowDetailViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestShowDetailViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShowDetail"];;
    destination.title = @"Test ShowDetail";
    return destination;
}

@end
