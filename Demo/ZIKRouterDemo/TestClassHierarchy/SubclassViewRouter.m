//
//  SubclassViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/11/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "SubclassViewRouter.h"
#import "SubclassViewController.h"

@interface SubclassViewController (TestClassHierarchyViewRouter) <ZIKRoutableView>
@end
@implementation SubclassViewController (TestClassHierarchyViewRouter)
@end

@implementation SubclassViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[SubclassViewController class]];
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    SubclassViewController *destination = [[SubclassViewController alloc] init];
    destination.title = @"Subclass";
    return destination;
}
@end
