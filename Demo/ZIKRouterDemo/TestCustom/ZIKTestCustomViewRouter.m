//
//  ZIKTestCustomViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestCustomViewRouter.h"
#import "TestCustomViewController.h"

@interface TestCustomViewController (ZIKTestCustomViewRouter) <ZIKRoutableView>
@end
@implementation TestCustomViewController (ZIKTestCustomViewRouter)
@end

@implementation ZIKTestCustomViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestCustomViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestCustomViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testCustom"];;
    destination.title = @"Test Custom";
    return destination;
}

@end
