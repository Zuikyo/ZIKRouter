//
//  ZIKServiceRouteAdapter.m
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKServiceRouteAdapter.h"

@implementation ZIKServiceRouteAdapter

- (nullable instancetype)initWithConfiguration:(__kindof ZIKServiceRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKRouteConfiguration *)removeConfiguration {
    NSAssert(NO, @"ZIKServiceRouteAdapter is only for register protocol for other ZIKServiceRouter in it's +registerRoutableDestination, don't use it's instance");
    return nil;
}

+ (void)registerRoutableDestination {
    
}

@end
