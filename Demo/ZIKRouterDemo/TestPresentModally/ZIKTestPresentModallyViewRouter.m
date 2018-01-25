//
//  ZIKTestPresentModallyViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPresentModallyViewRouter.h"
#import "TestPresentModallyViewController.h"

@interface TestPresentModallyViewController (ZIKTestPresentModallyViewRouter) <ZIKRoutableView>
@end
@implementation TestPresentModallyViewController (ZIKTestPresentModallyViewRouter)
@end

@implementation ZIKTestPresentModallyViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPresentModallyViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPresentModallyViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentModally"];;
    destination.title = @"Test PresentModally";
    return destination;
}

@end
