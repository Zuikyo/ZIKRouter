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
#import "ZIKRouteRegistryInternal.h"
#import "ZIKViewRouteRegistry.h"

@implementation ZIKViewRouteAdapter

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration {
    NSAssert(NO, @"ZIKViewRouteAdapter is only for register protocol for other ZIKViewRouter in its +registerRoutableDestination, don't use its instance");
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

+ (void)registerDestinationAdapter:(Protocol *)adapterProtocol forAdaptee:(Protocol *)adapteeProtocol {
    [ZIKViewRouteRegistry registerDestinationAdapter:adapterProtocol forAdaptee:adapteeProtocol];
}
+ (void)registerModuleAdapter:(Protocol *)adapterProtocol forAdaptee:(Protocol *)adapteeProtocol {
    [ZIKViewRouteRegistry registerModuleAdapter:adapterProtocol forAdaptee:adapteeProtocol];
}

@end
