//
//  ZIKTestPerformSegueViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPerformSegueViewRouter.h"
#import "TestPerformSegueViewController.h"

@interface TestPerformSegueViewController (ZIKTestPerformSegueViewRouter) <ZIKRoutableView>
@end
@implementation TestPerformSegueViewController (ZIKTestPerformSegueViewRouter)
@end

@implementation ZIKTestPerformSegueViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPerformSegueViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPerformSegueViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPerformSegue"];;
    destination.title = @"Test PerformSegue";
    return destination;
}

@end
