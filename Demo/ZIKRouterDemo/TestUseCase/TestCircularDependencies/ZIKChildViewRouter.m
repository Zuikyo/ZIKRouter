//
//  ZIKChildViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKChildViewRouter.h"
#import "ZIKChildViewController.h"
#import "ZIKChildViewProtocol.h"
#import "ZIKParentViewProtocol.h"

@interface ZIKChildViewController (ZIKChildViewRouter) <ZIKRoutableView>
@end
@implementation ZIKChildViewController (ZIKChildViewRouter)
@end

@implementation ZIKChildViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKChildViewController class]];
    [self registerViewProtocol:ZIKRoutable(ZIKChildViewProtocol)];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    ZIKChildViewController *destination = [[ZIKChildViewController alloc] init];
    destination.title = @"Test Circular Dependencies";
    destination.view.backgroundColor = [UIColor greenColor];
    return destination;
}

+ (BOOL)destinationPrepared:(ZIKChildViewController *)destination {
    if (destination.parent != nil) {
        return YES;
    }
    return NO;
}

- (void)prepareDestination:(ZIKChildViewController *)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    //Must check to avoid unnecessary preparation
    if (destination.parent == nil) {
        destination.parent = [ZIKRouterToView(ZIKParentViewProtocol) makeDestinationWithPreparation:^(id<ZIKParentViewProtocol>  _Nonnull parent) {
            parent.child = destination;
        }];
    }
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

@end
