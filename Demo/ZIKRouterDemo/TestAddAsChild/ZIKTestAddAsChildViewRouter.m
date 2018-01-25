//
//  ZIKTestAddAsChildViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestAddAsChildViewRouter.h"
#import "TestAddAsChildViewController.h"

@interface TestAddAsChildViewController (ZIKTestAddAsChildViewRouter) <ZIKRoutableView>
@end
@implementation TestAddAsChildViewController (ZIKTestAddAsChildViewRouter)
@end

@implementation ZIKTestAddAsChildViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestAddAsChildViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestAddAsChildViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsChild"];;
    destination.title = @"Test AddAsChild";
    return destination;
}

@end
