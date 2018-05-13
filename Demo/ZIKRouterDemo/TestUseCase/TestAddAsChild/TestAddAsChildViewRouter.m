//
//  TestAddAsChildViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestAddAsChildViewRouter.h"
#import "TestAddAsChildViewController.h"

@interface TestAddAsChildViewController (TestAddAsChildViewRouter) <ZIKRoutableView>
@end
@implementation TestAddAsChildViewController (TestAddAsChildViewRouter)
@end

@implementation TestAddAsChildViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestAddAsChildViewController class]];
    [self registerIdentifier:@"com.zuik.viewController.testAddAsChild"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestAddAsChildViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsChild"];
    NSString *title = @"Test AddAsChild";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
