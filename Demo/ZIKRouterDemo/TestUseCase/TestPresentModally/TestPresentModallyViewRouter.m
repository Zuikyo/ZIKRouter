//
//  TestPresentModallyViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPresentModallyViewRouter.h"
#import "TestPresentModallyViewController.h"

@interface TestPresentModallyViewController (TestPresentModallyViewRouter) <ZIKRoutableView>
@end
@implementation TestPresentModallyViewController (TestPresentModallyViewRouter)
@end

@implementation TestPresentModallyViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPresentModallyViewController class]];
    [self registerIdentifier:@"com.zuik.viewController.testPresentModally"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPresentModallyViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentModally"];
    NSString *title = @"Test PresentModally";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
