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
    [self registerIdentifier:@"com.zuik.viewController.testShowDetail"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestShowDetailViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testShowDetail"];
    NSString *title = @"Test ShowDetail";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
