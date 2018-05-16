//
//  TestShowDetailViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestShowDetailViewRouter.h"
#import "TestShowDetailViewController.h"

@interface TestShowDetailViewController (TestShowDetailViewRouter) <ZIKRoutableView>
@end
@implementation TestShowDetailViewController (TestShowDetailViewRouter)
@end

@implementation TestShowDetailViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestShowDetailViewController class]];
    [self registerIdentifier:@"testShowDetail"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestShowDetailViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShowDetail"];
    destination.title = @"Test ShowDetail";
    return destination;
}

@end
