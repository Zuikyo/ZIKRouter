//
//  ZIKTestAddAsChildViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestAddAsChildViewRouter.h"
#import "ZIKTestAddAsChildViewController.h"

@interface ZIKTestAddAsChildViewController (ZIKTestAddAsChildViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestAddAsChildViewController (ZIKTestAddAsChildViewRouter)
@end

@implementation ZIKTestAddAsChildViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestAddAsChildViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestAddAsChildViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsChild"];;
    destination.title = @"Test AddAsChild";
    return destination;
}

@end
