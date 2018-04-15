//
//  ZIKServiceRouteAdapter.m
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouteAdapter.h"

@implementation ZIKServiceRouteAdapter

- (nullable instancetype)initWithConfiguration:(__kindof ZIKPerformRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKRouteConfiguration *)removeConfiguration {
    NSAssert(NO, @"ZIKServiceRouteAdapter is only for register protocol for other ZIKServiceRouter in it's +registerRoutableDestination, don't use it's instance");
    return nil;
}

+ (BOOL)isAbstractRouter {
    return self == [ZIKServiceRouteAdapter class];
}

+ (BOOL)isAdapter {
    return YES;
}

+ (void)registerRoutableDestination {
    
}

@end
