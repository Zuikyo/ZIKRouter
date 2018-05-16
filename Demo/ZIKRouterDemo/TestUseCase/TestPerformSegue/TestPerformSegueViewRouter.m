//
//  TestPerformSegueViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPerformSegueViewRouter.h"
#import "TestPerformSegueViewController.h"

@interface TestPerformSegueViewController (TestPerformSegueViewRouter) <ZIKRoutableView>
@end
@implementation TestPerformSegueViewController (TestPerformSegueViewRouter)
@end

@implementation TestPerformSegueViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPerformSegueViewController class]];
    [self registerIdentifier:@"testPerformSegue"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPerformSegueViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPerformSegue"];
    destination.title = @"Test PerformSegue";
    return destination;
}

@end
