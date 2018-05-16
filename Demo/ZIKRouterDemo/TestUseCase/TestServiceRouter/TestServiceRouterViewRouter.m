//
//  TestServiceRouterViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestServiceRouterViewRouter.h"
#import "TestServiceRouterViewController.h"

@interface TestServiceRouterViewController (TestServiceRouterViewRouter) <ZIKRoutableView>
@end
@implementation TestServiceRouterViewController (TestServiceRouterViewRouter)
@end

@implementation TestServiceRouterViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestServiceRouterViewController class]];
    [self registerIdentifier:@"testServiceRouter"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestServiceRouterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testServiceRouter"];
    destination.title = @"Test ServiceRouter";
    return destination;
}

@end
