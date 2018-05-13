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
    [self registerIdentifier:@"com.zuik.viewController.testServiceRouter"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestServiceRouterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testServiceRouter"];
    NSString *title = @"Test ServiceRouter";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
