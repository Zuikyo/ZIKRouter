//
//  ZIKViewRouteAdapter.m
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouteAdapter.h"

@implementation ZIKViewRouteAdapter

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration {
    NSAssert(NO, @"ZIKViewRouteAdapter is only for register protocol for other ZIKViewRouter in it's +registerRoutableDestination, don't use it's instance");
    return nil;
}

+ (BOOL)isAbstractRouter {
    return self == [ZIKViewRouteAdapter class];
}

+ (BOOL)isAdapter {
    return YES;
}

+ (void)registerRoutableDestination {
    
}

@end
