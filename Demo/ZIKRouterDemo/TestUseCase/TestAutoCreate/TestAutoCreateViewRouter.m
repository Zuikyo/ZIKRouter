//
//  TestAutoCreateViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestAutoCreateViewRouter.h"
#import "TestAutoCreateViewController.h"

@interface TestAutoCreateViewController (TestAutoCreateViewRouter) <ZIKRoutableView>
@end
@implementation TestAutoCreateViewController (TestAutoCreateViewRouter)
@end

@implementation TestAutoCreateViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestAutoCreateViewController class]];
    [self registerIdentifier:@"com.zuik.viewController.testAutoCreate"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestAutoCreateViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAutoCreate"];
    NSString *title = @"Test AutoCreate";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
