//
//  MasterViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/20.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "MasterViewRouter.h"
#import "MasterViewController.h"
@import ZIKRouter.Internal;

DeclareRoutableView(MasterViewController, MasterViewRouter)

@implementation MasterViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[MasterViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MasterViewController *destination = [sb instantiateViewControllerWithIdentifier:@"master"];
    return destination;
}

- (BOOL)destinationFromExternalPrepared:(MasterViewController *)destination {
    if ([destination.tableView.backgroundColor isEqual:[UIColor lightGrayColor]]) {
        return YES;
    }
    return NO;
}

- (void)prepareDestination:(MasterViewController *)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    destination.tableView.backgroundColor = [UIColor lightGrayColor];
}

- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration {
    
}

+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ➡️ will\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ✅ did\n\
          perform route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ⬅️ will\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(id)source {
    NSLog(@"\n----------------------\nrouter: (%@),\n\
          ❎ did\n\
          remove route\n\
          from source: (%@),\n\
          destination: (%@),\n----------------------",router, source, destination);
}

@end
