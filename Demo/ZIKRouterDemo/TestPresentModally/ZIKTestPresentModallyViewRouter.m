//
//  ZIKTestPresentModallyViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPresentModallyViewRouter.h"
#import "ZIKTestPresentModallyViewController.h"

@interface ZIKTestPresentModallyViewController (ZIKTestPresentModallyViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestPresentModallyViewController (ZIKTestPresentModallyViewRouter)
@end

@implementation ZIKTestPresentModallyViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestPresentModallyViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestPresentModallyViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentModally"];;
    destination.title = @"Test PresentModally";
    return destination;
}

@end
