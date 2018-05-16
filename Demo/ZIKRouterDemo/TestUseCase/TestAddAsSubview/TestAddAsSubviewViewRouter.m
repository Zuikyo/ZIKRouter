//
//  TestAddAsSubviewViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestAddAsSubviewViewRouter.h"
#import "TestAddAsSubviewViewController.h"

@interface TestAddAsSubviewViewController (TestAddAsSubviewViewRouter) <ZIKRoutableView>
@end
@implementation TestAddAsSubviewViewController (TestAddAsSubviewViewRouter)
@end

@implementation TestAddAsSubviewViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestAddAsSubviewViewController class]];
    [self registerIdentifier:@"testAddAsSubview"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestAddAsSubviewViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsSubview"];
    destination.title = @"Test AddAsSubview";
    return destination;
}

@end
