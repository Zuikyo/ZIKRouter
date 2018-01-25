//
//  ZIKTestServiceRouterViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestServiceRouterViewRouter.h"
#import "TestServiceRouterViewController.h"

@interface TestServiceRouterViewController (ZIKTestPushViewRouter) <ZIKRoutableView>
@end
@implementation TestServiceRouterViewController (ZIKTestPushViewRouter)
@end

@implementation ZIKTestServiceRouterViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestServiceRouterViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestServiceRouterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testServiceRouter"];;
    destination.title = @"Test ServiceRouter";
    return destination;
}

@end
