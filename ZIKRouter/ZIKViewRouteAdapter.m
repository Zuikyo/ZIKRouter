//
//  ZIKViewRouteAdapter.m
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKViewRouteAdapter.h"

@implementation ZIKViewRouteAdapter

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration {
    NSAssert(NO, @"ZIKViewRouteAdapter is only for register protocol for other ZIKViewRouter in it's +registerRoutableDestination, don't use it's instance");
    return nil;
}

+ (void)registerRoutableDestination {
    
}

@end
